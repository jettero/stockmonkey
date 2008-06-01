package Math::Business::MACD;

use strict;
use warnings;

use version; our $VERSION = qv('2.1');

use Carp;
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

sub query {
    my $this = shift;

    my $f = $this->query_fast_ema;
    my $s = $this->query_slow_ema;

    return undef unless defined($f) and defined($s);
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

sub query_histogram { 
    my $this = shift; 

    my $m = $this->query;
    my $t = $this->query_trig_ema;

    return undef unless $m and $t;

    return $m - $t;
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

  print "       MACD: ", $macd->query,          "\n",
        "Trigger EMA: ", $macd->query_trig_ema, "\n",
        "   Fast EMA: ", $macd->query_fast_ema, "\n",
        "   Slow EMA: ", $macd->query_slow_ema, "\n";

To avoid recalculating huge lists when you add a few new values on the end:

  $ema->start_with( 
      $last_slow_ema,
      $last_fast_ema,
      $last_trig_ema,
  );

=head1 RESEARCHER

The MACD was designed by Gerald Appel in the 1960s.

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
