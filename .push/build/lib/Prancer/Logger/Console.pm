package Prancer::Logger::Console;

use strict;
use warnings FATAL => 'all';

use Carp;

use Time::HiRes ();

use constant LEVELS => {
    DEBUG => 4,
    INFO  => 3,
    WARN  => 2,
    ERROR => 1,
    FATAL => 0,
};

sub new {
    my ($class, $config) = @_;
    my $self = bless({}, $class);

    # make sure that there is a level and that is only one of five
    my $level = uc($config->{'level'} || "info");
    die "invalid default log level: ${level}\n" unless ($level =~ /^(debug|info|warn|error|fatal)$/xi);
    $self->{'_level'} = LEVELS->{$level};

    return $self;
}

sub _log {
    my ($self, $level, $message) = @_;

    croak "invalid message log level ${level}\n" unless ($level =~ /^(debug|info|warn|error|fatal)$/xi);
    return if (LEVELS->{uc($level)} > $self->{'_level'});

    my ($seconds, $microseconds) = Time::HiRes::gettimeofday();
    my ($second, $minute, $hour, $day, $month, $year) = localtime($seconds);
    $message =~ s/^\s+|\s+$//xgs;
    print STDOUT sprintf("%04d-%02d-%02d %02d:%02d:%02d,%03d %5s - %s\n", ($year + 1900), ($month + 1), $day, $hour, $minute, $second, ($microseconds / 1000), uc($level), $message);
    return;
}

sub debug {
    my ($self, $message) = @_;
    $self->_log("debug", $message);
    return;
}

sub info {
    my ($self, $message) = @_;
    $self->_log("info", $message);
    return;
}

## no critic (ProhibitBuiltinHomonyms)
sub warn {
    my ($self, $message) = @_;
    $self->_log("warn", $message);
    return;
}

sub error {
    my ($self, $message) = @_;
    $self->_log("error", $message);
    return;
}

sub fatal {
    my ($self, $message) = @_;
    $self->_log("fatal", $message);
    return;
}

1;

=head1 NAME

Prancer::Logger::Console

=head1 SYNOPSIS

This module configures a logger that sends log messages directly to STDOUT.
This is the default logger if no other logger is configured. If you wish to
configure this logger explicitly, add this to your configuration file:

    logger:
        driver: Prancer::Logger::Console
        options:
            level: debug

=head1 OPTIONS

=over 4

=item level

Set the default logging level.

=back

=cut
