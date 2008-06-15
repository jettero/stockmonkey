#!/usr/bin/perl

use Test;
use Math::Business::EMA;
use Math::Business::RSI;

plan tests => 3;

my $rsi = new Math::Business::RSI(14); 
my $rec = recommended Math::Business::RSI;

if( -f "msft_6-13-8.txt" ) {
    my @close = do "msft_6-13-8.txt";

    $rsi->insert( @close );
    $rec->insert( @close );
}

my $r = $rsi->query;
my $c = $rec->query;

my $r_d = abs($r - 54.9);
my $c_d = abs($c - 54.9);

ok( $r_d<0.2 );
ok( $c_d<0.2 );
ok( $r, $c );
