# vi:syntax=perl:

use strict;
use Test;

plan tests => 2;

use Math::Business::EMA; ok 1;

my $ema = new Math::Business::EMA(3);

$ema->insert(3);
$ema->insert(7);
$ema->insert(9);

ok( $ema->query, (6 + (1/3.0)) );

