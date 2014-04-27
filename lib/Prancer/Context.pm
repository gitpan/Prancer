package Prancer::Context;

use strict;
use warnings FATAL => 'all';

use Prancer;
use Hash::Merge::Simple;

sub new {
    my $class = shift;
    my %args = @_;
    return bless({
        '_env'      => $args{'env'},
        '_request'  => $args{'request'},
        '_response' => $args{'response'},
        '_session'  => $args{'session'},
    }, $class);
}

sub env {
    my $self = shift;
    return $self->{'_env'};
}

sub session {
    my $self = shift;
    return $self->{'_session'};
}

sub header {
    my $self = shift;
    my %args = (
        'get' => undef,
        'set' => undef,
        'value' => undef,
        @_
    );

    if (defined($args{'get'})) {
        my $x = $self->{'_request'};
        return $x->header($args{'get'});
    }

    if (defined($args{'set'})) {
        my $x = $self->{'_response'};
        return $x->header($args{'set'} => $args{'value'});
    }

    return;
}

sub headers {
    my $self = shift;
    return $self->{'_request'}->headers()
}

sub cookie {
    my $self = shift;
    my %args = (
        'get' => undef,
        'set' => undef,
        'value' => undef,
        @_
    );

    if (defined($args{'get'})) {
        my $x = $self->{'_request'};
        return $x->cookie($args{'get'});
    }

    if (defined($args{'set'})) {
        my $x = $self->{'_response'};
        return $x->cookie($args{'set'} => $args{'value'});
    }

    return;
}

sub cookies {
    my $self = shift;
    return $self->{'_request'}->cookies();
}

sub request {
    my $self = shift;
    return $self->{'_request'};
}

sub param {
    my $self = shift;
    return $self->{'_request'}->param(@_);
}

sub params {
    my $self = shift;
    return $self->{'_request'}->params(@_);
}

sub upload {
    my $self = shift;
    return $self->{'_request'}->upload(@_);
}

sub uploads {
    my $self = shift;
    return $self->{'_request'}->uploads(@_);
}

sub response {
    my $self = shift;
    return $self->{'_response'};
}

sub body {
    my $self = shift;
    return $self->{'_response'}->body(@_);
}

sub finalize {
    my $self = shift;
    return $self->{'_response'}->finalize(@_);
}

1;

=head1 NAME

Prancer::Context

=head1 SYNOPSIS

The context gives you access to all pieces of a request from request parameters
to cookies, sessions and headers. It can be used by calling C<context> from
anywhere in a package that extends L<Prancer::Application>. Otherwise you must
pass it to other packages to make it available.

    use Prancer::Application qw(:all);
    use parent qw(Prancer::Application);

    sub handle {
        my ($self, $env) = @_;

        mount('GET', '/', sub {
            context->header(set => 'Content-Type', value => 'text/plain');
            context->body("hello world");
            context->finalize(200);
        });

        return dispatch;
    }

=head1 METHODS

=over 4

=item env

Returns the PSGI environment for the request.

=item session

This gives access to the session in various ways. For example:

    my $does_foo_exist = context->session->has('foo');
    my $foo = context->session->get('foo');
    my $bar = context->session->get('bar', 'some default value if bar does not exist');
    context->session->set('foo', 'bar');
    context->session->remove('foo');

Changes made to the session are persisted immediately to whatever medium
backs your sessions.

=item request

Returns the L<Prancer::Request> object for the request.

=item response

Returns the L<Prancer::Response> object that will be used to generate the
response.

=item header

This gives access request and response headers. For example:

    # get a request header
    my $useragent = context->header(get => 'user-agent');

    # set a response header
    context->header(set => 'Content-Type', value => 'text/plain');

=item cookie

This gives access to request and response cookies. For example:

    # get a request cookie
    my $foo = context->cookie(get => 'foo');

    # set a response cookie
    context->cookie(set => 'foo', value => {
        'value' => 'bar',
        'domain' => '.example.com',
    });

=item param

This is a wrapper around the C<param> method to L<Prancer::Request>.

=item params

This is a wrapper around the C<params> method to L<Prancer::Request>.

=item upload

This is a wrapper around the C<upload> method to L<Prancer::Request>.

=item uploads

This is a wrapper around the C<uploads> method to L<Prancer::Request>.

=item body

This is a wrapper around the C<body> method to L<Prancer::Response>.

=item finalize

This is a wrapper around the C<finalize> method to L<Prancer::Response>.

=back

=cut
