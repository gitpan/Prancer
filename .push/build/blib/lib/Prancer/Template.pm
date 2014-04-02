package Prancer::Template;

use strict;
use warnings FATAL => 'all';

use Carp;
use Try::Tiny;
use Module::Load ();
use Prancer qw(logger);

sub load {
    my ($class, $config) = @_;

    unless (ref($config) && ref($config) eq "HASH" && $config->{'driver'}) {
        logger->warn("could not initialize template engine: no template engine configuration");
        return;
    }

    my $module = $config->{'driver'};

    try {
        Module::Load::load($module);
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->fatal("could not initialize template engine: not able to load ${module}: ${error}");
        croak;
    };

    unless ($module->can("render")) {
        logger->fatal("could not initialize template engine: ${module} doesn't implement 'render'");
        croak;
    }

    my $engine = undef;
    try {
        $engine = $module->new($config->{'options'});
        logger->info("initialized template engine with ${module}");
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->fatal("could not initialize template engine: ${error}");
        croak;
    };

    return $engine;
}

1;

=head1 NAME

Prancer::Template

=head1 SYNOPSIS

This module should not be used directly to access templates. Instead, one
should use L<Prancer>. For configuration options, please refer to the
documentation for the specific template engine you wish to use.

=head1 SEE ALSO

=over 4

=item1 L<Prancer::Template::TemplateToolkit>

=back

=cut
