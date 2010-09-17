package Math::Business::BollingerBands;

use strict;
use warnings;
use Carp;

our $VERSION = 2.4;

1;

sub recommended {
    my $class = shift;

    $class->new(20, 2);
}

sub new {
    my $class = shift;
    my $this  = bless {
        dev => [],
        val => [],
        N => undef, # days in the average
        K => undef, # deviations
    }, $class;

    if( @_ == 2 ) {
        $this->set_days($_[0]);
        $this->set_deviations($_[1]);
    }

    return $this;
}

sub set_deviations {
    my $this = shift;
    my $arg  = int shift;

    croak "deviations must be a positive non-zero integer" if $arg <= 0;
    $this->{K} = $arg;
}

sub set_days {
    my $this = shift;
    my $arg  = int shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;
    $this->{N} = $arg;

    $this->{val} = [];
    $this->{dev} = [];

    delete $this->{M};
    delete $this->{U};
    delete $this->{L};
}

sub insert {
    my $this = shift;
    my $val  = $this->{val};
    my $dev  = $this->{dev};

    my $N = $this->{N};
    my $K = $this->{K};

    croak "You must set the number of days and deviations before you try to insert" unless $N and $K;
    while( defined(my $value = shift) ) {
        push @$val, $value;

        if( @$val >= $N ) {
            if( defined( my $s = $this->{M} ) ) {
                my $old = shift @$val;
                $this->{M} = my $M = $s - $old/$N + $value/$N;

                push @$dev, (my $new = ($value - $M)**2);
                $old = shift @$dev;

                my $d = $this->{d};
                $this->{d} = $d = $d - $old/$N + $new/$N;

                my $k_stddev = $K * ($d<0.000_000_000_6 ? 0 : sqrt($d));
                $this->{L} = $M - $k_stddev;
                $this->{U} = $M + $k_stddev;

            } else {
                my $sum = 0;
                   $sum += $_ for @$val;

                $this->{M} = my $M = $sum/$N;
                @$dev = map {($_-$M)**2} @$val;

                $sum = 0;
                $sum += $_ for @$dev;

                $this->{d} = my $d = $sum/$N;

                my $k_stddev = $K * ($d<0.000_000_000_6 ? 0 : sqrt($d));
                $this->{L} = $M - $k_stddev;
                $this->{U} = $M + $k_stddev;
            }
        }
    }
}

sub query {
    my $this = shift;

    return ($this->{L}, $this->{M}, $this->{U}) if wantarray;
    return $this->{M};
}

__END__

=head1 NAME

Math::Business::BollingerBands - Technical Analysis: Bollinger Bands

=head1 SYNOPSIS

  use Math::Business::BollingerBands;

  my $bb = new Math::Business::BollingerBands;
     $bb->set_days(20);
     $bb->set_deviations(2);

  # alternatively/equivalently
  my $bb = new Math::Business::BollingerBands(20, 2);

  # or to just get the recommended model ... (20, 2);
  my $bb = Math::Business::BollingerBands->recommended;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $bb->insert( @closing_values );
  $bb->insert( $_ ) for @closing_values;

  my ($L,$M,$U) = $bb->query;
  if( defined $M ) {
      print "BB: $L < $M < $U.\n";

  } else {
      print "BB: n/a.\n";
  }

=head1 RESEARCHER

The Bollinger Bands were designed by John Bollinger in the 1980s.

The bands provide a high and low water mark for the closing price.
Volatility determines the width of the bands.

Conventional wisdom dictates that when prices consistently touch the upper
band they are "overbought" and when they continually touch the lower band
they are "oversold."

When the prices "bounce" off the lower band and cross the middle line, it
is thought to indicate a buy-signal.  The same (but opposite) could be said
about bouncing off the upper band and crossing the middle line on the way
down.

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.

I normally hang out on #perl on freenode, so you can try to get immediate
gratification there if you like.  L<irc://irc.freenode.net/perl>

There is also a mailing list with very light traffic that you might want to
join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright (c) 2010 Paul Miller

=head1 LICENSE

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

[This software may have had previous licenses, of which the current maintainer
is completely unaware.  If this is so, it is possible the above license is
incorrect or invalid.]

=head1 SEE ALSO

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://en.wikipedia.org/wiki/Bollinger_Bands>

L<http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:bollinger_bands>

=cut
