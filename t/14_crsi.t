

use Test;
use strict;
no warnings;

use Math::Business::ConnorRSI;

my $crsi = Math::Business::ConnorRSI->new(3,2,100);
my $data = do 'jpm-2013-10-02.txt' or die "problem loading test data: $!$@";

my @crsi_from_tradeingview_d_com = (
    10.7726, # 9/24
    74.1468, # 9/25
    64.6039, # 9/26
    73.8535, # 9/27
    26.7223, # 9/30
    57.4290, # 10/1
);

my @mb_crsi;

for my $row (@$data) {
    $crsi->insert($row->[-1]);
    my $v = $crsi->query;

    push @mb_crsi, $v;
}

plan tests => 0+@crsi_from_tradeingview_d_com;

while( @crsi_from_tradeingview_d_com ) {
    my $tv_crsi = pop @crsi_from_tradeingview_d_com;
    my $mb_crsi = pop @mb_crsi;

    my $d = abs($tv_crsi - $mb_crsi);

    if( $d < 1 ) {
        ok( 1 );

    } else {
        ok($mb_crsi, $tv_crsi);
    }
}
