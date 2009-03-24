
use Test;
use strict;

use Math::Business::LaguerreFilter;

my $N   = 14;
my $Dp  = 250;
my @data = (map {int(3 + rand 9)} 1 .. $N+$Dp);
my $lag = Math::Business::LaguerreFilter->new(0.4);
   $lag->set_adaptive(20);

my $min = my $max = $data[0];
for my $data (@data) {
    $min = $data if $data < $min;
    $max = $data if $data > $max;
}

plan tests => 1*@data;

my $ok = 1;
for my $data (@data) {
    $lag->insert($data);

    if( defined( my $h = $lag->query ) ) {
        if( $h >= $min and $h <= $max ) {
            ok(1);

        } else {
            open DUMP, ">dump.txt" or die $!;
            print DUMP "@data";
            close DUMP;
            die " [false]  $h >= $min and $h <= $max \n";
            ok(0);
        }
        $ok = 0;

    } else {
        ok($ok);
    }
}
