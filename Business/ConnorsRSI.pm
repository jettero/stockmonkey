package Math::Business::RSI;

use strict;
use warnings;
use Carp;

use Math::Business::RSI;

sub new {
    my $class = shift;
    my $this = bless {}, $class;

    $this->set_days(shift  ||   3);
    $this->set_sdays(shift ||   2);
    $this->set_prank(shift || 100);

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    delete $this->{cy};
    delete $this->{st};

    $this->{cRSI} = Math::Business::RSI->new($arg);
}

sub set_sdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    delete $this->{cy};
    delete $this->{st};

    $this->{sRSI} = Math::Business::RSI->new($arg);
}

sub insert {
    my $this = shift;
    my $close_yesterday = $this->{cy};
    my $streak          = $this->{st};

    my $sRSI = $this->{sRSI};
    my $cRSI = $this->{cRSI};

    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            my $d = $close_today > $close_yesterday ? 1 : $close_today < $close_yesterday ? -1 : 0;

            $streak += $d;
        }

        if( defined $streak ) {
            $this->{streak}->
        }

        $close_yesterday = $close_today;
    }

    $this->{cy} = $close_yesterday;
    $this->{st} = $streak;
}

sub query {
    my $this = shift;

    return $this->{connor};
}
