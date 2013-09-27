#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(store retrieve);
use Algorithm::NaiveBayes;
use Math::Business::RSI;
use Data::Dump qw(dump);
use GD::Graph::mixed;
use List::Util qw(min max);
use constant {
    DATE   => 0,
    CLOSE  => 1,
    RSI    => 2,
    BUY_P  => 3,
    SELL_P => 4,
};

my $ticker = shift    || "JPM";
my $slurpp = "@ARGV"  || "2 years";

my $period   = 12;
my $quotes   = find_quotes_for($ticker=>$slurpp);
my $sz       = @$quotes;
my $train_sz = int($sz * (2/3));

train_on( $period+1   .. $train_sz );
solve_on( $train_sz+1 .. $#$quotes );

plot_result();

# {{{ sub solve_on
sub solve_on {
    our $anb ||= Algorithm::NaiveBayes->new;

    for my $i( @_ ) {
        my $day  = $quotes->[$i-$period];
        my $prev = $quotes->[$i-$period-1];

        my $attrs  = find_attrs($day, $prev);
        my $result = $anb->predict(attributes=>$attrs);

        print "[predict] ", dump({given=>$attrs, result=>$result}), "\n";

        $day->[BUY_P]  = $result->{buy};
        $day->[SELL_P] = $result->{sell};
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

        my $label = $pdiff >=  0.05 ? "buy"
                  : $pdiff <= -0.05 ? "sell"
                  : "neutral";

        if( keys %$attrs ) {
            $anb->add_instance( attributes=>$attrs, label=>$label );
            print "[train pdiff=$pdiff] ", dump($attrs), " => $label\n";
        }
    }

    $anb->train;
}

# }}}
# {{{ sub find_attrs
sub find_attrs {
    my ($day, $prev) = @_;

    die "no rsi?? " . dump({day=>$day, prev=>$prev}) unless defined $day->[RSI];
    die "no rsi?? " . dump({day=>$day, prev=>$prev}) unless defined $prev->[RSI];

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
        push @todump, [ $date, $close, $v ] if defined $v;
    }

    store(\@todump => $fnam);

    return \@todump;
}

# }}}
# {{{ sub plot_result
sub plot_result {

    my @data;

    for(@$quotes) {
        no warnings 'uninitialized'; # most of the *_P are undefined, and that's ok! treat them as 0

        push @{ $data[0] }, $_->[DATE];
        push @{ $data[1] }, $_->[CLOSE];
        push @{ $data[2] }, $_->[SELL_P] > 0.6 ? $_->[CLOSE]*0.95 : undef;
        push @{ $data[3] }, $_->[BUY_P]  > 0.6 ? $_->[CLOSE]*1.05 : undef;
    }

    my $min_point = min( grep {defined} map {@$_} @data[1..$#data] );
    my $max_point = max( grep {defined} map {@$_} @data[1..$#data] );

    my $width = 100 + 12*@$quotes;

    my $graph = GD::Graph::mixed->new($width, 500);
       $graph->set_legend(qw(close sell-signal buy-signal));
       $graph->set(
           y_label           => "dollars $ticker",
           x_label           => 'date',
           transparent       => 0,
           dclrs             => [qw(dgray red green)],
           types             => [qw(lines points points)],
           y_min_value       => $min_point-0.2,
           y_max_value       => $max_point+0.2,
           y_number_format   => '%0.2f',
           x_labels_vertical => 1,

       ) or die $graph->error;

    my $gd = $graph->plot(\@data) or die $graph->error;
    open my $img, '>', ".graph.png" or die $!;
    binmode $img;
    print $img $gd->png;
    close $img;

    #system(qw(eog .graph.png));
}

# }}}
