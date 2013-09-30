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

# {{{ sub scan_for_events
sub scan_for_events {
    my $last_row = $quotes->[0];

    local $| = 1; # print immediately, don't buffer lines

    for my $row ( @$quotes[1..$#$quotes] ) {

        if( exists $last_row->{event} ) {
            if( not exists $last_row->{max_age} ) {
                $row->{event}   = $last_row->{event};
                $row->{age}     = 1 + $last_row->{age};

            } elsif( $last_row->{age} < $last_row->{max_age} ) {
                $row->{event}   = $last_row->{event};
                $row->{age}     = 1 + $last_row->{age};
                $row->{max_age} = $last_row->{max_age};
            }
        }

        if( $last_row->{rsi} < 70 and $row->{rsi} >= 70 ) {
            $row->{event} = "OVERBOUGHT";
            $row->{age} = 1;
            delete $row->{max_age};
            print "$row->{event} ";
        }

        if( $last_row->{rsi} > 30 and $row->{rsi} <= 30 ) {
            $row->{event} = "OVERSOLD";
            $row->{age} = 1;
            delete $row->{max_age};
            print "$row->{event} ";
        }

        next unless exists $row->{event};

        if( $row->{event} eq "OVERBOUGHT" and $last_row->{rsi} > 60 and $row->{rsi} <= 60 ) {
            $row->{event}   = "DIP";
            $row->{age}     = 1;
            $row->{max_age} = 3;
            print "$row->{event} ";
        }

        elsif ( $row->{event} eq "OVERSOLD" and $last_row->{rsi} < 40 and $row->{rsi} >= 40 ) {
            $row->{event}   = "SPIKE";
            $row->{age}     = 1;
            $row->{max_age} = 3;
            print "$row->{event} ";
        }

        if( $row->{event} eq "DIP" and $last_row->{lag4} < $last_row->{lag8} ) {
            $row->{event}   = "SELL";
            $row->{age}     = 1;
            $row->{max_age} = 1;
            print "!$row->{event}! ";
        }

        if( $row->{event} eq "SPIKE" and $last_row->{rsi} < 40 and $row->{rsi} >= 40 ) {
            $row->{event}   = "BUY";
            $row->{age}     = 1;
            $row->{max_age} = 1;
            print "!$row->{event}! ";
        }

        $last_row = $row;
    }

    print "\n";
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
