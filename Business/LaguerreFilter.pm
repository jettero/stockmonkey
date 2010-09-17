package Math::Business::LaguerreFilter;

use strict;
use warnings;
use Carp;
use constant {
    ALPHA  =>  2,
    LENGTH =>  3,
    F      => -1,
};

our $VERSION = 1.1; # local revision: d

1;

sub recommended { croak "no recommendation" }

sub new {
    my $class = shift;
    my $this  = bless [], $class;

    my $alpha = shift;
    if( defined $alpha ) {
        $this->set_alpha( $alpha );
    }

    my $length = shift;
    if( defined $length ) {
        $this->set_adaptive( $length );
    }

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = 0+shift;

    my $alpha = 2/(1+$arg);
    eval { $this->set_alpha( $alpha ) };
    croak "set_days() is basically set_alpha(2/(1+$arg)), which complained: $@" if $@;
}

sub set_alpha {
    my $this  = shift;
    my $alpha = 0+shift;

    croak "alpha must be a real between >=0 and <=1" unless $alpha >= 0 and $alpha <= 1;
    @$this = (
        [],    # P-hist
        [],    # L0-L4
        $alpha,
        0,     # adaptive length
        [],    # adaptive diff history
        undef, # filter
    );
}

sub set_adaptive {
    my $this = shift;
    my $that = int shift;

    croak "adaptive length must be an non-negative integer" unless $that >= 0;
    $this->[LENGTH] = $that;
}

sub insert {
    my $this = shift;
    my ($h, $L, $alpha, $length, $diff, $filter) = @$this;

    croak "You must set the number of days before you try to insert" if not defined $alpha;
    no warnings 'uninitialized';

    while( defined( my $P = shift ) ) {
        if( ref $P ) {
            my @a = eval {@$P}; croak $@ if $@;
            my $c = 0+@a;
            croak "high+low should only be two elements, not c=$c" unless $c == 2;
            $P = ($a[0]+$a[1])/$c;
        }

        if( defined $L->[0] ) {
            # adapt alpha {{{
            if( $length and defined($filter) ) {
                my $d = abs($P-$filter);
                push @$diff, $d;

                my $k = @$diff - $length;
                splice @$diff, 0, $k if $k>0;

                if( $k > 0 ) {   # NOTE Ehler really does this, "CurrentBar > Length".  See below.
                                 # IE, $k will only by >0 when we've moved past the 20th point
                    my $HH = $d;
                    my $LL = $d;

                    for(@$diff) {
                        $HH = $_ if $_ > $HH;
                        $LL = $_ if $_ < $LL;
                    }

                    if( $HH != $LL ) {
                        # Ehler: If CurrentBar > Length and HH - LL <> 0 then alpha = Median(((Diff - LL) / (HH - LL)), 5);

                        # NOTE: wtf is a "5 bar median"?  I guess it's this, or
                        # pretty close to it.  I imagine Median() runs through
                        # the [] hist for Diff, LL, and HH, but I can't say for
                        # sure without access to the programming language he
                        # uses in the book.

                        # AVG # my $sum  = ($diff->[-5]-$LL)/($HH-$LL);
                        # AVG #    $sum += ($diff->[$_]-$LL)/($HH-$LL) for (-4 .. -1);

                        # AVG # ($this->[ALPHA] = $alpha = $sum / 5);

                        # NOTE (later): he appears to mean the median (not
                        # average) of a scalar $HH/$LL against the last 5 @diff

                        my @b5 = sort {$a<=>$b}map {(($diff->[$_]-$LL)/($HH-$LL))} -5 .. -1;

                        $this->[ALPHA] = $alpha = $b5[2];
                    }
                }
            }
            # }}}

            my $O = [ @$L ];

            # L0 = alpha*Price + (1 - alpha)*L0[1] = alpha*P + (1-alpha)*O[0]

            $L->[0] = $alpha*$P + (1-$alpha)*$O->[0];

            # L1 = (1 - alpha)*L1[1] - (1 - alpha)*L0 + L0[1] = (1 - alpha)*O[1] - (1 - alpha)*L[0] + O[0]
            # L2 = (1 - alpha)*L2[1] - (1 - alpha)*L1 + L1[1] = (1 - alpha)*O[2] - (1 - alpha)*L[1] + O[1]
            # L3 = (1 - alpha)*L3[1] - (1 - alpha)*L2 + L2[1] = (1 - alpha)*O[3] - (1 - alpha)*L[2] + O[2]

            $L->[1] = defined($O->[1]) ? (1 - $alpha)*$O->[1] - (1 - $alpha)*$L->[0] + $O->[0] : $O->[0];
            $L->[2] = defined($O->[2]) ? (1 - $alpha)*$O->[2] - (1 - $alpha)*$L->[1] + $O->[1] : $O->[1];
            $L->[3] = defined($O->[3]) ? (1 - $alpha)*$O->[3] - (1 - $alpha)*$L->[2] + $O->[2] : $O->[2];

        } else {
            $L->[0] = $P;
        }
    }

    if( 4 == grep {defined $_} @$L ) {
        $this->[F] = ($L->[0] + 2*$L->[1] + 2*$L->[2] + $L->[3])/6;
    }
}

sub query {
    my $this = shift;

    return $this->[F];
}

__END__

=head1 NAME

Math::Business::LaguerreFilter - Technical Analysis: Laguerre Filter

=head1 SYNOPSIS

  use Math::Business::LaguerreFilter;

  my $avg = new Math::Business::LaguerreFilter;
     $avg->set_days(9);
     $avg->set_alpha(0.2); # same (roughly)

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $avg->insert( @closing_values );
  $avg->insert( $_ ) for @closing_values;

  if( defined(my $q = $avg->query) ) {
      print "value: $q.\n";

  } else {
      print "value: n/a.\n";
  }

For short, you can skip the set_alpha() by suppling the setting to new():

  my $avg = new Math::Business::LaguerreFilter(0.2); # same as set_alpha(0.2)

Ehlers actually uses the high and low price, rather than the closing price, in
his book.  The insert method takes either a closing price or the high and low
price as a two-tuple.

    $avg->insert( $close );       # correct
    $avg->insert( [$high,$low] ); # also correct

=head1 RESEARCHER

John F. Ehlers talked about how to adapt Laguerre Polynomials to technical
analysis in an engineering-oriented 2004 book titled I<Cybernetic Analysis for
Stocks and Futures: Cutting-Edge DSP Technology to Improve Your Trading>.

This technique appears in a chapter with the unlikely title
I<Time Warp - Without Space Travel>.

If you locate the chapter or the book, you should read it.  It's written well
and it's a unique way to look at moving averages in general (e.g. there are
filter schematics of each equation).

=head1 THANKS

John Baker C<< <johnb@listbrokers.com> >>

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

=cut
