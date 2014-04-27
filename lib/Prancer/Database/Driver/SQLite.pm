package Prancer::Database::Driver::SQLite;

use strict;
use warnings FATAL => 'all';

use Prancer::Database::Driver;
use parent qw(Prancer::Database::Driver);

use Carp;
use Try::Tiny;
use Prancer qw(logger);

sub new {
    my $class = shift;
    my $self = bless($class->SUPER::new(@_), $class);

    try {
        require DBD::SQLite;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->fatal("could not initialize database connection '${\$self->{'_connection'}}': could not load DBD::SQLite: ${error}");
        croak;
    };

    my $database = $self->{'_database'};
    my $username = $self->{'_username'};
    my $password = $self->{'_password'};
    my $hostname = $self->{'_hostname'};
    my $port     = $self->{'_port'};
    my $charset  = $self->{'_charset'};

    # if autocommit isn't configured then enable it by default
    my $autocommit = (defined($self->{'_autocommit'}) ? ($self->{'_autocommit'} =~ /^(1|true|yes)$/ix ? 1 : 0) : 1);
    logger->debug("auto commit is not enabled on database connection '${\$self->{'_connection'}}'") unless $autocommit;

    my $dsn = "dbi:SQLite:dbname=${database}";
    $dsn .= ";host=${hostname}" if defined($hostname);
    $dsn .= ";port=${port}" if defined($port);

    my $params = {
        'AutoCommit' => $autocommit,
        'RaiseError' => 1,
        'PrintError' => 0,
    };
    if ($charset && $charset =~ /^utf8$/xi) {
        $params->{'pg_enable_utf8'} = 1;
    }

    $self->{'_dsn'} = [$dsn, $username, $password, $params];
    logger->debug("database connection '${\$self->{'_connection'}}' dsn: ${dsn}");

    return $self;
}

1;
