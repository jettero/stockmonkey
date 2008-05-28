# vi:fdm=marker fdl=0 syntax=perl:
# $Id: main.t,v 1.1 2004/12/02 21:11:53 jettero Exp $

use Test;

plan tests => 4;

use Math::Business::MACD; ok 1;

$macd = new Math::Business::MACD;

$macd->set_days(26, 12, 9);

$macd->insert( 3 ) for 1..25; ok !defined($macd->query);
$macd->insert( 3 );           ok( defined($macd->query) and 0 == $macd->query );

$macd->insert( 30 ); ok( $macd->query > 0 );  # this is good enough for me really.
