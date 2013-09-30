#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(store retrieve);
use Algorithm::NaiveBayes;
use Math::Business::RSI;
use Math::Business::LaguerreFilter;
use Data::Dump qw(dump);
use GD::Graph::mixed;
use List::Util qw(min max);
use constant {
    DATE   => 0,
    CLOSE  => 1,
    RSI    => 2,
    LAG4   => 3,
    LAG8   => 4,
    EVENT  => 5,
    BUY_P  => 6,
    SELL_P => 7,
};

my $ticker = shift || "JPM";
my $slurpp = "10 years"; # data we want to fetch
my $quotes = find_quotes_for($ticker=>$slurpp);

scan_for_events();

print dump($quotes), "\n";

# {{{ sub scan_for_events
sub scan_for_events {
    my $last_row = $quotes->[0];

    for my $row ( @$quotes[1..$#$quotes] ) {
        if( $last_row->[RSI] < 70 and $row->[RSI] >= 70 ) {
            $row->[EVENT] = "OVERBOUGHT-1";
        }

        if( $last_row->[RSI] > 30 and $row->[RSI] <= 30 ) {
            $row->[EVENT] = "OVERSOLD-1";
        }

        if( not exists $row->[EVENT] and exists $last_row->[EVENT] ) {
            my ($event, $age) = $last_row->[EVENT] =~ m/(\w+)-(\d+)/;
            $row->[EVENT] = "$event-" . ($age+1);
        }

        if( exists $row->[EVENT] and my ($event, $age) = $row->[EVENT] =~ m/(\w+)-(\d+)/ ) {
            if( $event eq "OVERBOUGHT" and $last_row->[RSI] > 60 and $row->[RSI] <= 60 ) {
                $row->[EVENT] = "DOWNBREAK-1";
            }

            if( $event eq "OVERSOLD" and $last_row->[RSI] < 40 and $row->[RSI] >= 40 ) {
                $row->[EVENT] = "UPBREAK-1";
            }

            if( $event eq "DOWNBREAK" and ????
        }

        $last_row = $row;
    }
}

# }}}
# {{{ sub find_quotes_for
sub find_quotes_for {
    our $rsi  ||= Math::Business::RSI->recommended;
    our $lag4 ||= Math::Business::LaguerreFilter->new(2/(1+4));
    our $lag8 ||= Math::Business::LaguerreFilter->new(2/(1+8));

    my $tick = uc(shift || "MSFT");
    my $time = lc(shift || "6 months");
    my $fnam = "/tmp/$tick-$time.dat";

    my $res = eval { retrieve($fnam) };
    return $res if $res;


    my $q = Finance::QuoteHist->new(
        symbols    => [$tick],
        start_date => "$time ago",
        end_date   => 'today',
    );

    my @todump;
    for my $row ($q->quotes) {
        my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

        my $row = [ $date, $close ];

        $rsi->insert( $close );
        $row->[RSI] = $rsi->query;

        $lag4->insert( $close );
        $row->[LAG4] = $lag4->query;

        $lag8->insert( $close );
        $row->[LAG8] = $lag8->query;

        # only insert rows that are all defined
        push @todump, $row unless grep {not defined} @$row;
    }

    store(\@todump => $fnam);

    return \@todump;
}

# }}}
