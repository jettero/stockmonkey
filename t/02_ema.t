# vi:syntax=perl:

use strict;
use Test;

plan tests => 3;

use Math::Business::EMA; ok 1;

my $ema = new Math::Business::EMA(7);

my @seven = (3,7,9,8,8,10,11);

$ema->insert( @seven );

my $a   = 2/(7+1);
my $oma = 1-$a;
my $six = 3+7+9+8+8+10;
   $six = $six / 6;

ok( $ema->query, my $St = ($a*11)+($oma*$six) );

$ema->insert(my $Yt = 15);

ok( $ema->query, ($a*$Yt)+($oma*$St) );
