package Prancer::Logger;

use strict;
use warnings FATAL => 'all';

use Module::Load ();
use Try::Tiny;

sub load {
    my ($class, $config) = @_;
    my $module = $config->{'driver'} || "Prancer::Logger::Console";

    try {
        Module::Load::load($module);
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        die "could not initialize logger: not able to load ${module}: ${error}\n";
    };

    # make sure the module implements our required logging levels
    for (qw(debug info warn error fatal)) {
        die "could not initialize logger: ${module} doesn't implement '${_}'\n" unless $module->can($_);
    }

    # now create and load the module
    return $module->new($config->{'options'});
}

1;

=head1 NAME

Prancer::Logger

=head1 SYNOPSIS

This module should not be used directly to access the logger. Instead, one
should use L<Prancer>. For configuration options, please refer to the
documentation for the specific logger you wish to use.

=head1 SEE ALSO

=over 4

=item L<Prancer::Logger::Console>

=back

=cut
