package Math::Business::DMI;

use strict;
use warnings;
use Math::Business::ATR;

use version; our $VERSION = qv("1.1");
use Carp;

1;

sub recommended {
    my $class = shift;

    $class->new(14);
}

sub new { 
    my $class = shift;
    my $this  = bless {
        ATR => new Math::Business::ATR,
    }, $class;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days { 
    my $this = shift; 
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{ATR}->set_days($arg);
    $this->{days} = $arg;
    $this->{R}  = ($arg-1)/$arg;
    $this->{R1} = 1/$arg;
}

sub insert {
    my $this = shift;

    my $y_point = $this->{y};
    while( defined( my $point = shift ) ) {
        croak "insert takes three touples (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        if( defined $y_point ) {
            my $atr = $this->{ATR};
               $atr->insert($point);

            my ($y_high, $y_low, $y_close) = @$y_point;

            my ($PDM, $MDM) = (0,0);
            my $A = $t_high - $y_high;
            my $B = $y_low  - $t_low;

            if( $A > 0 and $A > $B ) {
                $PDM = $A;
                $MDM = 0;

            } elsif( $B > 0 and $B > $A ) {
                $PDM = 0;
                $MDM = $B;
            }

            if( defined(my $pdm = $this->{aPDM}) ) {
                my $mdm = $this->{aMDM};

                my $R  = $this->{R};
                my $R1 = $this->{R1};

                my $aPDM = $this->{aPDM} = $R * $pdm + $R1 * $PDM;
                my $aMDM = $this->{aMDM} = $R * $mdm + $R1 * $MDM;

                my $ATR = $atr->query || 0.000_000_000_6; # NOTE: a rather weak way to solve divide by zero

                my $PDI = $this->{PDI} = $aPDM / $ATR;
                my $MDI = $this->{MDI} = $aMDM / $ATR;

                my $DI = abs( $PDI - $MDI ) || 0.000_000_000_6;
                my $DX = $DI / ($PDI + $MDI);

                $this->{ADX} = $R * $this->{ADX} + $R1 * $DX;

            } else {
                my $p;
                my $N = $this->{days};
                if( ref($p = $this->{_p}) and (@$p >= $N-1) ) {
                    my $psum = 0;
                       $psum += $_ for @$p;
                       $psum += $PDM;

                    my $m = $this->{_m};
                    my $msum = 0;
                       $msum += $_ for @$m;
                       $msum += $MDM;

                    my $aPDM = $this->{aPDM} = $psum / $N;
                    my $aMDM = $this->{aMDM} = $msum / $N;

                    my $ATR = $atr->query || 0.000_000_000_6; # NOTE: a rather weak way to solve divide by zero

                    my $PDI = $this->{PDI} = $aPDM / $ATR;
                    my $MDI = $this->{MDI} = $aMDM / $ATR;

                    my $DI = abs( $PDI - $MDI ) || 0.000_000_000_6;
                    my $DX = $DI / ($PDI + $MDI);

                    $this->{ADX} = $DX; # is this right?  No idea...  I assume this is well documented in his book

                } else {
                    push @{$this->{_p}}, $PDM;
                    push @{$this->{_m}}, $MDM;
                }
            }
        }

        $y_point = $point;
    }

    $this->{y} = $y_point;
}

sub start_with {
    my $this = shift;

    die; # TODO
}

sub query_pdi {
    my $this = shift;

    return $this->{PDI};
}

sub query_mdi {
    my $this = shift;

    return $this->{MDI};
}

sub query {
    my $this = shift;

    return ($this->{PDI}, $this->{MDI}, $this->{ADX}) if wantarray;
    return $this->{ADX};
}

__END__

=head1 NAME

Math::Business::DMI - Technical Analysis: Directional Movement Index (aka ADX)

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
  $dmi->start_with( blah blah blah ); # TODO

=head1 RESEARCHER

The ADX/DMI was designed by J. Welles Wilder Jr circa 1978.

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

L<http://fxtrade.oanda.com/learn/graphs/indicators/adx.shtml>

=cut
