package Math::Business::ADX;

use strict;
use warnings;
use Math::Business::ATR;

use version; our $VERSION = qv("1.0");
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
    my $point = shift; croak "insert takes three touples (high, low, close)" unless ref $point eq "ARRAY" and @$point = 3;
    my ($t_high, $t_low, $t_close) = @$point;

    $this->{ATR}->insert($point);

    return unless my $y_point = $this->{y};

    my ($y_high, $y_low, $y_close) = @$y_point;

    my ($PDM, $MDM); ##-------------------------------------------
    my $A = $t_high - $y_high;
    my $B = $y_low  - $t_low;

    if( $A < 0 and $B < 0 ) {
        $MDM = $PDM = 0;

    } elsif( $A > $B ) {
        $PDM = $A;
        $MDM = 0;

    } elsif( $B < $A ) {
        $PDM = 0;
        $MDM = $B;

    } else {
        die "hrm, unexpected if-block failure";
    }

    if( defined(my $pdi = $this->{PDI}) ) {
        my $mdi = $this->{MDI};

        $this->{PDI} = $this->{R} * $pdi + $this->{R1} * $PDM;
        $this->{MDI} = $this->{R} * $mdi + $this->{R1} * $MDM;

    } else {
        my $p;
        my $N = $this->{days};
        if( ref($p = $this->{_p}) and (@$p >= $N-1) ) {
            my $psum = 0;
               $psum += $_ for @$p;
               $psum += $PDM;

            $this->{PDI} = $psum / $N;

            my $m = $this->{_m};
            my $msum = 0;
               $msum += $_ for @$m;
               $msum += $MDM;

            $this->{MDI} = $msum / $N;

        } else {
            push @{$this->{_p}}, $PDM;
            push @{$this->{_m}}, $MDM;
        }
    }
}

sub start_with {
    my $this = shift;

    die; # TODO
}

sub query_pdi {
    my $this = shift;

    return $this->{PDi};
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

Math::Business::ADX - Technical Analysis: Directional Movement Index

=head1 SYNOPSIS

  use Math::Business::ADX;

  my $adx = new Math::Business::ADX;
     $adx->set_days(14);

  # alternatively/equivilently
  my $adx = new Math::Business::ADX(14);

  # or to just get the recommended model ... (14)
  my $adx = Math::Business::ADX->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one: 
  $adx->insert( @data_points );
  $adx->insert( $_ ) for @data_points;

  my $adi = $adx->query;     # the composite
  my $pdi = $adx->query_pdi; # the DI+
  my $mdi = $adx->query_mdi; # the DI-

  # or
  my ($pdi, $mdi, $adx) = $adx->query;

  if( defined $adi ) {
      print "ADX: $adi.\n";

  } else {
      print "ADX: n/a.\n";
  }

  # you may use this to kick start 
  $adx->start_with( blah blah blah ); # TODO

=head1 RESEARCHER

The ADX was designed by J. Welles Wilder Jr circa 1978.

=head1 Thanks

Todd Litteken PhD <cl@xganon.com> 

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
