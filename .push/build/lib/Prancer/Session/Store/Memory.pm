package Prancer::Session::Store::Memory;

use strict;
use warnings FATAL => 'all';

use Plack::Session::Store;
use parent qw(Plack::Session::Store);

# this module does not require any additional settings
# we override the parent module strictly for semantics
# and maybe some day (but probably not) this module might be replaced by a
# different, homegrown version

sub new {
    my ($class, $config) = @_;
    return bless($class->SUPER::new(%{$config || {}}), $class);
}

1;

=head1 NAME

Prancer::Session::Store::Memory

=head1 SYNOPSIS

This module implements a session handler where all sessions are kept in memory.
This B<SHOULD NOT BE USED IN PRODUCTION>. If the server restarts all of your
users will be logged out. If you are using a multi-process server like Starman,
your users will be logged out whenever they connect to a different process so
basically every time they connect. This should be used strictly for testing.

Though this will be the default session handler if none is configured, it can
be explicitly configured like this:

    session:
        store:
            driver: Prancer::Session::Store::Memory

=cut
