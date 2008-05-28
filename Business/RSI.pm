package Math::Business::RSI;

use strict;
use warnings;
use Math::Business::SMA;
use Math::Business::EMA;

use version; our $VERSION = qv("1.00");

use Carp;

1;

sub new { 
    my $class = shift;
    my $this  = bless {
        val => [],
        U   => Math::Business::EMA->new,
        D   => Math::Business::EMA->new,
        RSI => undef,
    }, $class;

    return $this;
}

sub set_standard {
    my $this = shift;
    my $rm   = ref $this->{U};

    if( $rm =~ m/SMA/ ) {
        $this->{U} = Math::Business::EMA->new;
        $this->{D} = Math::Business::EMA->new;

        if( my $d = $this->{days} ) {
            $this->set_days($d);
        }
    }
}

sub set_cutler {
    my $this = shift;
    my $rm   = ref $this->{U};

    if( $rm =~ m/EMA/ ) {
        $this->{U} = Math::Business::SMA->new;
        $this->{D} = Math::Business::SMA->new;

        if( my $d = $this->{days} ) {
            $this->set_days($d);
        }
    }
}

sub set_days { 
    my $this = shift; 
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{U}->set_days($this->{days} = $arg);
    $this->{D}->set_days($arg);
    delete $this->{cy};
    delete $this->{RSI};
}

sub insert {
    my $this = shift;
    my $close_yesterday = $this->{cy};

    my $EMA_U = $this->{U};
    my $EMA_D = $this->{D};

    croak "You must set the number of days before you try to insert" if not $this->{days};
    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            my $delta = $close_today - $close_yesterday;

            my ($U,$D) = (0,0);
            if( $delta > 0 ) {
                $U = $delta;
                $D = 0;

            } elsif( $delta < 0 ) {
                $U = 0;
                $D = abs $delta;
            }

            $EMA_U->insert($U);
            $EMA_D->insert($D);
        }

        if( defined(my $eu = $EMA_U->query) ) {
            my $ed = $EMA_D->query;
            my $rs = (($ed == 0) ? 100 : $eu/$ed ); # NOTE: This is by definition apparently.

            $this->{RSI} = 100 - 100/(1+$rs);
        }

        $close_yesterday = $close_today;
    }

    $this->{cy} = $close_yesterday;
}

sub start_with {
    my $this = shift;

    die "unfinished"
}

sub query {
    my $this = shift;

    return $this->{RSI};
}

__END__

=head1 NAME

Math::Business::RSI - Technical Analysis: Relative Strength Index

=head1 SYNOPSIS

  use Math::Business::RSI;

  my $rsi = new Math::Business::RSI;

  set_days $rsi 7;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  foreach(@closing_values) {
      $sma->insert( $_ );
      if( defined(my $q = $sma->query) ) {
          print "SMA value: $q.\n";
      } else {
          print "SMA value: n/a.\n";

          # note that a simple moving average is undefined before 
          # there's enough days to calculate it.
      }
  }

  # you may use this to kick start 
  $sma->start_with( [@array_of_days_most_recent_on_right] );

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

L<http://en.wikipedia.org/wiki/Relative_Strength_Index>

=cut
