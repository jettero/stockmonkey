
use Test;
use strict;

use Math::Business::HMA;

my $N    = 14;
my $Dp   = 250;
my @data = (map {int(3 + rand 9)} 1 .. $N+$Dp);
my $hma  = Math::Business::HMA->new(14);

my $min = my $max = $data[0];
for my $data (@data) {
    $min = $data if $data < $min;
    $max = $data if $data > $max;
}

plan tests => 1*@data;

my $ok = 1;
my @lt;
my @std;
for my $data (@data) {
    $hma->insert($data);

    my $m = $min;
    my $M = $max;

    push @lt, $data;
    if( @lt>=3 ) {
        shift @lt while @lt>3;
        my $sum = 0; $sum += $_ for @lt;
        my $avg = $sum/@lt;
        my $var = 0; $var += ($avg - $_)**2 for @lt;
        my $std = sqrt $var;

        push @std, $std;
        shift @std while @std>5;
        $sum = 0; $sum += $_ for @std;
        $avg = $sum/@std;

        $m -= $avg;
        $M += $avg;

        # NOTE: we're adding in the average std dev because with this really
        # random data the HMA is frequently outside the min-max boundaries.
    }

    if( defined( my $h = $hma->query ) ) {
        if( $h >= $m and $h <= $M ) {
            ok(1);

        } else {
            open DUMP, ">dump.txt" or die $!;
            print DUMP "@data";
            close DUMP;
            die " [false]  $h >= $m and $h <= $M \n";
            ok(0);
        }
        $ok = 0;

    } else {
        ok($ok);
    }
}
