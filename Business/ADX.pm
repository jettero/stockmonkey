package Math::Business::ADX;

use strict;
use warnings;

use version; our $VERSION = qv("1.0");
use Carp;

1;

sub recommended {
    my $class = shift;

    $class->new(14);
}

sub new { 
    my $class = shift;
    my $this  = bless {
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

    die; # TODO
}

sub insert {
    my $this = shift;

    die; # TODO
}

sub start_with {
    my $this = shift;

    die; # TODO
}

sub query_pdi {
    my $this = shift;

    return $this->{PDi};
}

sub query_mdi {
    my $this = shift;

    return $this->{MDI};
}

sub query {
    my $this = shift;

    return ($this->{PDI}, $this->{MDI}, $this->{ADX}) if wantarray;
    return $this->{ADX};
}

__END__

=head1 NAME

Math::Business::ADX - Technical Analysis: Average Directional Index

=head1 SYNOPSIS

  use Math::Business::ADX;

  my $adx = new Math::Business::ADX;
     $adx->set_days(14);

  # alternatively/equivilently
  my $adx = new Math::Business::ADX(14);

  # or to just get the recommended model ... (14)
  my $adx = Math::Business::ADX->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one: 
  $adx->insert( @data_points );
  $adx->insert( $_ ) for @data_points;

  my $adi = $adx->query;     # the composite
  my $pdi = $adx->query_pdi; # the DI+
  my $mdi = $adx->query_mdi; # the DI-

  # or
  my ($pdi, $mdi, $adx) = $adx->query;

  if( defined $adi ) {
      print "ADX: $adi.\n";

  } else {
      print "ADX: n/a.\n";
  }

  # you may use this to kick start 
  $adx->start_with( blah blah blah ); # TODO

=head1 Thanks

Todd Litteken PhD <cl@xganon.com> 

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

L<http://en.wikipedia.org/wiki/Relative_Strength_Index>

=cut
