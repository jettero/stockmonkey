package Math::Business::ADX;

use strict;
use warnings;
use Carp;

use base 'Math::Business::DMI';

1;

sub set_days {
    my $this = shift;

    $this->SUPER::set_days(@_);
    $this->{tag} = "ADX($this->{days})";
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::ADX - Technical Analysis: ADX (wilder's DMI)

=head1 SEE ALSO

ADX is an alternate name for DMI.  This module is simply an alias for the DMI.

perl(1), L<Math::Business::DMI>

=cut
