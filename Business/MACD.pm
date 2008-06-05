package Math::Business::MACD;

use strict;
use warnings;
use Carp;
use version; our $VERSION = qv("2.0");

use Math::Business::EMA;

1;

sub recommended {
    my $class = shift;

    $class->new(26, 12, 9);
}

sub new { 
    my $class = shift;

    my $this = bless {
        slow_EMA => new Math::Business::EMA,
        fast_EMA => new Math::Business::EMA,
        trig_EMA => new Math::Business::EMA,
        days     => 0,
    }, $class;

    if( @_ == 3 ) {
        $this->set_days(@_);
    }

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

sub query_histogram { 
    my $this = shift; 

    my $m = $this->query;
    my $t = $this->query_trig_ema;

    return unless defined($m) and defined($t);
    return $m - $t;
}

sub query {
    my $this = shift;

    my $f = $this->query_fast_ema;
    my $s = $this->query_slow_ema;

    return unless defined($f) and defined($s);
    if( wantarray ) {
        my $m = $f-$s;
        my $t = $this->query_trig_ema; return unless defined $t;
        my $h = $m-$t;

        return ( $m, $f, $s, $t, $h );
    }
    return $f - $s;
}

sub insert {
    my $this  = shift;

    croak "You must set the number of days before you try to insert" if not $this->{days};

    while( defined( my $value = shift ) ) {
        $this->{slow_EMA}->insert($value);
        $this->{fast_EMA}->insert($value);

        my $m = $this->query;

        $this->{trig_EMA}->insert( $m ) if defined($m);
    }
}

__END__

=head1 NAME

Math::Business::MACD - Technical Analysis: Moving Average Convergence/Divergence

=head1 SYNOPSIS

  use Math::Business::MACD;

  # WARNING: To clear up any confusion, Appel used 12-26-9 rather
  # than the 26,12,9 shown here -- that is, he used
  # fast-slow-trigger instead of slow-fast-trigger as used below.

  my ($slow, $fast, $trigger) = (26, 12, 9);
  my $macd = new Math::Business::MACD;
     $macd->set_days( $slow, $fast, $trigger );

  # alternatively/equivelently
  my $macd = new Math::Business::MACD( $slow, $fast, $trigger );

  # or to just get the recommended model ... (26,12,9)
  my $macd = Math::Business::MACD->recommended;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  # choose one:
  $macd->insert( @closing_vlaues );
  $macd->insert( $_ ) for @closing_values;

  print "       MACD: ", $macd->query,           "\n",
        "Trigger EMA: ", $macd->query_trig_ema,  "\n",
        "   Fast EMA: ", $macd->query_fast_ema,  "\n",
        "   Slow EMA: ", $macd->query_slow_ema,  "\n";
        "  Histogram: ", $macd->query_histogram, "\n";

  my @macd = $macd->query;
  # $macd[0] is the MACD
  # $macd[1] is the Fast
  # $macd[2] is the Slow
  # $macd[3] is the Trigger
  # $macd[4] is the Histogram

To avoid recalculating huge lists when you add a few new values on the end:

  $ema->start_with( 
      $last_slow_ema,
      $last_fast_ema,
      $last_trig_ema,
  );

=head1 RESEARCHER

The MACD was designed by Gerald Appel in the 1960s.

MACD graphs usually show: 

    1. The MACD=ema[fast]-ema[slow] -- query()
    2. The signal=ema[trig]         -- query_trig_ema()
    3. The histogram=MACD-signal    -- query_histogram()

Appel designed the MACD to spot tend changes.

It is believed that when the MACD crosses the signal line on the way up, it
signals a buy condition and when the MACD crosses the signal line on the
way down, it's time to sell.  The histogram can help to visualize when a
crossing is going to occur.

A upward crossing of the MACD through the zero-line indicates a bullish
situation and vice versa.

=head1 Thanks

David Perry <David.Perry@ca.com>

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

L<http://en.wikipedia.org/wiki/MACD>

=cut
