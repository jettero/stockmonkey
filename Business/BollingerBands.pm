package Math::Business::BollingerBands;

use strict;
use warnings;

use version; our $VERSION = qv("1.01");
use Carp;

1;

sub new { 
    my $class = shift;
    my $this  = bless {
        dev => [],
        val => [],
        N => undef, # days in the average
        K => undef, # deviations
    }, $class;

    if( @_ == 2 ) {
        $this->set_days($_[0]);
        $this->set_deviations($_[1]);
    }

    return $this;
}

sub set_deviations { 
    my $this = shift; 
    my $arg  = int shift;

    croak "deviations must be a positive non-zero integer" if $arg <= 0;
    $this->{K} = $arg;
}

sub set_days { 
    my $this = shift; 
    my $arg  = int shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;
    $this->{N} = $arg;

    $this->{val} = [];
    $this->{dev} = [];

    delete $this->{M};
    delete $this->{U};
    delete $this->{L};
}

sub insert {
    my $this = shift;
    my $val  = $this->{val};
    my $dev  = $this->{dev};

    my $N = $this->{N};
    my $K = $this->{K};

    croak "You must set the number of days and deviations before you try to insert" unless $N and $K;
    while( defined(my $value = shift) ) {
        push @$val, $value;

        if( @$val >= $N ) {
            if( defined( my $s = $this->{M} ) ) {
                my $old = shift @$val;
                $this->{M} = my $M = $s - $old/$N + $value/$N;

                push @$dev, (my $new = ($value - $M)**2);
                $old = shift @$dev;

                my $d = $this->{d};
                $this->{d} = $d = $d - $old/$N + $new/$N;

                my $k_stddev = $K * sqrt($d);
                $this->{L} = $M - $k_stddev;
                $this->{U} = $M + $k_stddev;

            } else {
                my $sum = 0;
                   $sum += $_ for @$val;

                $this->{M} = my $M = $sum/$N;
                @$dev = map {($_-$M)**2} @$val;

                $sum = 0;
                $sum += $_ for @$dev;

                $this->{d} = my $d = $sum/$N;

                my $k_stddev = $K * sqrt($d);
                $this->{L} = $M - $k_stddev;
                $this->{U} = $M + $k_stddev;
            }
        }
    }
}

*start_with = *insert;

sub query {
    my $this = shift;

    return ($this->{L}, $this->{M}, $this->{U}) if wantarray;
    return $this->{M};
}

__END__

=head1 NAME

Math::Business::BollingerBands - Technical Analysis: Bollinger Bands

=head1 SYNOPSIS

  use Math::Business::BollingerBands;

  my $bb = new Math::Business::BollingerBands;
     $bb->set_days(20);
     $bb->set_deviations(2);

  # alternatively/equivalently
  my $bb = new Math::Business::BollingerBands(20, 2);

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5 
      6 6 6 6 7 7 7 8 8 8 8 
  );

  # choose one: 
  $bb->insert( @closing_values );
  $bb->insert( $_ ) for @closing_values;

  my ($L,$M,$U) = $bb->query;
  if( defined $M ) {
      print "BB: $L < $M < $U.\n";

  } else {
      print "BB: n/a.\n";
  }

  # you may use this to kick start 
  $bb->start_with( @closes );

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

L<http://en.wikipedia.org/wiki/Bollinger_Bands>

L<http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:bollinger_bands>

=cut
