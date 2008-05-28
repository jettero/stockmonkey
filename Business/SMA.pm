package Math::Business::SMA;

use strict;
use warnings;

our $VERSION = "0.99";

use Carp;

1;

sub new { 
    bless {
        val => [],
    } 
}

sub set_days { 
    my $this = shift; 
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{days} = $arg;
}

sub insert {
    my $this = shift;
    my $arg  = shift;

    croak "You must set the number of days before you try to insert" if not $this->{days};

    push @{ $this->{val} }, $arg; 

    $this->recalc;
}

sub start_with {
    my $this        = shift;
       $this->{val} = shift;

    croak "bad arg to start_with" unless ref($this->{val}) eq "ARRAY";

    $this->recalc;
}

sub recalc {
    my $this = shift;

    my $i = int(@{ $this->{val} });

    shift @{ $this->{val} } while @{ $this->{val} } > $this->{days};

    my $j = int(@{ $this->{val} });

    if( @{ $this->{val} } == $this->{days} ) {
        my $t = 0;
        foreach my $v (@{ $this->{val} }) {
            $t += $v;
        }

        $this->{cur} = ($t/$this->{days});
    } elsif( defined($this->{cur}) ) {
        $this->{cur} = undef;
    }
}

sub query {
    my $this = shift;

    return $this->{cur};
}

__END__

=head1 NAME

Math::Business::SMA - Perl extension for calculating simple moving averages.

=head1 SYNOPSIS

  use Math::Business::SMA;

  my $sma = new Math::Business::SMA;

  set_days $sma 3;

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

Jettero Heller jettero@cpan.org

http://www.voltar.org

=head1 SEE ALSO

perl(1), Math::Business::SMA(3).

=cut
