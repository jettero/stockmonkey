package Math::Business::Stochastic;

use strict;
use warnings;
use Carp;

use Math::Business::SMA;
use Math::Business::EMA;

1;

use constant METHOD_LANE => 0;
use constant METHOD_FAST => 1;
use constant METHOD_SLOW => 2;
use constant METHOD_FULL => 3;

sub recommended { my $class = shift; return $class->new(5,3,METHOD_LANE); }

sub new {
    my $class = shift;
    my $kp    = shift || 5;
    my $dp    = shift || 3;
    my $meth  = shift || METHOD_LANE;

    my $this  = bless {}, $class;

    $this->set_days( $kp );
    $this->set_dperiod( $dp );
    $this->set_method( $meth );

    return $this;
}

sub set_days { 
    my $this = shift;
    my $arg = shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{kp} = $arg;
}

sub set_dperiod { 
    my $this = shift;
    my $arg = shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{dp} = $arg;
}

sub set_method {
    my $this = shift;
    my $meth = shift;

    croak "method not known" unless grep {$meth == $_} (METHOD_LANE, METHOD_FAST, METHOD_SLOW, METHOD_FULL);

    $this->{m} = $meth;
}

{
    my $method = {
        METHOD_LANE() => \&insert_lane,
        METHOD_FAST() => \&insert_fast,
        METHOD_SLOW() => \&insert_slow,
        METHOD_FULL() => \&insert_full,
    };

    sub insert {
        my $this = shift;

        return $this->$method( @_ );
    }
}

sub insert_lane {
    my $this = shift;

    my $l = ($this->{low_hist}  ||= []);
    my $h = ($this->{high_hist} ||= []);
    my $kp = $this->{kp};
    my $dp = $this->{dp};

    my ($K, $D);
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        push @$l, $t_low;  shift @$l while @$l > $kp;
        push @$h, $t_high; shift @$h while @$h > $kp;

        if( @$l == $kp ) {
            my $L = $l->[0]; for( 1 .. $#$l ) { $L = $l->[$_] if $l->[$_] < $L };
            my $H = $h->[0]; for( 1 .. $#$h ) { $H = $h->[$_] if $h->[$_] > $H };

            $K = 100 * ($t_close - $L)/($H-$L);

            my $L = $l->[-$dp]; for( (-$dp+1) .. -1 ) { $L = $l->[$_] if $l->[$_] < $L };
            my $H = $h->[-$dp]; for( (-$dp+1) .. -1 ) { $H = $h->[$_] if $h->[$_] > $H };

            $D = 100 * $H / $L;
        }
    }

    $this->{K} = $K;
    $this->{D} = $D;

    return;
}

sub query {
    my $this = shift;

    return ($this->{K}, $this->{D});
}

__END__

=head1 NAME

Math::Business::Stochastic - Technical Analysis: Stochastic Oscillator

=head1 SYNOPSIS

  use Math::Business::Stochastic;

  my $sto = new Math::Business::Stochastic;
     $sto->set_days(5);     # Lane uses 5 in his examples (if any)
     $sto->set_dperiod(30); # Lane
     $sto->set_method( Math::Business::Stochastic::METHOD_LANE );


  # Lane's version
  my $sto = Math::Business::Stochastic->recommended;


  # Probably more like what you expect (ie, matches up with
  # Yahoo/Google/Ameritrade, etc)

  my $sto_slow = Math::Business::Stochastic->modern_slow;
  my $sto_fast = Math::Business::Stochastic->modern_fast;
  my $sto_full = Math::Business::Stochastic->modern_full;


  # basic usage

  $sto->insert($close);
  my ($K, $D) = $sto->query;
  print "current stochastic: %K=$K and %D=$D\n";

=head1 RESEARCHER

The Stochastic was designed by R. George C. Lane.

It is difficult to find a good reference on this indicator.  Almost every
source disagrees with the next and some sources even disagree internally
(I'm looking at you Wikipedia).

The stochastic (among other things) purports to indicate an "overbought"
situation where the C<%K> is above 80 and "oversold" when below 20.

There are "divergences" and "convergences" to look for too, however.  If
there is a higher high or a lower low in the C<%K>, this can apperntly
indicate trend changes.  This concept is not easy to pin down explicitly,
and so is not described here.

=head1 FUTHER BACKGROUND ON COMPUTATION

The basic idea is that C<%K> should be a momentum indicator and C<%D>
should be a smoothed version of C<%K>.  Most sources generally agree that
C<%K(5)> should be computed as follows:

  $K = 100 * (close - min(@last_5_low))/(max(@last_5_high)-min(@last_5_low))

C<%D> is more sticky and various sources give various answers.   Lane
himself seemed to use:

  $D = 100 * max(@last_3_high)/min(@last_3_low)

But most charting sites and the Wikipedia seem to choose an SMA or EMA for
smothing on C<%D> and thus produce something like:

  $SMA->set_days(3);
  $SMA->insert($K);
  $D = $SMA->query;

The main problem getting this right is that Lane himself hasn't really
spelled it out in publication.  "Do this, then this, then that."  The
reason seems to be the lecture circuit.  He teaches this stuff in classes
and seminars (or tought) and hasn't really published it in the traditional
sense.

To a certain extent, we therefore feel free to pick whatever we want for
the defaults.

=head1 THANKS

Robby Oliver C<< <robbykaty@gmail.com> >>

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  There is a mailing list with very light traffic that you
might want to join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright © 2013 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.

=head1 SEE ALSO

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://en.wikipedia.org/wiki/Stochastic_oscillator>

=cut
