package Math::Business::RSI;

use strict;
use warnings;
use Math::Business::SMA;
use Math::Business::EMA;

use version; our $VERSION = qv("1.00");

use Carp;

1;

sub new { 
    my $class = shift;
    my $this  = bless {
        val => [],
        mov => Math::Business::EMA->new,
        rec => 1,
        cur => undef,
    }, $class;

    return $this;
}

sub set_standard {
    my $this = shift;
    my $rm   = ref $this->{mov};

    if( $rm =~ m/SMA/ ) {
        $this->{mov} = Math::Business::EMA->new;
        $this->{mov}->set_days( $this->{days} ) if $this->{days};
    }
}

sub set_cutler {
    my $this = shift;
    my $rm   = ref $this->{mov};

    if( $rm =~ m/EMA/ ) {
        $this->{mov} = Math::Business::SMA->new;
        $this->{mov}->set_days( $this->{days} ) if $this->{days};
    }
}

sub set_days { 
    my $this = shift; 
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{mov}->set_days($this->{days} = $arg);
}

sub insert {
    my $this = shift;
    my $arg  = shift;

    croak "You must set the number of days before you try to insert" if not $this->{days};
}

sub start_with {
    my $this = shift;

    die "unfinished"
}

sub query {
    my $this = shift;

    return $this->{cur};
}

__END__

=head1 NAME

Math::Business::RSI - Technical Analysis: Relative Strength Index

=head1 SYNOPSIS

  use Math::Business::RSI;

  my $rsi = new Math::Business::RSI;

  set_days $rsi 7;

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
  $sma->start_with( [@array_of_days_most_recent_on_right] );

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

L<http://en.wikipedia.org/wiki/Relative_Strength_Index>

=cut
