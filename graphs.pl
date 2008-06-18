#!/usr/bin/perl -Iblib/lib

use strict;
use Math::Business::ParabolicSAR;
use Math::Business::EMA;
use GD::Graph::mixed;
use List::Util qw(min max);;

my $sar = Math::Business::ParabolicSAR->recommended;
my $ema = Math::Business::EMA->new(15);

my @ohlc = @{do "msft_6-16-8.txt"}; shift @ohlc while @ohlc>100;
my @data = ([ 0 .. $#ohlc ]); # [0]

for my $p (@ohlc) {
    $sar->insert($p);
    $ema->insert($p->[3]);

    my $x = 1;

    push @{$data[$x++]}, $p->[3]; # close [1]
    push @{$data[$x++]}, $p->[1]; # high  [2]
    push @{$data[$x++]}, $p->[2]; # low   [3]
    push @{$data[$x++]}, $sar->query; # [4]
    push @{$data[$x++]}, $ema->query; # [4]
}

my $graph = GD::Graph::mixed->new(800, 600);
   $graph->set(
       y_label           => 'Dollahz',
       transparent       => 0,
       markers           => [qw(7 3 9 8)],
       dclrs             => [qw(black lgreen lred lblue)],
       y_max_value       => (max(@{$data[2]})+0.1),
       y_min_value       => (min(@{$data[3]})-0.1),
       y_number_format   => '%0.2f',
       x_labels_vertical => 1,
       types             => [qw(linespoints points points points)],

   ) or die $graph->error;

my $gd = $graph->plot(\@data) or die $graph->error;
open my $img, '>', "sar.png" or die $!;
binmode $img;
print $img $gd->png;
close $img;

system(qw(eog -f sar.png));

__END__
This controls the order of markers in points and linespoints graphs.  This should be a reference to an array of
numbers:

    $graph->set( markers => [3, 5, 6] );

Available markers are: 1: filled square, 2: open square, 3: horizontal cross, 4: diagonal cross, 5: filled dia-
mond, 6: open diamond, 7: filled circle, 8: open circle, 9: horizontal line, 10: vertical line.  Note that the
last two are not part of the default list.

Default: [1,2,3,4,5,6,7,8]
