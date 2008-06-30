
use strict;
use Test;

use Math::Business::WMA;

my $N   = 7;
my $Dp  = 3;
my $wma = new Math::Business::WMA($N);

my @data = (map {int(3 + rand 9)} 1 .. $N+$Dp);
my @hand;

for my $i ($N-1 .. $#data) {
    my @ld = grep {defined $_} @data[ $i-($N-1) .. $i ];

    die "hrm" unless @ld == $N;

    my $x = $N;
    my $den = ($N * ($N+1)) / 2;
    my $num = 0;
       $num+= $_ for map { $_*$x-- } @ld;

    $hand[$i] = $num/$den;
}

plan tests => 2*@data;

for my $i (0 .. $#data) {
    $wma->insert($data[$i]);

    my $w = $wma->query;

    ok($wma->query, $hand[$i]);

    if( defined $w ) {
        ok(($w <= 11 and $w >= 3)?"YES":"not within sane numeric boundaries", "YES");

    } else {
        ok(1);
    }
}
