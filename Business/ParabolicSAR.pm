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
    my $this  = bless {
        sp  => undef,
        ep  => undef,
        sar => undef,
        ls  => 
    }, $class;

    return $this;
}

sub insert {
    my $this = shift;

    my $y_point = $this->{y};
    while( defined( my $point = shift ) ) {
        croak "insert takes three touples (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
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
