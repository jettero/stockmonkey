#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(store retrieve);
use Algorithm::NaiveBayes;
use Math::Business::RSI;
use Data::Dump qw(dump);
use constant {
    CLOSE => 0,
    RSI   => 1,
};

my $period   = 12;
my $quotes   = find_quotes_for(SCTY=>"6 months");
my $sz       = @$quotes;
my $train_sz = int($sz * (2/3));

train_on( $period+1   .. $train_sz );
solve_on( $train_sz+1 .. $#$quotes );

# {{{ sub solve_on
sub solve_on {
    our $anb ||= Algorithm::NaiveBayes->new;

    for my $i( @_ ) {
        my $day  = $quotes->[$i-$period];
        my $prev = $quotes->[$i-$period-1];

        my $attrs  = find_attrs($day, $prev);
        my $result = $anb->predict(attributes=>$attrs);

        print "[predict] ", dump({given=>$attrs, result=>$result}), "\n";
    }
}

# }}}
# {{{ sub train_on
sub train_on {
    our $anb ||= Algorithm::NaiveBayes->new;

    for my $i( @_ ) {
        my $future = $quotes->[$i];           # the quote we're learning about
        my $day    = $quotes->[$i-$period];   # the quote we can know about beforehand
        my $prev   = $quotes->[$i-$period-1]; # the quote the day before that

        my $attrs = find_attrs($day,$prev);

        my $diff  = $future->[CLOSE] - $day->[CLOSE];
        my $pdiff = $diff / $day->[CLOSE];

        my $label = $pdiff > 0.2 ? "buy"
                  : $pdiff < 0.2 ? "sell"
                  : "neutral";

        $anb->add_instance( attributes=>$attrs, label=>$label );
        print "[train] ", dump($attrs), " => $label\n";
    }

    $anb->train;
}

# }}}
# {{{ sub find_attrs
sub find_attrs {
    my ($day, $prev) = @_;

    my %attrs;

    # traditional interpretations
    $attrs{rsi_overbought} = 1 if $day->[RSI] >= 90;
    $attrs{rsi_oversold} = 1   if $day->[RSI] <= 10;
    $attrs{rsi_sell} = 1       if $day->[RSI] >= 90 and $prev->[RSI] < 90;
    $attrs{rsi_buy} = 1        if $day->[RSI] <= 10 and $prev->[RSI] > 10;
    # NOTE: if I have these backwards, it doesn't really matter, Bayes will sort that out

    # other factoids of questionable value and unknown meaning
    $attrs{rsi_above} = 1           if $day->[RSI] > 50;
    $attrs{rsi_below} = 1           if $day->[RSI] < 50;
    $attrs{rsi_moar_above} = 1      if $day->[RSI] > 65;
    $attrs{rsi_moar_below} = 1      if $day->[RSI] < 35;
    $attrs{rsi_prev_above} = 1      if $prev->[RSI] > 50;
    $attrs{rsi_prev_below} = 1      if $prev->[RSI] < 50;
    $attrs{rsi_prev_moar_above} = 1 if $prev->[RSI] > 65;
    $attrs{rsi_prev_moar_below} = 1 if $prev->[RSI] < 35;
    $attrs{rsi_trend_up}   = 1      if $day->[RSI] > $prev->[RSI];
    $attrs{rsi_trend_down} = 1      if $day->[RSI] < $prev->[RSI];

    return \%attrs;
}

# }}}
# {{{ sub find_quotes_for
sub find_quotes_for {
    our $rsi ||= Math::Business::RSI->recommended;

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

        $rsi->insert( $close );
        my $v = $rsi->query;
        push @todump, [ $close, $v ] if defined $v;
    }

    store(\@todump => $fnam);

    return \@todump;
}

# }}}
