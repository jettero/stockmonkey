package Math::Business::ATR;

use strict;
use warnings;
use Carp;

1;

sub recommended {
    my $class = shift;

    $class->new(14);
}

sub new { 
    my $class = shift;
    my $this  = bless {
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

    # NOTE: wilder uses 13/14 * last + 1/14 * current for his exponential average ...
    # probably wouldn't have been my first choice, but that's how ATR is defined.

    $this->{days} = $arg;
    $this->{R}  = ($arg-1)/$arg;
    $this->{R1} = 1/$arg;
}

sub insert {
    my $this = shift;

    my $y_close = $this->{y_close};
    while( defined( my $point = shift ) ) {
        croak "insert takes three touples [high, low, close]" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        if( defined $y_close ) {
            my $A = abs( $t_high - $t_low );
            my $B = abs( $t_high - $y_close );
            my $C = abs( $t_low  - $y_close );

            my $true_range = $A;
               $true_range = $B if $B > $true_range;
               $true_range = $C if $C > $true_range;

            if( defined(my $atr = $this->{ATR}) ) {
                $this->{ATR} = $this->{R} * $atr + $this->{R1} * $true_range;

            } else {
                my $p;
                my $N = $this->{days};
                if( ref($p = $this->{_p}) and (@$p >= $N-1) ) {
                    my $sum = 0;
                       $sum += $_ for @$p;
                       $sum += $true_range;

                    $this->{ATR} = $sum / $N;

                } else {
                    push @{$this->{_p}}, $true_range;
                }
            }

        } else {
            my $true_range = $t_high - $t_low;

            # NOTE: _p shouldn't exist because this initializer is only used for the very first entry
            die "something is clearly wrong, see note below above line" if exists $this->{_p};

            # NOTE: this initializer sucks because the calculation is done
            # differently than it would be if you had data from the day before.
            # IMO, we should just return undef for an extra day, but this
            # appears to be by definition, so we do it:

            $this->{_p} = [$true_range];
        }

        $y_close = $t_close;
    }

    $this->{y_close} = $y_close;
}

sub start_with {
    my $this = shift;
    croak "you must provide: (yesterday's close, yesterday's ATR)" unless @_ == 2;

    $this->{y_close} = shift;
    $this->{ATR}     = shift;
}

sub query {
    my $this = shift;

    return $this->{ATR};
}

__END__

=head1 NAME

Math::Business::ATR - Technical Analysis: Average True Range

=head1 SYNOPSIS

  use Math::Business::ATR;

  my $atr = new Math::Business::ATR;
     $atr->set_days(14);

  # alternatively/equivilently
  my $atr = new Math::Business::ATR(14);

  # or to just get the recommended model ... (14)
  my $atr = Math::Business::ATR->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one: 
  $atr->insert( @data_points );
  $atr->insert( $_ ) for @data_points;

  my $atr = $atr->query;

  if( defined( my $q = $atr->query ) ) {
      print "ATR: $q.\n";

  } else {
      print "ATR: n/a.\n";
  }

  # you may use this to kick start 
  $atr->start_with( $yesterday_close, $old_atr );

=head1 RESEARCHER

The ATR was designed by J. Welles Wilder Jr circa 1978.

The ATR is meant to be a measure of the volatility of the stock price.  It
does not provide any indication of the direction of the moves, only how
erratic the moves may be.

Wilder felt that large ranges meant traders are willing to I<continue>
bidding up (or selling down) a stock.

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

L<http://fxtrade.oanda.com/learn/graphs/indicators/atr.shtml>

=cut
