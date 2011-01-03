package Math::Business::EMA;

use strict;
use warnings;
use Carp;

our $VERSION = 2.5;

1;

sub recommended { croak "no recommendation" }

sub new {
    my $class = shift;
    my $this = bless {
        EMA => undef,
        R   => 0,
        R1  => 0,
    }, $class;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{R}    = 2.0 / (1.0 + $arg);
    $this->{R1}   = (1 - $this->{R});
    $this->{days} = $arg;
}

sub insert {
    my $this = shift;

    croak "You must set the number of days before you try to insert" if not $this->{R};

    while( defined(my $Yt  = shift) ) {
        if( defined(my $e = $this->{EMA}) ) {
            $this->{EMA} = ( $this->{R} * $Yt ) + ( $this->{R1} * $e );

        } else {
            my ($p,$N);
            if( ref($p = $this->{_p}) and (($N = @$p) >= $this->{days}-1) ) {
                my $sum = 0;
                   $sum += $_ for @$p;

                $this->{EMA} = ( $this->{R} * $Yt ) + ( $this->{R1} * ($sum/$N) );
                delete $this->{_p};

            } else {
                push @{$this->{_p}}, $Yt;
            }
        }
    }
}

sub query {
    my $this = shift;

    return $this->{EMA};
}

__END__

=head1 NAME

Math::Business::EMA - Technical Analysis: Exponential Moving Average

=head1 SYNOPSIS

  use Math::Business::EMA;

  my $avg = new Math::Business::EMA;
     $avg->set_days(7);

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $avg->insert( @closing_values );
  $avg->insert( $_ ) for @closing_values;

  if( defined(my $q = $avg->query) ) {
      print "value: $q.\n";

  } else {
      print "value: n/a.\n";
  }

For short, you can skip the set_days() by suppling the setting to new():

  my $longer_ema = new Math::Business::EMA(10);

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.

I normally hang out on #perl on freenode, so you can try to get immediate
gratification there if you like.  L<irc://irc.freenode.net/perl>

There is also a mailing list with very light traffic that you might want to
join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright (c) 2011 Paul Miller

=head1 LICENSE

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

[This software may have had previous licenses, of which the current maintainer
is completely unaware.  If this is so, it is possible the above license is
incorrect or invalid.]

=head1 SEE ALSO

perl(1), L<Math::Business::EMA>, L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://en.wikipedia.org/wiki/Exponential_moving_average>

=cut
