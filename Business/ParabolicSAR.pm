package Math::Business::ParabolicSAR;

use strict;
use warnings;
use Carp;
use vars qw($x); # like our, but at compile time so these constants work
use constant {
    LONG  => $x++,
    SHORT => $x++,
};

our $VERSION = 1.0;

1;

sub recommended {
    my $class = shift;
       $class->new(0.02, 0.20);
}

sub new {
    my $class = shift;
    my $this  = bless {}, $class;

    if( @_ ) {
       eval { $this->set_alpha(@_) };
       croak $@ if $@;
    }

    return $this;
}

sub set_alpha {
    my $this = shift;
    my ($as,$am) = @_;

    croak "set_alpha(as,am) takes two arguments, the alpha start (0<as<1) and the alpha max (0<as<am<1)"
        unless 0 < $as and $as < $am and $am < 1;

    $this->{as} = $as;
    $this->{am} = $am;

    return;
}

sub insert {
    my $this = shift;

    my ($as,$am);
    croak "must set_alpha(as,am) before inserting data" unless defined( $am = $this->{am} ) and defined( $as = $this->{as} );

    while( defined( my $ar = shift ) ) {
        croak "arguments to insert must be three touples (low,high,close)" unless ref($ar) eq "ARRAY" and @$ar==3 and $ar->[0]<$ar->[1];
        my ($low, $high, $close) = @$ar;

        if( defined( my $ls = $this->{ls} ) ) {
            my $alpha = $this->{a};
            my $ep    = $this->{ep};
            my $sar   = $this->{sar};
            my $lh    = $this->{lh};

            if( $ls == LONG ) {
                $this->{ep} = $ep = $high if $high>$ep;

                $sar = $sar + $alpha * ($ep - $sar);

                if( $sar > $low ) {
                    $sar = $low;
                    $this->{ls} = SHORT;

                } elsif( $sar > $lh->[0] ) {
                    $sar = $lh->[0];
                    $this->{ls} = SHORT;
                }

            } else {
                $this->{ep} = $ep = $low if $low < $ep;

                $sar = $sar + $alpha * ($ep - $sar);

                if( $sar < $high ) {
                    $sar = $high;
                    $this->{ls} = LONG;

                } elsif( $sar < $lh->[1] ) {
                    $sar = $lh->[1];
                    $this->{ls} = LONG;
                }
            }

            $this->{sar} = $sar + $alpha * ($ep - $sar);
            $this->{lh}  = [ $low, $high ];

            $alpha += $as;
            $alpha = $am if $alpha > $am;
            $this->{a} = $alpha;

        } elsif( defined( my $lh = $this->{lh} ) ) {
            my $alpha = $as;
            my ($ep, $sar);

            if( $close > $lh->[2] ) {
                # "If the market has recently moved lower and is now above the
                # lows of that move, assume a long. Call the lowest point of the
                # previous trade the SAR initial point (SIP) because it will be
                # the starting point for the SAR calculation (SARI = SIP)."
                # -- pricemotion.com

                # really, we're assuming long if our close is greater than
                # yesterday's close

                $this->{ep}  = $ep = ($high > $lh->[1] ? $high : $lh->[1]);

                $sar = $lh->[0] + $alpha * ($ep - $lh->[0]);

                # * "If tomorrow's SAR value lies within (or beyond) today's or
                #    yesterday's price range, the SAR must be set to the
                #    closest price bound. For example, if in an uptrend, the
                #    new SAR value is calculated and it results to be greater
                #    than today's or yesterday's lowest price, the SAR must be
                #    set equal to that lower boundary.
                # * "If tomorrow's SAR value lies within (or beyond) tomorrow's
                #   price range, a new trend direction is then signaled, and
                #   the SAR must 'switch sides.'"
                # --wikipedia

                if( $sar > $low ) {
                    $sar = $low;
                    $this->{ls} = SHORT;

                } elsif( $sar > $lh->[0] ) {
                    $sar = $lh->[0];
                    $this->{ls} = SHORT;

                } else {
                    $this->{ls} = LONG;
                }

            } else {
                $this->{ep}  = $ep = ($low < $lh->[0] ? $low : $lh->[0]);

                $sar = $lh->[1] + $alpha * ($ep - $lh->[1]);

                if( $sar < $high ) {
                    $sar = $high;
                    $this->{ls} = LONG;

                } elsif( $sar < $lh->[1] ) {
                    $sar = $lh->[1];
                    $this->{ls} = LONG;

                } else {
                    $this->{ls} = SHORT;
                }
            }

            $this->{lh}  = [ $low, $high ];
            $this->{sar} = $sar;

            $alpha += $as;
            $alpha = $am if $alpha > $am;
            $this->{a} = $alpha;

        } else {
            $this->{lh} = $ar;
        }
    }
}

sub start_with {
    my $this = shift;

    die "todo";
}

sub query {
    my $this = shift;

    die "todo";
}

__END__

=head1 NAME

Math::Business::ParabolicSAR - Technical Analysis: Stop and Reversal (aka SAR)

=head1 SYNOPSIS

  use Math::Business::DMI;

  my $dmi = new Math::Business::DMI;
     $dmi->set_days(14);

  # alternatively/equivilently
  my $dmi = new Math::Business::DMI(14);

  # or to just get the recommended model ... (14)
  my $dmi = Math::Business::DMI->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one:
  $dmi->insert( @data_points );
  $dmi->insert( $_ ) for @data_points;

  my $adx = $dmi->query;     # ADX
  my $pdi = $dmi->query_pdi; # +DI
  my $mdi = $dmi->query_mdi; # -DI

  # or
  my ($pdi, $mdi, $adx) = $dmi->query;

  if( defined $adx ) {
      print "ADX: $adi.\n";

  } else {
      print "ADX: n/a.\n";
  }

  # you may use this to kick start
  $dmi->start_with($aPDM, $aMDM, $adx;

  # aPDM and aMDM are internals, to fetch them, use these
  my $aPDM = $dmi->query_apdm;
  my $aMDM = $dmi->query_amdm;

=head1 RESEARCHER

The ADX/DMI was designed by J. Welles Wilder Jr circa 1978.

The +DI and -DI signals measure the force of directional changes.  When the
+DI crosses above the -DI it may indicate that it's time to buy and when
the -DI crosses above the +DI it may be time to sell.

The ADX tries to combine the two.  It may indicate the strength of the
current trend (but not it's direction).  When it moves above 20 it may be
the beginning of a trend and when it falls below 40, it may be the end of
it.

The DMI uses the ATR to try to measure volatility.

NOTE: The +DI, -DI and ADX returned by this module are probabilities ranging
from 0 to 1.  Most sources seem to show the DMI values as numbers from 0 to
100.  Simply multiply the three touple by 100 to get this result.

    my @DMI = map { 100*$_ } = $dmi->query;

=head1 AUTHOR

Paul Miller <jettero@cpan.org>

I am using this software in my own projects...  If you find bugs, please please
please let me know.

I normally hang out on #perl on freenode, so you can try to get immediate
gratification there if you like.  L<irc://irc.freenode.net/perl>

=head1 COPYRIGHT

Copyright (c) 2008 Paul Miller -- LGPL [Software::License::LGPL_2_1]

    perl -MSoftware::License::LGPL_2_1 \
         -e '$l = Software::License::LGPL_2_1->new({
             holder=>"Paul Miller"});
             print $l->fulltext' | less

=head1 SEE ALSO

perl(1)

L<http://en.wikipedia.org/wiki/Parabolic_SAR>

L<http://www.pricemotion.com/Forex-and-Stock-Market-Educational-Trading-Games--Parabolic-SAR.htm>

=cut
