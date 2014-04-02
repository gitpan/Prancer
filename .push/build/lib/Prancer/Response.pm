package Prancer::Response;

use strict;
use warnings FATAL => 'all';

use Carp;
use Plack::Response;
use Hash::MultiValue;
use URI::Escape ();

sub new {
    my ($class, $env) = @_;
    return bless({
        '_response' => Plack::Response->new($env),
        '_cookies' => Hash::MultiValue->new(),
        '_headers' => Hash::MultiValue->new(),
    }, $class);
}

# set a single header
# or get all the keys
sub header {
    my $self = shift;

    # return the keys if nothing is asked for
    return keys(%{$self->headers()}) unless @_;

    # if given just a key return that
    if (@_ == 1) {
        my $key = shift;
        return $self->headers->{$key} unless wantarray;
        return $self->headers->get_all($key);
    }

    # if we are given multiple args assume they are headers in key/value pairs
    croak "odd number of headers" unless (@_ % 2 == 0);
    while (@_) {
        my ($key, $value) = (shift(@_), shift(@_));
        $self->headers->add($key => [@{$self->headers->get_all($key) || []}, $value]);
    }

    return;
}

# get all the headers that have been set
sub headers {
    my $self = shift;
    return $self->{'_headers'};
}

# set a single cookie
# or get all the keys
sub cookie {
    my $self = shift;

    # return the keys if nothing is asked for
    return keys(%{$self->cookies()}) unless @_;

    # if given just a key return that
    if (@_ == 1) {
        my $key = shift;
        return $self->cookies->{$key} unless wantarray;
        return $self->cookies->get_all($key);
    }

    # if we are given multiple args assume they are cookies in key/value pairs
    croak "odd number of cookies" unless (@_ % 2 == 0);
    while (@_) {
        my ($key, $value) = (shift(@_), shift(@_));

        # take a moment to validate the cookie
        # TODO

        $self->cookies->add($key => [@{$self->cookies->get_all($key) || []}, $value]);
    }

    return;
}

sub cookies {
    my $self = shift;
    return $self->{'_cookies'};
}

sub body {
    my $self = shift;

    # make the response be a callback
    if (ref($_[0]) && ref($_[0]) eq "CODE") {
        $self->{'_callback'} = shift;
        return;
    }

    # just add this to the body, whatever it is
    return $self->{'_response'}->body(@_);
}

sub finalize {
    my ($self, $status) = @_;
    $self->{'_response'}->status($status);

    # add headers
    for my $key (keys %{$self->headers()}) {
        for my $value (@{$self->headers->get_all($key)}) {
            $self->{'_response'}->header($key => $value);
        }
    }

    # add cookies
    for my $key (keys %{$self->cookies()}) {
        for my $value (@{$self->cookies->get_all($key)}) {
            $self->{'_response'}->header('Set-Cookie', $self->_bake_cookie($key, $value));
        }
    }

    if (defined($self->{'_callback'}) &&
        ref($self->{'_callback'}) &&
        ref($self->{'_callback'}) eq "CODE") {

        # empty the body out just in case
        $self->{'_response'}->body("");

        return sub {
            my $responder = shift;
            # finalize will always return a three element array. the third
            # element is supposed to be the body. because we don't have a body
            # yet (it's in the callback) use splice to exclude the third
            # element (aka the body) and just return the status code and the
            # list of headers.
            my $writer = $responder->([splice(@{$self->{'_response'}->finalize()}, 0, 2)]);
            return $self->{'_callback'}->($writer);
        }
    }

    # just return a normal response
    return $self->{'_response'}->finalize();
}

sub _bake_cookie {
    my ($self, $key, $value) = @_;

    my @cookie = (URI::Escape::uri_escape($key) . "=" . URI::Escape::uri_escape($value->{'value'}));
    push(@cookie, "domain="  . $value->{'domain'})                    if $value->{'domain'};
    push(@cookie, "path="    . $value->{'path'})                      if $value->{'path'};
    push(@cookie, "expires=" . $self->_cookie_date($self->expires())) if $value->{'expires'};
    push(@cookie, "secure")                                           if $value->{'secure'};
    push(@cookie, "HttpOnly")                                         if $value->{'httponly'};
    return join("; ", @cookie);

}

my @MON  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @WDAY = qw( Sun Mon Tue Wed Thu Fri Sat );

sub _cookie_date {
    my ($self, $expires) = @_;

    if ($expires =~ /^\d+$/x) {
        # all numbers -> epoch date
        # (cookies use '-' as date separator, HTTP uses ' ')
        my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($expires);
        $year += 1900;

        return sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
                       $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec);
    }

    return $expires;
}

1;

=head1 NAME

Prancer::Response

=head1 SYNOPSIS

    sub handle {

        ...

        my $response = context->response();
        status(Prancer::Const::OK);
        response->header("Content-Type" => "text/plain");
        response->body("hello, goodbye");
        finalize;
    }

    # or using a callback
    sub handle {

        ...

        status(Prancer::Const::OK);
        $response->header("Content-Type" => "text/plain");
        $response->callback(sub {
            my $writer = shift;
            $writer->write("What's up?");
            $writer->close();
        });
        finalize;
    }

=head1 ATTRIBUTES

=over 4

=item header

If called with no arguments this will return the names of all headers that have
been set to be sent with the response. Otherwise, this method expects a list of
headers to add to the response. For example:

    $response->header("Content-Type" => "text/plain");
    $response->header("Content-Length" => 1234, "X-Foo" => "bar");

If the header has already been set this will add another value to it and the
response will include the same header multiple times. To replace a header that
has already been set, remove the existing value first:

    $response->headers->remove("X-Foo");

=item headers

Returns a L<Hash::MultiValue> of all headers that have been set to be sent with
the response.

=item cookie

If called with no arguments this will return the names of all cookes that have
been set to be sent with the response. Otherwise, this method expects a list of
cookies to add to the response. For example:

    $response->cookie('foo' => {
        'value'   => 'test',
        'path'    => "/",
        'domain'  => '.example.com',
        'expires' => time + 24 * 60 * 60,
    });

The hashref may contain things such as C<value>, C<domain>, C<expires>,
C<path>, C<httponly>, and C<secure>. C<expires> can take a string or an integer
(as an epoch time) and B<does not> convert string formats like C<+3M>.

=item cookies

Returns a L<Hash::MultiValue> of all cookies that have been set to be sent with
the response.

=item body

Send buffered output to the client. Anything sent to the client with this
method will be buffered until C<finalize> is called. For example:

    $response->body("hello");
    $response->body("goodbye", "world");

The body may also be a callback to send a streaming response to the client.
Any headers or response codes set in the callback will be ignored as they must
all be set beforehand. Any body set before or after a callback is set will also
be ignored. For example:

    $response->body(sub {
        my $writer = shift;
        $writer->write("Hello, world!");
        $writer->close();
    });

=item finalize

This requires one argument: the HTTP status code of the response. It will then
send a PSGI compatible result. For example:

    # send a 200 response
    $response->finalize(Prancer::Const::OK);

    # or hard code it
    $response->finalize(405);

=back

=cut
