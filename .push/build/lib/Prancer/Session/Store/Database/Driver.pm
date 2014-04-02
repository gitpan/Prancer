package Prancer::Session::Store::Database::Driver;

use strict;
use warnings FATAL => 'all';

use Plack::Session::Store;
use parent qw(Plack::Session::Store);

use Carp;
use YAML;
use Try::Tiny;
use Prancer qw(logger);

sub new {
    my ($class, $config) = @_;

    try {
        require DBI;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->fatal("could not initialize session handler: could not load DBI: ${error}");
        croak;
    };

    # this is the only required field
    unless ($config->{'database'}) {
        logger->fatal("could not initialize session handler: no database name configured");
        croak;
    }

    # initialize the serializer that will be used
    my $self = bless($class->SUPER::new(%{$config || {}}), $class);
    $self->{'_serializer'}      = sub { YAML::freeze(reverse(@_)) };
    $self->{'_deserializer'}    = sub { YAML::thaw(@_) };

    $self->{'_database'}        = $config->{'database'};
    $self->{'_username'}        = $config->{'username'};
    $self->{'_password'}        = $config->{'password'};
    $self->{'_hostname'}        = $config->{'hostname'};
    $self->{'_port'}            = $config->{'port'};
    $self->{'_autocommit'}      = $config->{'autocommit'};
    $self->{'_charset'}         = $config->{'charset'};
    $self->{'_check_threshold'} = $config->{'connection_check_threshold'} || 30;
    $self->{'_table'}           = $config->{'table'} || "sessions";
    $self->{'_timeout'}         = $config->{'expiration_timeout'} || 1800;
    $self->{'_autopurge'}       = $config->{'autopurge'} || 1;

    # store a pool of database connection handles
    $self->{'_handles'} = {};

    return $self;
}

sub handle {
    my $self = shift;

    # to be fork safe and thread safe, use a combination of the PID and TID (if running
    # with use threads) to make sure no two processes/threads share a handle.
    # implementation based on DBIx::Connector by David E. Wheeler
    my $pid_tid = $$;
    $pid_tid .= '_' . threads->tid if $INC{'threads.pm'};

    # OK, see if we have a matching handle
    my $handle = $self->{'_handles'}->{$pid_tid} || undef;

    if ($handle->{'dbh'}) {
        if ($handle->{'dbh'}{'Active'} && $self->{'_check_threshold'} &&
            (time - $handle->{'last_connection_check'} < $self->{'_check_threshold'})) {

            # the handle has been checked recently so just return it
            return $handle->{dbh};
        } else {
            if (_check_connection($handle->{'dbh'})) {
                $handle->{last_connection_check} = time;
                return $handle->{'dbh'};
            } else {
                # er need to reconnect
                logger->debug("database connection to '${\$self->{'_connection'}}' went away -- reconnecting");

                # try to disconnect but don't care if it fails
                if ($handle->{'dbh'}) {
                    try { $handle->{'dbh'}->disconnect() } catch {};
                }

                # try to connect again and save the new handle
                $handle->{'dbh'} = $self->_get_connection();
                return $handle->{'dbh'};
            }
        }
    } else {
        $handle->{'dbh'} = $self->_get_connection();
        if ($handle->{'dbh'}) {
            $handle->{'last_connection_check'} = time;
            $self->{'_handles'}->{$pid_tid} = $handle;
            return $handle->{'dbh'};
        }
    }

    return;
}

sub _get_connection {
    my $self = shift;

    my $dbh = undef;
    try {
        $dbh = DBI->connect(@{$self->{'_dsn'}}) || die "${\$DBI::errstr}\n";
    } catch {
        logger->fatal("could not initialize database connection '${\$self->{'_connection'}}': " . $_);
    };

    return $dbh;
}

# Check the connection is alive
sub _check_connection {
    my $dbh = shift;
    return unless $dbh;

    if ($dbh->{Active} && (my $result = $dbh->ping())) {
        if (int($result)) {
            # DB driver itself claims all is OK, trust it:
            return 1;
        } else {
            # it was "0 but true", meaning the DBD doesn't implement ping and
            # instead we got the default DBI ping implementation. implement
            # our own basic check, by performing a real simple query.
            return try {
                return $dbh->do('SELECT 1');
            } catch {
                return 0;
            };
        }
    } else {
        return;
    }
}

1;
