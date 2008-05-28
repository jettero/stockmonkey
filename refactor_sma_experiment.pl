#!/usr/bin/perl

use strict;
use List::Util qw(sum);

my @start = map {12 + int rand 37} 1 .. 7;
my @next  = map {12 + int rand 7}  1 .. 7;

my $N = @start;

my $last;
for my $next (@next) {
    my $old = shift @start;
    push @start, $next;

    my $sum = sum @start;
    my $avg = $sum/$N;
    my $ref = $last - $old/$N + $next/$N;

    printf 'avg=%05.2f; ref=%05.2f%s', $avg, $ref, "\n";

    $last = $avg;
}

