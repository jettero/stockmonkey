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
plot_result();

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
            $row->{max_age} = 5;
            print "$row->{event} ";
        }

        elsif ( $row->{event} eq "OVERSOLD" and $last_row->{rsi} < 40 and $row->{rsi} >= 40 ) {
            $row->{event}   = "SPIKE";
            $row->{age}     = 1;
            $row->{max_age} = 5;
            print "$row->{event} ";
        }

        if( $row->{event} eq "DIP" and $row->{lag4} < $row->{lag8} ) {
            $row->{event}   = "SELL";
            $row->{age}     = 1;
            $row->{max_age} = 1;
            print "!$row->{event}! ";
        }

        elsif( $row->{event} eq "SPIKE" and $row->{lag4} > $row->{lag8} ) {
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
# {{{ sub plot_result
sub plot_result {
    # {{{ my $gd_price = do
    my $gd_price = do {
        my @data;

        for(@$quotes[-300 .. -1]) {
            no warnings 'uninitialized'; # most of the *_P are undefined, and that's ok! treat them as 0

            push @{ $data[0] }, ''; # $_->{date};
            push @{ $data[1] }, $_->{close};
        }

        my $min_point = min( grep {defined} map {@$_} @data[1..$#data] );
        my $max_point = max( grep {defined} map {@$_} @data[1..$#data] );

        my $width = 100 + 11*@{$data[0]};

        my $graph = GD::Graph::mixed->new($width, 500);
           $graph->set_legend(map { sprintf "%6s",$_ } qw(close) );
           $graph->set(
               legend_placement  => 'RT',
               y_label           => "dollars $ticker",
               x_label           => '',
               transparent       => 0,
               dclrs             => [qw(dgray)],
               types             => [qw(lines)],
               y_min_value       => $min_point-0.2,
               y_max_value       => $max_point+0.2,
               y_number_format   => '%6.2f',
               x_labels_vertical => 1,

           ) or die $graph->error;

        # return gd
        $graph->plot(\@data) or die $graph->error;
    };

    # }}}
    # {{{ my $gd_rsi = do
    my $gd_rsi = do {
        my @data;

        for(@$quotes[-300..-1]) {
            no warnings 'uninitialized'; # most of the *_P are undefined, and that's ok! treat them as 0

            push @{ $data[0] }, $_->{date};
            push @{ $data[1] }, $_->{rsi};
        }

        my $width = 100 + 11*@{$data[0]};

        my $graph = GD::Graph::mixed->new($width, 150);
           $graph->set_legend( map { sprintf "%6s", $_ } qw(rsi) );
           $graph->set(
               legend_placement  => 'RT',
               y_label           => "rsi $ticker",
               x_label           => 'date',
               transparent       => 0,
               dclrs             => [qw(dgray)],
               types             => [qw(lines)],
               y_min_value       => 0,
               y_max_value       => 100,
               y_number_format   => '%6.2f',
               x_labels_vertical => 1,

           ) or die $graph->error;

        my $gd = $graph->plot(\@data) or die $graph->error;

        my @lhs = $graph->val_to_pixel(0,50);
        my @rhs = $graph->val_to_pixel( @{$data[0]}-1, 50 );

        # XXX: hack alert... {fgci} is the color of the axis

        my $rsi_axis_clr = $graph->set_clr(GD::Graph::colour::_rgb('lgrey'));

        $gd->line(@lhs,@rhs,$rsi_axis_clr);

        # return
        $gd;
    };

    # }}}

    die "something is wrong" unless $gd_price->width == $gd_rsi->width;

    my $gd = GD::Image->new( $gd_price->width, $gd_price->height + $gd_rsi->height );

    # $image->copyMergeGray($sourceImage,$dstX,$dstY, $srcX,$srcY,$width,$height,$percent)

    $gd->copy( $gd_price, 0,0,                 0,0, $gd_price->width, $gd_price->height);
    $gd->copy( $gd_rsi,   0,$gd_price->height, 0,0, $gd_rsi->width,   $gd_rsi->height);

    open my $img, '>', ".graph.png" or die $!;
    binmode $img;
    print $img $gd->png;
    close $img;

    system(qw(eog .graph.png));
}

# }}}
