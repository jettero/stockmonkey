package Math::Business::MACD;

use strict;
use warnings;

use version; our $VERSION = qv('1.10');

use Carp;
use Math::Business::EMA;

1;

sub new { 
    my $this = shift;

    $this = bless {
        slow_EMA => new Math::Business::EMA,
        fast_EMA => new Math::Business::EMA,
        trig_EMA => new Math::Business::EMA,
        days     => 0,
    }, $this;

    return $this;
}

sub start_with {
    my $this = shift;
    my ($slow, $fast, $trig) = @_;

    croak "undefined slow ema" unless defined $slow;
    croak "undefined fast ema" unless defined $fast;
    croak "undefined trig ema" unless defined $trig;

    $this->{slow_EMA}->start_with($slow);
    $this->{fast_EMA}->start_with($fast);
    $this->{trig_EMA}->start_with($trig);
}

sub set_days {
    my $this = shift;
    my ($slow, $fast, $trig) = @_;

    croak "slow days must be a positive non-zero integers" if $slow <= 0;
    croak "fast days must be a positive non-zero integers" if $fast <= 0;
    croak "trig days must be a positive non-zero integers" if $trig <= 0;

    $this->{days} = 1;

    $this->{slow_EMA}->set_days($slow);
    $this->{fast_EMA}->set_days($fast);
    $this->{trig_EMA}->set_days($trig);
}

sub query_trig_ema { my $this = shift; return $this->{trig_EMA}->query }
sub query_slow_ema { my $this = shift; return $this->{slow_EMA}->query }
sub query_fast_ema { my $this = shift; return $this->{fast_EMA}->query }

sub query {
    my $this = shift;

    my $f = $this->query_fast_ema;
    my $s = $this->query_slow_ema;

    return undef unless defined($f) and defined($s);

    return $f - $s;
}

sub insert {
    my $this  = shift;
    my $value = shift;;

    croak "You must set the number of days before you try to insert" if not $this->{days};

    $this->{slow_EMA}->insert($value);
    $this->{fast_EMA}->insert($value);

    my $m = $this->query;

    $this->{trig_EMA}->insert( $m ) if defined($m);
}

sub query_histogram { 
    my $this = shift; 

    my $m = $this->query;
    my $t = $this->query_trig_ema;

    return undef unless $m and $t;

    return $m - $t;
}

__END__

=head1 NAME

Math::Business::MACD - Perl extension for calculating MACDs

=head1 SYNOPSIS

  use Math::Business::MACD;

  my $macd = new Math::Business::MACD;

  my ($slow, $fast, $trigger) = (26, 12, 9);

  set_days $macd $slow, $fast, $trigger;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  # This is probably a bad example.  It will produce quite a few
  # warnings with the -w switch.  Note that the return will be
  # undefined until there are enough values in the ema!
  foreach(@closing_values) {
      $macd->insert( $_ );
      print "       MACD: ", $macd->query,          "\n",
            "Trigger EMA: ", $macd->query_trig_ema, "\n",
            "   Fast EMA: ", $macd->query_fast_ema, "\n",
            "   Slow EMA: ", $macd->query_slow_ema, "\n";
  }

  # to avoid recalculating huge lists when 
  # you add a few new values on the end

  $ema->start_with( 
      $last_slow_ema,
      $last_fast_ema,
      $last_trig_ema,
  );

  # then continue with a foreach over the newly
  # inserted values

  # unfortunately this means you'd have had to
  # store the last slow, fast, and trigger ema's.
  # somewhere

=head1 EMA/SMA Note

    As of SMA 0.99, EMA 1.06, MACD 1.10, the MACD will now return 
    'undef' where there is not yet enough data to calculate the EMAs.
    Further, the trigger and histogram values will not be available until
    the trigger EMA has enough data.

    This is going to be a compat buster for some of my graphs, but it has
    to be done for correctness.  :(

=head1 AUTHOR

Jettero Heller <jettero@cpan.org>

http://www.voltar.org

=head1 Thanks

David Perry <David.Perry@ca.com>

=head1 Special Thanks

http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_MACD1.html

=head1 SEE ALSO

perl(1), Math::Business::EMA(3).

=head1 Go Read this Page:

http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_MACD1.html

=cut
