package Math::Business::ConnorRSI;

use strict;
use warnings;
use Carp;

use Math::Business::RSI;

sub recommended { (shift)->new() }

sub new {
    my $class = shift;
    my $this = bless {}, $class;

    $this->set_cdays(shift ||   3);
    $this->set_sdays(shift ||   2);
    $this->set_pdays(shift || 100);

    $this->{cRSI} = Math::Business::RSI->new($this->{cdays});
    $this->{sRSI} = Math::Business::RSI->new($this->{sdays});

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

sub set_cdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{cdays} = $arg;

    $this->reset;
}

sub set_sdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{sdays} = $arg;

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
    my $streak          = $this->{st} || 0;

    my $sRSI  = $this->{sRSI};
    my $cRSI  = $this->{cRSI};
    my $prnk  = $this->{prank};
    my $pdays = $this->{pdays};

    # we store 1 extra so we can compare $pdays values
    my $pdaysp1 = $pdays + 1;

    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            if( $close_yesterday < $close_today ) {
                $streak = $streak >= 0 ? -1 : $streak-1;

            } elsif( $close_yesterday > $close_today ) {
                $streak = $streak <= 0 ? 1 : $streak+1;

            } else {
                $streak = 0;
            }

            push @$prnk, ($close_today - $close_yesterday)/$close_yesterday;
            shift @$prnk while @$prnk > $pdaysp1;
        }

        $sRSI->insert($streak) if defined $streak;
        $cRSI->insert($close_today);

        $close_yesterday = $close_today;
    }

    my $srsi = $sRSI->query;
    my $crsi = $cRSI->query;

    if( defined $srsi and defined $crsi and @$prnk==$pdaysp1 ) {
        my $v = $prnk->[-1];
        my $p = 0;
        my $i = $#$prnk;

        # we skip the first one, cuz that's $v
        while( (--$i) >= 0 ) {
            $p ++ if $prnk->[$i] < $v;
        }

        my $PR = 100 * ($p/$pdays);

        $this->{connor} = ( $srsi + $crsi + $PR ) / 3;
    }

    $this->{cy} = $close_yesterday;
    $this->{st} = $streak;
}

sub query {
    my $this = shift;

    return $this->{connor};
}

1;
