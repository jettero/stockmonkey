package Math::Business::SMA;

use strict;
use warnings;

use version; our $VERSION = qv('1.1');

use Carp;

1;

sub new { 
    my $class = shift;
    my $this  = bless {
        val => [],
        cur => undef,
        rec => 1,
    }, $class;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days { 
    my $this = shift; 
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{val} = [];
    delete $this->{SMA};
    $this->{days} = $arg;
}

sub insert {
    my $this = shift;
    my $val  = $this->{val};
    my $N    = $this->{days};

    croak "You must set the number of days before you try to insert" if not defined $N;

    while( defined(my $PM = shift) ) {
        push @$val, $PM;

        if( @$val >= $N ) {
            if( defined( my $s = $this->{SMA} ) ) {
                my $old = shift @$val;
                $this->{SMA} = $s - $old/$N + $PM/$N;

            } else {
                my $sum = 0;
                   $sum += $_ for @$val;

                $this->{SMA} = $sum/$N;
            }
        }
    }
}
*start_with = *insert;

sub query {
    my $this = shift;

    return $this->{SMA};
}

__END__

=head1 NAME

Math::Business::SMA - Technical Analysis: Simple Moving Average

=head1 SYNOPSIS

  use Math::Business::SMA;

  my $sma = new Math::Business::SMA;

  set_days $sma 7;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  foreach(@closing_values) {
      $sma->insert( $_ );
      if( defined(my $q = $sma->query) ) {
          print "SMA value: $q.\n";
      } else {
          print "SMA value: n/a.\n";

          # note that a simple moving average is undefined before 
          # there's enough days to calculate it.
      }
  }

  # you may use this to kick start 
  $sma->start_with( @array_of_days_most_recent_on_right ); 
  # (until version 1.1, this used to take an arrayref, not an array)

=head1 AUTHOR

Paul Miller <jettero@cpan.org>

I am using this software in my own projects...  If you find bugs, please please
please let me know.

I normally hang out on #perl on freenode, so you can try to get immediate
gratification there if you like.  L<irc://irc.freenode.net/perl>

=head1 COPYRIGHT

Copyright (c) 2008 Paul Miller -- LGPL [Software::License::LGPL_2_1]

    perl -MSoftware::License::LGPL_2_1 \
         -e '$l = Software::License::LGPL_2_1->new({
             holder=>"Paul Miller"});
             print $l->fulltext' | less

=head1 SEE ALSO

perl(1)

L<http://en.wikipedia.org/wiki/Simple_moving_average>

=cut
