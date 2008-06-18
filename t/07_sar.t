#!/usr/bin/perl

use Test;
use Math::Business::ParabolicSAR;
use Data::Dumper;

plan tests => 7;

my $sar = recommended Math::Business::ParabolicSAR;

if( -f "msft_6-16-8.txt" ) {
    my $ohlc = do "msft_6-16-8.txt";
    die $! if $!;
    die $@ if $@;
    die "unknown error: " . Dumper($ohlc) unless ref($ohlc) and @$ohlc > 10;

    my @totest = splice @$ohlc, -7;
    my @sarz = (
        [ 28.2, '6/6'  ],
        [ 28.0, '6/9'  ],
        [ 27.2, '6/10' ],
        [ 28.3, '6/11' ],
        [ 27.1, '6/12' ],
        [ 27.2, '6/13' ],
        [ 27.3, '6/16' ],
    );

    $sar->insert( @$ohlc );

    warn "\n\n";
    for my $row (@totest) {
        $sar->insert( $row );

        my $q = $sar->query;
        my $p = shift @sarz;
        my $d = abs($q-$p->[0]);

        if( 0 ) {
            ok(1);

        } else {
            warn " \e[31mfailed $p->[1] \e[1;33m$p->[0] != $q\e[m\n";
            ok(0);
        }
    }

} else {
    die "bad MANIFEST?";
}

