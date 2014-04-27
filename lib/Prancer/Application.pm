package Prancer::Application;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent qw(Exporter);

use Carp;
use Try::Tiny;
use Module::Load ();
use Router::Boom::Method;
use Prancer;

our @EXPORT_OK = qw(context mount dispatch config logger database);
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);

sub new {
    my ($class, $context) = @_;
    my $self = bless({ '_context' => $context }, $class);
    $self->{'_dispatcher'} = Router::Boom::Method->new();

    # because the actual method needs a reference to the object it belongs to,
    # it will be wrapped to provide $self as the first argument. we assume that
    # the exported methods are actually implemented by a method with the same
    # name but prefixed with an underscore. this loop dynamically creates the
    # exported method and makes it call the actual method.
    for my $method (@EXPORT_OK) {
        no strict 'refs';
        no warnings 'redefine';
        my $exported = __PACKAGE__ . "::${method}";
        *{"${exported}"} = sub {
            my $internal = "_${method}";
            &$internal($self, @_);
        };
    }

    return $self;
}

sub handle {
    my ($self, $env) = @_;
    croak "method 'handle' must be implemented by subclass to " . __PACKAGE__;
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _config {
    my $self = shift;
    return Prancer::config(@_);
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _logger {
    my $self = shift;
    return Prancer::logger(@_);
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _database {
    my $self = shift;
    return Prancer::database(@_);
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _context {
    my $self = shift;
    return $self->{'_context'};
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _mount {
    my ($self, $method, $path, $sub) = @_;

    unless ($sub && ref($sub) && ref($sub) eq "CODE") {
        croak "can only dispatch to a sub";
    }

    $self->{'_dispatcher'}->add($method, $path, $sub);
    return;
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _dispatch {
    my $self = shift;

    my $env = $self->{'_context'}->env();
    my $path = $env->{PATH_INFO};
    my $method = $env->{REQUEST_METHOD};
    my ($matched, $captured, $is_method_not_allowed) = $self->{'_dispatcher'}->match($method, $path);

    return [405, ['Content-Type', 'text/plain'], ['method not allowed']] if ($is_method_not_allowed);
    return [404, ['Content-Type', 'text/plain'], ['not found']] unless defined($matched);
    return $matched->($captured);
}

1;

=head1 NAME

Prancer::Application

=head1 SYNOPSIS

This package is where your application should start.

    package MyApp;

    use Prancer::Application qw(:all);
    use parent qw(Prancer::Application);

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(shift);

        # when prancer is instantiated, the programmer has the option to pass
        # extra arguments after the handler class name. those arguments will end
        # up in here!
        #
        # of course, you don't have to write a ->new method if you don't want to as
        # one is created automatically in Prancer::Application. but that means that
        # if you DO create one you must call to ->SUPER::new first and you MUST
        # pass the first argument to ->new (after $class) to ->SUPER::new in order
        # for Prancer to work correctly.

        return $self;
    }

    sub handle {
        my ($self, $env) = @_;

        mount('GET', '/', sub {
            context->header(set => 'Content-Type', value => 'text/plain');
            context->body("hello world");
            context->finalize(200);
        });

        return dispatch;
    }

A new instance of this package is created on every request so that request
specific fields may be filled in and available. It also means that your code
should be as lightweight as possible.

Your class should implement C<handle>. Two arguments are passed to this method:
the instance of your class created for this request and C<$env> for the
request. You probably don't need to use C<$env> because the methods detailed
below should give you everything you need, especially C<context>.

=head1 EXPORTABLE

The following methods are exportable: C<context>, C<mount>, C<dispatch>,
C<config>, C<logger>, and C<database>. They can all be exported at once with
C<:all>.

=head1 METHODS

By default this package exports nothing. But that makes it difficult to use.
You should probably export C<:all>. That will give you quick access to these
methods.

=over 4

=item config

Passes through to C<Prancer::config>. This is made available for your
application.

=item logger

Passes through to C<Prancer::logger>. This is made available for your
application.

=item database

Passes through to C<Prancer::database>. This is made available for your
application.

=item context

This gives access to the request context. See L<Prancer::Context> for more
information about what that makes available. But here is a short example:

    context->header(set => 'Content-Type', value => 'text/plain');
    context->body("hello world");
    context->finalize(200);

=item mount METHOD, PATH, SUB

This adds a routed path. Prancer uses L<Router::Boom::Method> to handle
routing. If it is not installed then calls to this method will croak. The first
argument will always be the method or methods that should match. For example:

    mount('GET', ..., ...);
    mount(['GET','POST'], ..., ...);

The second argument should be the path that will match. For example:

    mount(..., '/', ...);
    mount(..., '/:user', ...);
    mount(..., '/blog/{year}', ...);
    mount(..., '/blog/{year}/{month:\d+}', ...);
    mount(..., '/download/*', ...);

The last argument should be a sub that will run on a successful match. For
example:

    mount(..., ..., sub {
        my $captured = shift;

        context->header(set => 'Content-Type', value => 'text/plain');
        context->body("hello world");
        context->finalize(200);
    });

Of course the sub doesn't have to be anonymous and could point to anything. The
only argument that gets passed to a sub is a hashref containing what, if
anything, was captured in the route. For example:

    mount(..., '/', sub {
        my $captured = shift;
        # captured = {}
    });

    # :user matches qr{([^/]+)}
    mount(..., '/:user', sub {
        my $captured = shift;
        print $captured->{'user'};
    });

    # {year} matches qr{([^/]+)}
    mount(..., '/blog/{year}/{month:\d+}', sub {
        my $captured = shift;
        print $captured->{'year'};
        print $captured->{'month'};
    });

    # * matches qr{(.+)}
    mount(..., '/download/*', sub {
        my $captured = shift;
        print $captured->{'*'};
    });

Further documentation on how to use routes can be found by reading the docs
for L<Router::Boom> and L<Router::Boom::Method>.

=item dispatch

This should be called at the end of your implementation to C<handle>. It will
run the configured routes and return a valid PSGI response to the application
server. If you do not have L<Router::Boom> installed then calling this method
will croak. If you are not using L<Router::Boom> then you should not use this
method but should instead have your implementation of C<handle> return a valid
PSGI response.

=back

=cut
