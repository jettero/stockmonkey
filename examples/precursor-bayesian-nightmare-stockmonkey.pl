#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(freeze thaw);
use Math::Business::RSI;
use Math::Business::LaguerreFilter;
use Math::Business::BollingerBands;
use Math::Business::ConnorRSI;
use Data::Dump qw(dump);
use GD::Graph::lines;
use GD::Graph::Hooks;
use List::Util qw(min max);
use MySQL::Easy;
use Date::Manip;

my $dbo    = MySQL::Easy->new("scratch"); # reads .my.cnf for password and host
my $ticker = shift || "SCTY";
my $phist  = shift || 150; # final plot history items
my $slurpp = "10 years"; # data we want to fetch

if( $ticker eq "newk" ) {
    $dbo->do("drop table if exists stockplop");
    $dbo->do("drop table if exists stockplop_glaciers");
    exit 0;
}

find_quotes_for($ticker=>$slurpp);

# {{{ sub find_quotes_for
sub find_quotes_for {
    our $lf   ||= Math::Business::LaguerreFilter->new(2/(1+4));
    our $ls   ||= Math::Business::LaguerreFilter->new(2/(1+8));
    our $bb   ||= Math::Business::BollingerBands->recommended;
    our $crsi ||= Math::Business::ConnorRSI->recommended;
    our $rsi  ||= Math::Business::RSI->recommended;

    # NOTE: if you add to indicies, you probably need to 'newk'
    my @indicies = ($lf, $ls, $crsi, $rsi, $bb);

    my $tick = uc(shift || "SCTY");
    my $time = lc(shift || "6 months");

    # {{{ SCHEMA:
    SCHEMA: {
        my @moar_columns;
        for( @indicies ) {
            my $tag  = $_->tag;
            my @ret  = $_->query;
            my $type = @ret == 1 ? "decimal(6,4)" : "varchar(50)";

            push @moar_columns, "`$tag` $type,";
        }

        $dbo->do("create table if not exists stockplop(
            rowid    int unsigned not null auto_increment primary key,

            ticker  char(5) not null,
            qtime   datetime not null,
            open    decimal(6,2) unsigned not null,
            high    decimal(6,2) unsigned not null,
            low     decimal(6,2) unsigned not null,
            close   decimal(6,2) unsigned not null,
            volume  int unsigned not null,

            @moar_columns

            unique(ticker,qtime)
        )");

        $dbo->do("create table if not exists stockplop_glaciers(
            ticker  char(5) not null,
            last_qtime date not null,
            tag varchar(30) not null,

            glacier blob,

            primary key(ticker,last_qtime,tag)
        )");
    }

    # }}}

    if( my @fv = grep {defined} $dbo->firstrow("select max(qtime), max(qtime)=now() from stockplop where ticker=?", $tick) ) {
        return if $fv[1]; # nothing to fetch

        $time = $fv[0];

    } else {
        $time = "$time ago";
    }

    die "fatal start_date parse error" unless $time;

    my $q = Finance::QuoteHist->new(
        symbols    => [$tick],
        start_date => $time,
        end_date   => 'today',
    );

    if( $time !~ m/ ago/ ) {
        # we can resurrect the indexes
        my $sth = $dbo->ready("select glacier from stockplop_glaciers where last_qtime=? and tag=?");

        for( $rsi, $lf, $ls, $crsi, $bb ) {
            $sth->execute($time, $_->tag);
            $sth->bind_columns(\my $glacier);
            $_ = thaw($glacier) if $sth->fetch;
        }
    }

    my $ins;
    PREPARE: {
        my @columns = ("ticker=?, qtime=?, open=?, high=?, low=?, close=?, volume=?");
        for(@indicies) {
            my $t = $_->tag;
            push @columns, "`$t`=?";
        }

        $ins = $dbo->ready("insert ignore into stockplop set " . join(", ", @columns));
    }

    my $last_qtime;
    my @todump;
    for my $row ($q->quotes) {
        my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

        next unless $date = ParseDate("$date 4:30pm");
        $date = UnixDate($date, '%Y-%m-%d %H:%M:%S');

        my @data = ($symbol, $date, $open, $high, $low, $close, $volume);
        for(@indicies) {
            $_->insert($close);

            my @r = $_->query;
            my $r = @r>1 ? join("/", map {defined()?sprintf('%0.4f', $_):'-'} @r) : $r[0];

            push @data, $r;
        }

        $ins->execute(@data);

        $last_qtime = $date;
    }

    if( $last_qtime ) {
        my $freezer = $dbo->ready("replace into stockplop_glaciers set ticker=?, last_qtime=?, tag=?, glacier=?");

        for( $rsi, $lf, $ls, $crsi, $bb ) {
            $freezer->execute($ticker, $last_qtime, $_->tag, freeze($_));
        }
    }
}

# }}}
