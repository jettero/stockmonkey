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
    $this->set_pdays(shift || 100);

    return $this;
}

sub reset {
    my $this = shift;

    delete $this->{cy};
    delete $this->{st};

    $this->{cRSI} = Math::Business::RSI->new($this->{cdays}) if exists $this->{cRSI};
    $this->{sRSI} = Math::Business::RSI->new($this->{sdays}) if exists $this->{sRSI};
    $this->{prank} = [];
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->reset;
}

sub set_sdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->reset;
}

sub set_pdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{pdays} = $arg;
    $this->reset;
}

sub insert {
    my $this = shift;
    my $close_yesterday = $this->{cy};
    my $streak          = $this->{st};

    my $sRSI = $this->{sRSI};
    my $cRSI = $this->{cRSI};
    my $prnk = $this->{prnk};

    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            my $d = $close_today > $close_yesterday ? 1 : $close_today < $close_yesterday ? -1 : 0;

            $streak += $d;
        }

        $sRSI->insert($sreak) if defined $streak;
        $cRSI->insert($close_today);

        $close_yesterday = $close_today;
    }

    $this->{cy} = $close_yesterday;
    $this->{st} = $streak;
}

sub query {
    my $this = shift;

    return $this->{connor};
}
