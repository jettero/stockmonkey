package Math::Business::HMA;

use strict;
use warnings;
use Carp;
use Math::Business::SMA;

our $VERSION = 1.0;

1;

sub recommended { croak "no recommendation" }

sub new { 
    my $class = shift;
    my $this  = bless {
        dat => [
            undef,
            undef,
            undef,
            undef,
        ],
    }, $class;

    croak $@ if $@;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days { 
    my $this = shift; 
    my $arg  = int(shift);

    croak "days must be a positive non-zero even integer" if $arg <= 0 or ($arg/2) =~ m/\./;

    $this->{dat} = [
        $arg,
        $arg/2,
        sqrt($arg),
        Math::Business::SMA->new($arg),
    ];
}

sub insert {
    my $this = shift;
    my ($N, $No2, $sqrtN, $sma) = @{ $this->{dat} };

    # The HMA manages to keep up with rapid changes in price activity whilst
    # having superior smoothing over an SMA of the same period. The HMA employs
    # weighted moving averages and dampens the smoothing effect (and resulting
    # lag) by using the square root of the period instead of the actual period
    # itself…as seen below.

    # Integer (Square Root (Period)) WMA [2 x Integer (Period/2) WMA (Price) -
    # Period WMA (Price)]

    # The following formulas for the Hull Moving Average are for MetaStock and
    # Supercharts but can be easily adapted for use with other charting
    # programs that are capable of custom indicator construction.

    # MetaStock Formula
    # period:=Input("period",1,200,20);sqrtperiod:=Sqrt(period);Mov(2*Mov(C,period/2,W)
    # - Mov(C,period,W),LastValue(sqrtperiod),W);

    # SuperCharts Formula
    # Input: period (Default value 20) waverage (2*waverage
    # (close,period/2)-waverage (close,period), SquareRoot (Period))

    # A simple application for the HMA, given its superior smoothing, would be
    # to employ the turning points as entry/exit signals. However it shouldn't
    # be used to generate crossover signals as this technique relies on lag.

    croak "You must set the number of days before you try to insert" if not defined $N;
    while( defined(my $P = shift) ) {
        $sma->insert($P);
    }
}

sub start_with {
    die "todo";
}

sub query {
    my $this = shift;

    return $this->{HMA};
}

__END__

=head1 NAME

Math::Business::HMA - Technical Analysis: Hull Moving Average

=head1 SYNOPSIS

  use Math::Business::HMA;

  my $avg = new Math::Business::HMA;
     $avg->set_days(8);

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  # choose one:
  $avg->insert( @closing_values );
  $avg->insert( $_ ) for @closing_values;

  if( defined(my $q = $avg->query) ) {
      print "value: $q.\n";  

  } else {
      print "value: n/a.\n";
  }

To avoid recalculating huge lists when you add a few new values on the end;

  $avg->start_with( $the_last_calculated_value );

For short, you can skip the set_days() by suppling the setting to new():

  my $longer_avg = new Math::Business::HMA(10);

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

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://www.alanhull.com.au/hma/hma.html>

=cut
