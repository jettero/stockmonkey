# vi:fdm=marker fdl=0 syntax=perl:
# $Id: main.t,v 1.1 2004/12/02 21:12:06 jettero Exp $

use Test;

plan tests => 5;

use Math::Business::SMA; ok 1;

$sma = new Math::Business::SMA;

$sma->set_days(3);


$sma->insert( 3 ); ok !defined($sma->query);
$sma->insert( 8 ); ok !defined($sma->query);
$sma->insert( 9 ); ok (((3 + 8 + 9)/3.0) == $sma->query);
$sma->insert( 7 ); ok (((8 + 9 + 7)/3.0) == $sma->query);
