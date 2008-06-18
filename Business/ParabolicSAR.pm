package Math::Business::ParabolicSAR;

use strict;
use warnings;
use Carp;
use constant {
    LONG  => 7,
    SHORT => 9,
    HP    => 1,
    LP    => 0,
};

our $VERSION = 1.0;

1;

sub recommended {
    my $class = shift;
       $class->new(0.02, 0.20);
}

sub new {
    my $class = shift;
    my $this  = bless {e=>[], y=>[]}, $class;

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

    my ($y_low, $y_high) = @{$this->{y}};
    my ($open,$high,$low,$close);

    my $S;
    my $P = $this->{S};
    my $A = $this->{A};
    my $e = $this->{e};

    my $ls = $this->{ls};

    while( defined( my $ar = shift ) ) {
        croak "arguments to insert must be four touples (open,high,low,close)"
            unless ref($ar) eq "ARRAY" and @$ar==4 and $ar->[2]<$ar->[1];

        # NOTE: we really only use open and close to initialize ...
        ($open,$high,$low,$close) = @$ar;

        if( defined $ls ) {
            # calculate sar_t
            # The Encyclopedia of Technical Market Indicators - Page 495

            my @oe = @$e;
            $e->[HP] = $high if $high > $e->[HP]; # the highest point during the trend
            $e->[LP] = $low  if $low  < $e->[LP]; # the  lowest point during the trend

            if( $ls == LONG ) {
                $S = $P + $A*($e->[HP] - $P); # adjusted upwards from the reset like so

                # NOTE: many sources say you should flop short/long if you get
                # inside the price range for the last *two* periods.  Amazon,
                # Yahoo! and stockcharts dont' seem to do it that way.

                if( $S > $low ) { # or $S > $y_low ) {
                    $ls = SHORT; # new short position

                    $S  = $e->[HP];
                    $A  = $as;

                    $e->[HP] = ($high>$y_high ? $high : $y_high);
                    $e->[LP] = ($low <$y_low  ? $low  : $y_low );

                } elsif( $oe[HP] != $e->[HP] ) {
                    $A += $as;
                    $A = $am if $A > $am;
                }

            } else {
                $S = $P + $A*($e->[LP] - $P); # adjusted downwards from the reset like so

                # NOTE: many sources say you should flop short/long if you get
                # inside the price range for the last *two* periods.  Amazon,
                # Yahoo! and stockcharts dont' seem to do it that way.

                if( $S < $high ) { # or $S < $y_high ) {
                    $ls = LONG; # new long position

                    $S  = $e->[LP];
                    $A  = $as;

                    $e->[HP] = ($high>$y_high ? $high : $y_high);
                    $e->[LP] = ($low <$y_low  ? $low  : $y_low );

                } elsif( $oe[LP] != $e->[LP] ) {
                    $A += $as;
                    $A = $am if $A > $am;
                }
            }

        } else {
            # initialize somehow
            # (never did find a good description of how to initialize this mess,
            #   I think you're supposed to tell it how to start)
            # this is the only time we use open/close and it's not even in the definition

            $A = $as;

            if( $open < $close ) {
                $ls = LONG;
                $S  = $low;

            } else {
                $ls = SHORT;
                $S  = $high;
            }

            $e->[HP] = $high;
            $e->[LP] = $low;
        }

        $P = $S;

        ($y_low, $y_high) = ($low, $high);
    }

    ## DEBUG ## warn "{S}=$S; {A}=$A";

    $this->{S}  = $S;
    $this->{A}  = $A;
    $this->{ls} = $ls;

    @{$this->{y}} = ($y_low, $y_high);
}

sub start_with {
    my $this = shift;

    die "todo";
}

sub query {
    my $this = shift;

    $this->{S};
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

The Encyclopedia of Technical Market Indicators - Page 495

=cut
