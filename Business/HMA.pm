package Math::Business::HMA;

use strict;
use warnings;
use Carp;
use Math::Business::WMA;

our $VERSION = 1.3;

1;

sub recommended { croak "no recommendation" }

sub new {
    my $class = shift;
    my $this  = bless [
        undef,
        undef,
        undef,
    ], $class;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive number" if $arg <= 0;

    @$this = (
        Math::Business::WMA->new(int($arg/2)),
        Math::Business::WMA->new($arg),
        Math::Business::WMA->new(int(sqrt($arg))),
    );
}

sub insert {
    my $this = shift;
    my ($po2, $p, $sqp) = @$this;

    croak "You must set the number of days before you try to insert" unless defined $sqp;
    while( defined(my $P = shift) ) {
        $po2->insert($P);
          $p->insert($P);

        if( defined( my $_p = $p->query ) and defined( my $_po2 = $po2->query ) ) {
            $sqp->insert( 2*$_po2 - $_p );
        }
    }
}

sub query {
    my $this = shift;

    return $this->[-1]->query;
}

__END__

=head1 NAME

Math::Business::HMA - Technical Analysis: Hull Moving Average

=head1 SYNOPSIS

  use Math::Business::HMA;

  my $avg = new Math::Business::HMA;
     $avg->set_days(8);

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

  my $longer_avg = new Math::Business::HMA(10);

=head1 RESEARCHER

The Hull Moving Average was invented Alan Hull circa 1990[?].

An SMA can smooth data fairly well but tends to lag terribly.  The HMA tries to
smooth data quickly (without the lag) by averaging some weighted moving
averages (L<Math::Business::WMA>) of itself at various intervals.

=head1 THANKS

John Baker C<< <johnb@listbrokers.com> >>

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

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://www.alanhull.com.au/hma/hma.html>

=cut
