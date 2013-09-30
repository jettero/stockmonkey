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

my $ticker = shift || "JPM";
my $slurpp = "10 years"; # data we want to fetch
my $quotes = find_quotes_for($ticker=>$slurpp);

scan_for_events();

print dump($quotes), "\n";

# {{{ sub scan_for_events
sub scan_for_events {
    my $last_row = $quotes->[0];

    for my $row ( @$quotes[1..$#$quotes] ) {
        if( $last_row->{rsi} < 70 and $row->{rsi} >= 70 ) {
            $row->{event} = "OVERBOUGHT-1";
        }

        if( $last_row->{rsi} > 30 and $row->{rsi} <= 30 ) {
            $row->{event} = "OVERSOLD-1";
        }

        if( not exists $row->{event} and exists $last_row->{event} ) {
            my ($event, $age) = $last_row->{event} =~ m/(\w+)-(\d+)/;
            $row->{event} = "$event-" . ($age+1);
        }

        if( exists $row->{event} and my ($event, $age) = $row->{event} =~ m/(\w+)-(\d+)/ ) {
            if( $event eq "OVERBOUGHT" and $last_row->{rsi} > 60 and $row->{rsi} <= 60 ) {
                delete $row->{event};
                if( $row->{lag4} < $row->{lag8} ) {
                    $row->{EVENT} = "SELL";
                }
            }

            if( $event eq "OVERSOLD" and $last_row->{rsi} < 40 and $row->{rsi} >= 40 ) {
                delete $row->{event};
                if( $row->{lag4} > $row->{lag8} ) {
                    $row->{EVENT} = "BUY";
                }
            }
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
    my $fnam = "/tmp/p2-$tick-$time.dat";

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

        $rsi->insert( $close );
        $lag4->insert( $close );
        $lag8->insert( $close );

        my $row = {
            date  => $date,
            close => $close,
            rsi   => $rsi->query,
            lag4  => $lag4->query,
            lag8  => $lag8->query,
        };

        # only insert rows that are all defined
        push @todump, $row unless grep {not defined} values %$row;
    }

    store(\@todump => $fnam);

    return \@todump;
}

# }}}
