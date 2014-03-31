package Prancer::Session::State::Cookie;

use strict;
use warnings FATAL => 'all';

use Plack::Session::State::Cookie;
use parent qw(Plack::Session::State::Cookie);

# this module does not require any additional settings. we override the parent
# module almost strictly for semantics and maybe some day (but probably not)
# this module might be replaced by a different, homegrown version.

sub new {
    my ($class, $config) = @_;
    return bless($class->SUPER::new(%{$config || {}}), $class);
}

1;

=head1 NAME

Prancer::Session::State::Cookie

=head1 SYNOPSIS

THis module enables a session state handler. NOTE: One should not use this
module to connect to the database. Instead, one should use L<Prancer::Context>.

This module implements a session state handler. It will keep track of sessions
by setting cookies into the response headers and reading cookies in the request
headers. You must enable this if you want sessions to work.

To use this session state handler, add this to your configuration file:

    session:
        state:
            driver: Prancer::Session::State::Cookie
            options:
                key: PSESSION
                path: /
                domain: .example.com
                # expires in 30 minutes
                expires: 1800
                secure: 1
                httponly: 1

=head1 OPTIONS

=over 4

=item key

Set the name of the cookie. The default is B<PSESSION>.

=item path

Path of the cookie, this defaults to "/";

=item domain

Domain of the cookie. If nothing is supplied then it will not be included in
the cookie.

=item expires

Expiration time of the cookie in seconds. If nothing is supplied then it will
not be included in the cookie, which means the session expires per browser
session.

=item secure

Secure flag for the cookie. If nothing is supplied then it will not be included
in the cookie. If this is set then the cookie will only be transmitted on
secure connections.

=item httponly

HttpOnly flag for the cookie. If nothing is supplied then it will not be
included in the cookie. If this is set then the cookie will only be accessible
by the server and not by, say, JavaScript.

=back

=cut
