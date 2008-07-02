package Math::Business::LaguerreFilter;

use strict;
use warnings;
use Carp;

our $VERSION = 1.0;

1;

sub recommended { croak "no recommendation" }

sub new { 
    my $class = shift;
    my $this  = bless [], $class;

    my $alpha = shift;
    if( defined $alpha ) {
        $this->set_alpha( $alpha );
    }

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = 0+shift;

    my $alpha = 2/(1+$arg);
    eval { $this->set_alpha( $alpha ) };
    croak "set_days() is basically set_alpha(2/(1+$arg)), which complained: $@" if $@;
}

sub set_alpha { 
    my $this  = shift; 
    my $alpha = 0+shift;
    my $days  = 2*(1/$alpha)-1;
       $days  = int $days;
       $days  = 1 if $days < 1;

  # warn "alpha=$alpha; days=$days";

    croak "alpha must be a real between 0 and 1" unless $alpha > 0 and $alpha < 1;
    @$this = (
        [],    # P-hist
        [],    # L0-L4
        $alpha,
        $days,
        undef, # filter
    );
}

sub insert {
    my $this = shift;
    my ($h, $L, $alpha, $days, $filter) = @$this;

    croak "You must set the number of days before you try to insert" if not defined $alpha;
    no warnings 'uninitialized';

    while( defined( my $P = shift ) ) {
        if( ref $P ) {
            my @a = eval {@$P}; croak $@ if $@;
            my $c = 0+@a;
            croak "high+low should only be two elements, not c=$c" unless $c == 2;
            $P = ($a[0]+$a[1])/$c;
        }

        if( defined $L->[0] ) {
            my $O = [ @$L ];

            # L0 = alpha*Price + (1 - alpha)*L0[1] = alpha*P + (1-alpha)*O[0]

            $L->[0] = $alpha*$P + (1-$alpha)*$O->[0];

            # L1 = (1 - alpha)*L1[1] - (1 - alpha)*L0 + L0[1] = (1 - alpha)*O[1] - (1 - alpha)*L[0] + O[0]
            # L2 = (1 - alpha)*L2[1] - (1 - alpha)*L1 + L1[1] = (1 - alpha)*O[2] - (1 - alpha)*L[1] + O[1]
            # L3 = (1 - alpha)*L3[1] - (1 - alpha)*L2 + L2[1] = (1 - alpha)*O[3] - (1 - alpha)*L[2] + O[2]
                                                                            
            $L->[1] = defined($O->[1]) ? (1 - $alpha)*$O->[1] - (1 - $alpha)*$L->[0] + $O->[0] : $O->[0];
            $L->[2] = defined($O->[2]) ? (1 - $alpha)*$O->[2] - (1 - $alpha)*$L->[1] + $O->[1] : $O->[1];
            $L->[3] = defined($O->[3]) ? (1 - $alpha)*$O->[3] - (1 - $alpha)*$L->[2] + $O->[2] : $O->[2];

        } elsif( @$h==$days-1 ) {
            my $sum = $P;
               $sum += $_ for @$h;

            $L->[0] = $sum/$days; # NOTE: this is not in the DSP book
            @$h =();

        } else {
            push @$h, $P;
        }
    }

    if( 4 == grep {defined $_} @$L ) {
        $this->[-1] = ($L->[0] + 2*$L->[1] + 2*$L->[2] + $L->[3])/6;
    }
}

sub query {
    my $this = shift;

    return $this->[-1];
}

__END__

=head1 NAME

Math::Business::LaguerreFilter - Technical Analysis: Laguerre Filter

=head1 SYNOPSIS

  use Math::Business::LaguerreFilter;

  my $avg = new Math::Business::LaguerreFilter;
     $avg->set_days(9); 
     $avg->set_alpha(0.2); # same (roughly)

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

For short, you can skip the set_alpha() by suppling the setting to new():

  my $avg = new Math::Business::LaguerreFilter(0.2); # same as set_alpha(0.2)

Ehlers actually uses the high and low price, rather than the closing price, in
his book.  The insert method takes either a closing price or the high and low
price as a two-touple.

    $avg->insert( $close );       # correct
    $avg->insert( [$high,$low] ); # also correct

=head1 RESEARCHER

John F. Ehlers talked about how to adapt Laguerre Polynomials to technical
analysis in an engineering-oriented 2004 book titled I<Cybernetic Analysis for
Stocks and Futures: Cutting-Edge DSP Technology to Improve Your Trading>.

This technique appears in a chapter with the unlikely title
I<Time Warp - Without Space Travel>.

If you locate the chapter or the book, you should read it.  It's written well
and it's a unique way to look at moving averages in general (e.g. there are
filter schematics of each equation).

=head1 Thanks

John Baker <johnb@listbrokers.com>

=head1 AUTHOR

Paul Miller <jettero@cpan.org>

I am using this software in my own projects...  If you find bugs, please please
please let me know.

I normally hang out on #perl on freenode, so you can try to get immediate
gratification there if you like.  L<irc://irc.freenode.net/perl>

There is also a mailing list with very light traffic that you might want to
join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright (c) 2008 Paul Miller -- LGPL [Software::License::LGPL_2_1]

    perl -MSoftware::License::LGPL_2_1 \
         -e '$l = Software::License::LGPL_2_1->new({
             holder=>"Paul Miller"});
             print $l->fulltext' | less

=head1 SEE ALSO

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

=cut
