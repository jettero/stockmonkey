
use Test;
use strict;
use Math::Business::DMI;

my @dmiData = (
    [ 168, 166, 167 ],
    [ 168, 166, 168 ],
    [ 168, 166, 168 ],
    [ 168, 166, 168 ],
); 

my $adx = recommended Math::Business::DMI;

plan tests => 2;

my $i = eval { $adx->insert(@dmiData); 1};
warn " error inserting data: $@" unless $i;

ok( $i );
ok(eval { $adx->query; 1});
