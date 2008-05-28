package Math::Business::EMA;

use strict;
use warnings;

use version; our $VERSION = qv('1.5');

use Carp;
use Math::Business::SMA;

1;

sub new { 
    my $class = shift;
    my $this = bless {
        EMA => undef,
        R   => 0,
        R1  => 0,
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

    $this->{R}    = 2.0 / (1.0 + $arg);
    $this->{R1}   = (1 - $this->{R});
    $this->{days} = $arg;
}

sub insert {
    my $this = shift;

    croak "You must set the number of days before you try to insert" if not $this->{R};

    while( defined(my $Yt  = shift) ) {
        if( defined(my $e = $this->{EMA}) ) {
            $this->{EMA} = ( $this->{R} * $Yt ) + ( $this->{R1} * $e );

        } else {
            my ($p,$N);
            if( ref($p = $this->{_p}) and (($N = @$p) >= $this->{days}-1) ) {
                my $sum = 0;
                   $sum += $_ for @$p;

                $this->{EMA} = ( $this->{R} * $Yt ) + ( $this->{R1} * ($sum/$N) );

            } else {
                push @{$this->{_p}}, $Yt;
            }
        }
    }
}

sub start_with {
    my $this = shift;
       $this->{EMA} = shift;

    croak "undefined arg to start_with" unless defined $this->{EMA};
}

sub query {
    my $this = shift;

    return $this->{EMA};
}

__END__

=head1 NAME

Math::Business::EMA - Technical Analysis: Exponential Moving Average

=head1 SYNOPSIS

  use Math::Business::EMA;

  my $ema = new Math::Business::EMA;

  set_days $ema 7;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  foreach(@closing_values) {
      $ema->insert( $_ );
      if( defined(my $q = $ema->query) ) {
          # The first entry is the value of the simple 
          # moving average
          print "EMA value: $q.\n";  
      } else {
          # this is undefined until there's at least
          # $days worth of data...
          print "EMA value: n/a.\n";
      }
  }

  # to avoid recalculating huge lists when 
  # you add a few new values on the end

  $ema->start_with( $the_last_calculated_value );

  # then continue with a foreach over the newly
  # inserted values

  # For short, you can now skip the set_days() by suppling the setting to new():

  my $longer_ema = new Math::Business::EMA(10);

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

perl(1), Math::Business::EMA(3).

L<http://en.wikipedia.org/wiki/Exponential_moving_average>

=cut
