
use Test;
use strict;

use Math::Business::HMA;

my $N   = 14;
my $Dp  = 250;
my @data = (map {int(3 + rand 9)} 1 .. $N+$Dp);
my $hma = Math::Business::HMA->new(14);

plan tests => $N+$Dp;

my $min = my $max = $data[0];

my $ok = 1;
for my $data (@data) {
    $hma->insert($data);
    $min = $data if $data < $min;
    $max = $data if $data > $max;

    if( defined( my $h = $hma->query ) ) {
        ok( $h >= $min and $h <= $max );
        $ok = 0;

    } else {
        ok($ok);
    }
}
