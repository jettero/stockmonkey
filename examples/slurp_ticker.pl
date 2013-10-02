#!/usr/bin/perl

use strict;
use Data::Dump qw(dump);

my @tickers = @_;
push @tickers, "MSFT" unless @tickers;

use Finance::QuoteHist;
my $q = Finance::QuoteHist->new(
    symbols    => [@tickers],
    start_date => '6 months ago',
    end_date   => 'today',
);

my @todump;
for my $row ($q->quotes) {
    my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

    push @todump, [ $date, $open,$high,$low,$close ];
}

print "my \@res =\n\n";
print dump(@todump), ";\n\n";
print "\\\@res;\n";
