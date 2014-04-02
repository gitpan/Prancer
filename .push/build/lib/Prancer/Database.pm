package Prancer::Database;

use strict;
use warnings FATAL => 'all';

use Carp;
use Prancer;
use Module::Load ();
use Try::Tiny;
use Prancer qw(logger);

sub load {
    my ($class, $config) = @_;

    unless (ref($config) && ref($config) eq "HASH") {
        logger->warn("could not initialize database connection: no database configuration");
        return;
    }

    # we can load multiple databases
    my $handles = {};

    foreach my $key (keys %{$config}) {
        my $subconfig = $config->{$key};

        unless (ref($subconfig) && ref($subconfig) eq "HASH" && $subconfig->{'driver'}) {
            logger->warn("could not initialize database connection '${key}': no database driver configuration");
            return;
        }

        my $module = $subconfig->{'driver'};

        try {
            Module::Load::load($module);
        } catch {
            my $error = (defined($_) ? $_ : "unknown");
            logger->fatal("could not initialize database connection '${key}': not able to load ${module}: ${error}");
            croak;
        };

        unless ($module->can("handle")) {
            logger->fatal("could not initialize database connection '${key}': ${module} doesn't implement 'handle'");
            croak;
        }

        # now initialize that module
        try {
            $handles->{$key} = $module->new($subconfig->{'options'}, $key);
            logger->info("initialized database connection '${key}' with ${module}");
        } catch {
            my $error = (defined($_) ? $_ : "unknown");
            logger->fatal("could not initialize database connection '${key}': ${error}");
            croak;
        };
    }

    return $handles;
}

1;

=head1 NAME

Prancer::Database

=head1 SYNOPSIS

This module enables connections to a database. NOTE: One should not use this
module to connect to the database. Instead, one should use L<Prancer>.

It's important to remember that when running your application in a single-
threaded, single-process application server like, say, L<Twiggy>, all users of
your application will use the same database connection. If you are using
callbacks then this becomes very important. You will want to take care to avoid
crossing transactions or to avoid expecting a database connection or
transaction to be in the same state it was before a callback.

To use a database connector, add something like this to your configuration
file:

    database:
        connection-name:
            driver: Prancer::Database::Driver::DriverName
            options:
                username: test
                password: test
                database: test
                hostname: localhost
                port: 5432
                autocommit: true
                charset: utf8
                connection_check_threshold: 10

The "connection-name" can be anything you want it to be. This will be used when
requesting a connection from Prancer to determine which connection to return.
If only one connection is configured it may be prudent to call it "default" as
that is the name that Prancer will look for if no connection name is given.
For example:

    my $dbh = database;  # returns whatever connection is called "default"
    my $dbh = database('foo');  # returns the connection called "foo"

=head1 OPTIONS

=over 4

=item database

B<REQUIRED> The name of the database to connect to.

=item username

The username to use when connecting. If this option is not set the default is
the user running the application server.

=item password

The password to use when connectin. If this option is not set the default is to
connect with no password.

=item hostname

The host name of the database server. If this option is not set the default is
to connect to localhost.

=item port

The port number on which the database server is listening. If this option is
not set the default is to connect on the database's default port.

=item autocommit

If set to a true value -- like 1, yes, or true -- this will enable autocommit.
If set to a false value -- like 0, no, or false -- this will disable
autocommit. By default, autocommit is enabled.

=item charset

The character set to connect to the database with. If this is set to "utf8"
then the database connection will attempt to make UTF8 data Just Work if
available.

=item connection_check_threshold

This sets the number of seconds that must elapse between calls to get a
database handle before performing a check to ensure that a database connection
still exists and will reconnect if one does not. This handles cases where the
database handle hasn't been used in a while and the underlying connection has
gone away. If this is not set it will default to 30 seconds.

=back

=head1 SEE ALSO

=over 4

=item L<Prancer::Database::Driver::Pg>

=back

=cut
