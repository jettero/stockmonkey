#!/usr/bin/perl

use strict;
use Math::Business::EMA;
use Math::Business::RSI;
use Finance::QuoteHist;
use Data::Dump qw(dump);

my $ema = new Math::Business::EMA(20);
my $rsi = new Math::Business::RSI(14); 
 # $rsi->set_cutler;

if( -f "qdump.txt" ) {
    my @close = do "qdump.txt";

    $ema->insert( @close );
    $rsi->insert( @close );

} else {
    my @close;
    my $q = Finance::QuoteHist->new(symbols => 'MSFT', start_date => '10/30/2005', end_date => '06/14/2008' );
    for my $row ($q->quotes()) {
        my ($symbol, $date, $open, $high, $low, $close, $volume, $xclose) = @$row;
        push @close, $close;

        $ema->insert( $close );
        $rsi->insert( $close );
    }

    open my $d, ">qdump.txt";
    print $d dump(@close);
    close $d;
}

if( defined(my $q = $ema->query) ) {
    print "EMA value: $q.\n";

} else {
    print "EMA value: n/a.\n";
}

if( defined(my $q = $rsi->query) ) {
    print "RSI: $q.\n";

} else {
    print "RSI: n/a.\n";
}
