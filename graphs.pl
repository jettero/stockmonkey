#!/usr/bin/perl -Iblib/lib

use strict;
use Math::Business::ParabolicSAR;
use GD::Graph::mixed;

my $sar = Math::Business::ParabolicSAR->recommended;

my @ohlc = @{do "msft_6-16-8.txt"};
my @data = ([ 0 .. $#ohlc ]);

for my $p (@ohlc) {
    $sar->insert($p);

    push @{$data[1]}, $p->[3];
    push @{$data[2]}, $sar->query;
}

my $graph = GD::Graph::mixed->new(1280, 500);
   $graph->set(
       x_label           => 'X date',
       y_label           => 'Y kill:death -1',
       y_max_value       =>  1.5,
       y_min_value       => -1.5,
       y_number_format   => '%0.1f',
       x_labels_vertical => 1,
       types             => [qw(linespoints points)],

   ) or die $graph->error;

my $gd = $graph->plot(\@data) or die $graph->error;
open my $img, '>', "sar.png" or die $!;
binmode $img;
print $img $gd->png;
close $img;
