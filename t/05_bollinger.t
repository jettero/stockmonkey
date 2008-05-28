# vi:fdm=marker fdl=0 syntax=perl:
# $Id: main.t,v 1.1 2004/12/02 21:11:53 jettero Exp $

use Test;
use strict;
use Math::Business::BollingerBands;

my $bb = new Math::Business::BollingerBands(20,2);

# NOTE: This example was taken from
# http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:bollinger_bands
# 05/28 2008

my @closes = qw(
    103.13 109.00 103.06 102.75 108.00 107.56 105.25 107.69 108.63 107.00
    109.00 110.00 112.75 113.50 114.25 115.25 121.50 126.88 122.50 119.00
    122.50 118.00 122.00 121.19 123.63 122.75 123.13 122.13 119.00 112.69
);

my @matchers = (
    # The stockcharts csample alculations were altered by as much as 2 cents
    # here-and-there because we don't throw away as much roundoff error as
    # their spreadsheet apparently does.

    [qw(124.62 111.34 98.05)],
    [qw(125.86 112.30 98.74)],
    [qw(126.48 112.75 99.03)],
);

my ($L,$M,$U,$match);

plan tests => 3*(1+@matchers);

$bb->insert(splice @closes, 0, 19);
($L,$M,$U) = $bb->query;
ok( $L, undef );
ok( $M, undef );
ok( $U, undef );

while( $match = shift @matchers ) {
    $bb->insert(shift @closes);
    ($L,$M,$U) = $bb->query;
    ok( sprintf('%0.2f', $L), sprintf('%0.2f', $match->[2]) );
    ok( sprintf('%0.2f', $M), sprintf('%0.2f', $match->[1]) );
    ok( sprintf('%0.2f', $U), sprintf('%0.2f', $match->[0]) );
}
