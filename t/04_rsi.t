# vi:fdm=marker fdl=0 syntax=perl:
# $Id: main.t,v 1.1 2004/12/02 21:11:53 jettero Exp $

use Test;
use strict;
use Math::Business::RSI;

plan tests => 2;

my $rsi = new Math::Business::RSI;
   $rsi->set_days(14);

my @todd_litteken = qw(
    46.1250 47.1250 46.4375 46.9375 44.9375 44.2500 44.6250 45.7500 47.8125 47.5625
    47.0000 44.5625 46.3125 47.6875 46.6875 45.6875 43.0625 43.5625 44.8750 43.6875
);

my @RSI_todd = qw( 51.7787 48.4771 41.0734 42.8634 47.3818 43.9921 );

$rsi->insert(splice @todd_litteken, 0, 13);

ok( $rsi->query, undef );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );

$rsi->insert(shift @todd_litteken);
ok( $rsi->query, $RSI_todd[0] );
