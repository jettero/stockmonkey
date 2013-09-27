package Math::Business::ConnorRSI;

use strict;
use warnings;
use Carp;

use Math::Business::RSI;

sub recommended { (shift)->new() }

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
    my $pdays = $this->{pdays};

    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            my $d = $close_today > $close_yesterday ? 1 : $close_today < $close_yesterday ? -1 : 0;

            $streak += $d;
        }

        $sRSI->insert($streak) if defined $streak;
        $cRSI->insert($close_today);

        push @$prnk, ($close_today - $close_yesterday)/$close_yesterday;
        shift @$prnk while @$prnk > $pdays;

        $close_yesterday = $close_today;
    }

    my $srsi = $sRSI->query;
    my $crsi = $cRSI->query;

    if( defined $srsi and defined $crsi ) {
        my $v = $prnk->[-1];
        my $p = 0;
        my $c = 0;
        my $i = $#$prnk;

        while( (--$i) >= 0 ) {
            $p ++ if $prnk->[$i] < $v;
            $c ++;
        }

        my $PR = $p/$c;

        $this->{connor} = ( $srsi + $crsi + $PR ) / 3;
    }

    $this->{cy} = $close_yesterday;
    $this->{st} = $streak;
}

sub query {
    my $this = shift;

    return $this->{connor};
}
