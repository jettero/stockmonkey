#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(freeze thaw);
use Math::Business::RSI;
use Math::Business::LaguerreFilter;
use Math::Business::BollingerBands;
use Math::Business::ConnorRSI;
use MySQL::Easy;
use Date::Manip;
#se GD::Graph::lines;
#se GD::Graph::Hooks;
#se List::Util qw(min max);

my $dbo    = MySQL::Easy->new("scratch"); # reads .my.cnf for password and host
my $ticker = shift || "SCTY";
my $phist  = shift || 150; # final plot history items
my $slurpp = "10 years"; # data we want to fetch
my @proj   = map {[map {int $_} split m{/}]} @ARGV; # projections

# proj is a list of projections 12/20 5/5, etc that are days in advance, over percent gain/loss
@proj = ([12,20],[5,5]) unless @proj; # dunno why I like 12 days and 20% so much...

if( $ENV{NEWK} ) { $dbo->do("drop table if exists stockplop"); $dbo->do("drop table if exists stockplop_glaciers") }

find_quotes_for($ticker=>$slurpp) unless $ENV{NO_FETCH};
annotate_ticker();

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
            qtime   date not null,
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

    if( my @fv = grep {defined} $dbo->firstrow("select date_add(max(qtime), interval 1 day),
        max(qtime)=now(), max(qtime) from stockplop where ticker=?", $tick) ) {

        if( $fv[1] ) {
            print "no quotes to fetch\n";
            return;
        }

        # fetch time
        $time = $fv[0];

        # we can resurrect the indexes
        my $sth = $dbo->ready("select glacier from stockplop_glaciers where ticker=? and last_qtime=? and tag=?");

        print "found rows ending with $fv[2].  setting start time to $time and trying to thaw glaciers\n";

        for( @indicies ) {
            $sth->execute($ticker, $fv[2], $_->tag);
            $sth->bind_columns(\my $glacier);
            if ( $sth->fetch ) {
                $_ = thaw($glacier);
                my $t = $_->tag;
                my @r = $_->query;
                print "thawed $t from $time: @r\n";
            }
        }

    } else {
        $time = "$time ago";
    }

    die "fatal start_date parse error" unless $time;

    my $q = Finance::QuoteHist->new(
        symbols    => [$tick],
        start_date => $time,
        end_date   => $ENV{END_DATE_FOR_FQ}||"today",
    );

    print "fetched quotes\n";

    my $ins;
    PREPARE: {
        my @columns = ("ticker=?, qtime=?, open=?, high=?, low=?, close=?, volume=?");
        for(@indicies) {
            my $t = $_->tag;
            push @columns, "`$t`=?";
        }

        $ins = $dbo->ready("insert ignore into stockplop set " . join(", ", @columns));
    }

    print "processing rows\n";

    my $last_qtime;
    my @todump;
    for my $row ($q->quotes) {
        my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

        next unless $date = ParseDate($date);
        $date = UnixDate($date, '%Y-%m-%d');

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

        for( @indicies ) {
            my $t = $_->tag;
            print "saving $t as of $last_qtime\n";

            $freezer->execute($ticker, $last_qtime, $t, freeze($_));
        }
    }
}

# }}}
# {{{ sub annotate_ticker
sub annotate_ticker {
    my @projections;

    for( @proj ) {
        next unless $_->[0] > 0 && $_->[1] > 0; # ignore stupid projections

        my $f = "$_->[0]_$_->[1]";
        push @projections, "
            p${f}_price    decimal(6,2) unsigned not null,
            p${f}_qtime    date not null,
            p${f}_strength tinyint unsigned not null,

            m${f}_price    decimal(6,2) unsigned not null,
            m${f}_qtime    date not null,
            m${f}_strength tinyint unsigned not null,
        ";
    }

    SCHEMA: {
        $dbo->do("drop table if exists stockplop_annotations");
        $dbo->do(qq^create table stockplop_annotations(
            rowid int unsigned not null,

            @projections

            description text not null,

            primary key(rowid)
        )^);
    }

    my $limit = int($phist) || 1; # NOTE: can't bind a limit with ?, so sanitize it first!!

    # NOTE: these could maybe be temporary tables instead, but I like to select from them to double check my work
    $dbo->do("drop table if exists t$_->[0]") for @proj;
    $dbo->do("create table t$_->[0] select (rowid-$_->[0])rowid,qtime,close from
        (select rowid,qtime,close from stockplop where ticker=? and rowid>$_->[0] order by qtime desc) sub
        order by qtime asc", $ticker) for @proj;

    my $cols = join(", ", map {"t$_->[0].close t$_->[0]_close"} @proj);
    my @join = map {"join t$_->[0] using (rowid)"} @proj;

    my $sth = $dbo->ready("select stockplop.*, $cols from stockplop @join");
    my $ins = $dbo->ready("insert into stockplop_annotations set rowid=?, description=?");
    $sth->execute;

    my %events;
    my $last;
    while( my $row = $sth->fetchrow_hashref ) {
        for my $event (keys %events) {
            delete $events{$event} unless exists $events{$event}{stopping_case};
        }

        if( defined $last->{"LAG(8)"} and defined $last->{"LAG(4)"} ) {
            $events{lag_break_up}{age} = 1
                if $last->{'LAG(4)'} < $last->{"LAG(8)"} and $row->{'LAG(4)'} > $row->{"LAG(8)"};

            $events{lag_break_down}{age} = 1
                if $last->{'LAG(4)'} > $last->{"LAG(8)"} and $row->{'LAG(4)'} < $row->{"LAG(8)"};
        }

        my @desc;
        for my $event (keys %events) {
            my $txt = "$event($events{$event}{age})";
               $txt =~ s/\(1\)$//;

            push @desc, $txt;
        }

        $ins->execute($row->{rowid}, "@desc");

        $last = $row;
    }
}

# }}}
