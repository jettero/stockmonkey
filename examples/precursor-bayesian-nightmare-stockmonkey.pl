#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(freeze thaw);
use Math::Business::RSI;
use Math::Business::LaguerreFilter;
use Data::Dump qw(dump);
use GD::Graph::lines;
use GD::Graph::Hooks;
use List::Util qw(min max);
use MySQL::Easy;

my $dbo    = MySQL::Easy->new("scratch"); # reads .my.cnf for password and host
my $ticker = shift || "SCTY";
my $phist  = shift || 150; # final plot history items
my $lagf   = shift || 4;   # speed of fast laguerre filter
my $lags   = shift || 8;   # speed of slow laguerre filter
my $slurpp = "10 years"; # data we want to fetch

find_quotes_for($ticker=>$slurpp);

# {{{ sub find_quotes_for
sub find_quotes_for {
    our $lf   ||= Math::Business::LaguerreFilter->new(2/(1+$lagf));
    our $ls   ||= Math::Business::LaguerreFilter->new(2/(1+$lags));
    our $bb   ||= Math::Business::BollingerBands->recommended;
    our $crsi ||= Math::Business::ConnorRSI->recommended;
    our $rsi  ||= Math::Business::RSI->recommended;

    my $tick = uc(shift || "SCTY");
    my $time = lc(shift || "6 months");
    my $fnam = "/tmp/p3-$tick-$time-$lagf-$lags-bb-crsi.dat";

    my $res = eval { retrieve($fnam) };
    return $res if $res;

    $dbo->do("create table if not exists stockplop(
        rowid    unsigned int not null auto_increment primary key,

        ticker   char(5) not null,
        interval unsigned int not null default 86400,
        qtime    datetime not null,
        open     unsigned decimal(4,2) not null,
        high     unsigned decimal(4,2) not null,
        low      unsigned decimal(4,2) not null,
        close    unsigned decimal(4,2) not null,
        volume   unsigned int not null,

        unique(ticker,interval,qtime)
    )");

    $dbo->do("create table if not exists stockplop_attrs(
        rowid unsigned int not null,
        tag varchar(30) not null,

        val0 decimal(6,2) not null,
        val1 decimal(6,2), -- some attrs need more space
        val2 decimal(6,2),
        val3 decimal(6,2),

        primary key(rowid,tag)
    )");

    $dbo->do("create table if not exists stockplop_glaciers(
        last_qtime date not null,
        interval unsigned int not null default 86400,
        tag varchar(30) not null,

        glacier blob,

        primary key(last_qtime,interval,tag)
    )");

    # NOTE: later, this logic will have to be tweaked for intervals smaller than 86400

    if( my @fv = $dbo->firstrow("select max(qtime), iifmax(qtime)=now() from stockplop where interval=86400 and ticker=?", $tick) ) {

        return if $fv[1]; # nothing to fetch

        $time = $fv[0];

    } else {
        $time = "$time ago";
    }

    my $q = Finance::QuoteHist->new(
        symbols    => [$tick],
        start_date => $time;
        end_date   => 'today',
    );

    if( $time !~ m/ ago/ ) {
        # we can resurrect the indexes
        my $sth = $dbo->ready("select glacier from stockplop_glaciers where last_qtime=? and interval=86400 and tag=?");
           $sth->bind_columns(\my $glacier);

        for( $rsi, $lf, $ls, $crsi, $bb ) {
            $sth->execute($_->tag);
            $_ = thaw($glacier) if $sth->fetch;
        }
    }

    my $ins = $dbo->ready("insert into stockplop 
        set ticker=?, interval=86400, qtime=?, open=?, high=?, low=?, close=?, volume=?
        on duplicate key update");

    my $ains = $dbo->ready("insert into stockplop_attrs set rowid=?, interval=86400, tag=?,
        val0=?, val1=?, val2=?, val3=?
        on duplicate key update");

    my $last_qtime;
    my @todump;
    for my $row ($q->quotes) {
        my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

        next unless $date = ParseDate("$date 4:30pm");
        $date = UnixDate($date, '%Y-%m-%d %H:%M:%S');

        $ins->execute($symbol, $date, $open, $high, $low, $close, $volume);
        my $rowid = $ins->last_insert_id;

        for( $rsi, $lf, $ls, $crsi, $bb ) {
            $_->insert($close);
            $ains->execute($rowid, $_->tag, $_->query);
        }

        $last_qtime = $date;
    }

    if( $last_qtime ) {
        my $freezer = $dbo->ready("replace into stockplop_glaciers set last_qtime=?, interval=86400, tag=?, glacier=?");

        for( $rsi, $lf, $ls, $crsi, $bb ) {
            $freezer->execute($_->tag, $_->query, freeze($_));
        }
    }
}

# }}}
