package Prancer::Session::Store::YAML;

use strict;
use warnings FATAL => 'all';

use Plack::Session::Store::File;
use parent qw(Plack::Session::Store::File);

use Carp;
use Cwd ();
use YAML ();
use Prancer qw(logger);

sub new {
    my ($class, $config) = @_;

    return try {
        my $path = Cwd::realpath(delete($config->{'path'}) || '/tmp');
        die "${path} does not exist\n" unless (-e $path);
        die "${path} is not readable\n" unless (-r $path);

        # i want names like "path"
        # but the Prancer::Middleware::Session really wants "dir"
        # so rename it
        $config->{'dir'} = $path;

        # set the storage type to YAML
        my $self = bless($class->SUPER::new(%{$config || {}}), $class);
        $self->{'_serializer'}   = sub { YAML::DumpFile(reverse(@_)) };
        $self->{'_deserializer'} = sub { YAML::LoadFile(@_) };

        logger->info("intialized session handler with YAML in ${path}");
        return $self;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->fatal("could not initialize sessions handler: ${error}");
        croak;
    };
}

1;

=head1 NAME

Prancer::Session::Store::YAML

=head1 SYNOPSIS

This module implements a session handler based on YAML files. Sessions are
stored at the configured path. This backend an perfectly be used in production
environments, but two things should be kept in mind: The content of the session
files is in plain text, and the session files should be purged by a cron job.

To use this session handler, add this to your configuration file:

    session:
        store:
            driver: Prancer::Session::Store::YAML
            options:
                path: /tmp/prancer/sessions

=head1 OPTIONS

=over 4

=item path

B<REQUIRED> This indicates where sessions will be stored. If this path does not
exist it will be created, if possible. This must be an absolute path and the
destination must be writable by the same user that is running the application
server. If this is not set your application will not start. If this is set to a
path that your application cannot write to your application will not start. If
this is set to a path that doesn't exist and the path can't be created your
application will not start.

=back

=cut
