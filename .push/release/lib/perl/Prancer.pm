package Prancer;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = "0.02";

use Exporter;
use parent qw(Exporter);

our @EXPORT_OK = qw(config logger template database);
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);

use Carp;
use Module::Load ();
use Storable qw(dclone);
use Try::Tiny;

use Prancer::Config;
use Prancer::Logger;
use Prancer::Request;
use Prancer::Response;
use Prancer::Session;
use Prancer::Context;

sub new {
    my ($class, $config_path, $handler, @args) = @_;

    # already got an object
    return $class if ref($class);

    # this is a singleton
    my $instance = undef;
    {
        no strict 'refs';
        $instance = \${"$class\::_instance"};
        return $$instance if defined($$instance);
    }

    my $self = bless({
        '_handler' => $handler,    # the name of the class that will implement the handler
        '_handler_args' => \@args, # any arguments that should be passed to the handler on creation
    }, $class);

    # load configuration
    $self->{'_config'} = Prancer::Config->load($config_path);

    # load the configured logger
    $self->{'_logger'} = Prancer::Logger->load($self->{'_config'}->remove('logger'));

    $$instance = $self;
    return $self;
}

# return an already created instance of ourselves or croak if one doesn't exist
sub instance {
    my $class = __PACKAGE__;

    {
        no strict 'refs';
        my $instance = \${"$class\::_instance"};
        return $$instance if defined($$instance);
    }

    croak "must create an instance of " . __PACKAGE__ . " before it may be used";
}

sub logger {
    my $self = instance();
    return $self->{'_logger'};
}

sub config {
    my $self = instance();
    return $self->{'_config'};
}

sub template {
    my $self = instance();

    # if the template object hasn't been initialized do it now
    # this will make this work well with CLI apps
    require Prancer::Template;
    $self->{'_template'} = Prancer::Template->load(config->remove('template')) unless defined($self->{'_template'});

    return $self->{'_template'}->render(@_);
}

sub database {
    my $self = instance();
    my $connection = shift || "default";

    # if the database object hasn't been initialized do it now
    # this will make this work well with CLI apps
    require Prancer::Database;
    $self->{'_database'} = Prancer::Database->load(config->remove('database')) unless defined($self->{'_database'});

    if (!defined($connection)) {
        logger->fatal("could not get connection to database: no connection name given");
        croak;
    }
    if (!exists($self->{'_database'}->{$connection})) {
        logger->fatal("could not get connection to database: no connection named '${connection}'");
        croak;
    }

    return $self->{'_database'}->{$connection}->handle();
}

sub run {
    my $self = shift;

    try {
        Module::Load::load($self->{'_handler'});
    } catch {
        logger->fatal("could not initialize handler: " . (defined($_) ? $_ : "unknown"));
        croak;
    };

    # pre-load the template engine
    require Prancer::Template;
    $self->{'_template'} = Prancer::Template->load(config->remove('template'));

    # pre-load the database engine
    require Prancer::Database;
    $self->{'_database'} = Prancer::Database->load(config->remove('database'));

    my $app = sub {
        my $env = shift;

        # create a context to pass to the request
        my $context = Prancer::Context->new(
            'env'      => $env,
            'request'  => Prancer::Request->new($env),
            'response' => Prancer::Response->new($env),
            'session'  => Prancer::Session->new($env),
        );

        my $handler = $self->{'_handler'};
        my $copy = $handler->new($context, @{$self->{'_handler_args'}});
        return $copy->handle($env);
    };

    # capture warnings and logging messages and send them to the configured logger
    require Prancer::Middleware::Logger;
    $app = Prancer::Middleware::Logger->wrap($app);

    # enable user sessions
    $app = $self->_enable_sessions($app);

    # serve up static files if configured to do so
    $app = $self->_enable_static($app);

    return $app;
}

sub _enable_sessions {
    my ($self, $app) = @_;

    my $config = config->remove('session');
    if ($config) {
        try {
            # load the session state module first
            # this will probably be a cookie
            my $state_module = undef;
            my $state_options = undef;
            if (ref($config->{'state'}) && ref($config->{'state'}) eq "HASH") {
                $state_module = $config->{'state'}->{'driver'};
                $state_options = $config->{'state'}->{'options'};
            }

            # set defaults and then load the state module
            $state_options ||= {};
            $state_module ||= "Prancer::Session::State::Cookie";
            Module::Load::load($state_module);

            # set the default for the session name because the plack
            # default is stupid
            $state_options->{'session_key'} ||= "PSESSION";

            # load the store module second
            my $store_module = undef;
            my $store_options = undef;
            if (ref($config->{'store'}) && ref($config->{'store'}) eq "HASH") {
                $store_module = $config->{'store'}->{'driver'};
                $store_options = $config->{'store'}->{'options'};
            }

            # set defaults and then load the store module
            $store_options ||= {};
            $store_module ||= "Prancer::Session::Store::Memory";
            Module::Load::load($store_module);

            require Plack::Middleware::Session;
            $app = Plack::Middleware::Session->wrap($app,
                'state' => $state_module->new($state_options),
                'store' => $store_module->new($store_options),
            );
            logger->info("initialized session handler with state module ${state_module} and store module ${store_module}");
        } catch {
            my $error = (defined($_) ? $_ : "unknonw");
            logger->warn("could not initialize session handler: initialization error: ${error}");
        };
    } else {
        logger->warn("could not initialize session handler: no session handler configured");
    }

    return $app;
}

sub _enable_static {
    my ($self, $app) = @_;

    my $config = config->remove('static');
    if ($config) {
        try {
            # this intercepts requests for /static/* and checks to see if
            # the requested file exists in the configured path. if it does
            # it is served up. if it doesn't then the request will pass
            # through to the handler.
            die "no path is configured\n" unless defined($config->{'path'});
            my $path = Cwd::realpath($config->{'path'});
            die "${path} does not exist\n" unless (-e $path);
            die "${path} is not readable\n" unless (-r $path);

            require Plack::Middleware::Static;
            $app = Plack::Middleware::Static->wrap($app,
                'path' => sub { s!^/static/!!x },
                'root' => $path,
                'pass_through' => 1,
            );
            logger->info("serving static files from ${path} at /static");
        } catch {
            logger->warn("could not initialize static file loader: initialization error: $_");
        };
    } else {
        logger->warn("could not initialize static file loader: not configured");
    }

    return $app;
}

1;

=head1 NAME

Prancer - Another PSGI Framework

=head1 SYNOPSIS

Prancer is yet another PSGI framework. This one is designed to be a bit smaller
and more out of the way than others but it could probably be described best as
project derived from L<NIH syndrome|https://en.wikipedia.org/wiki/Not_Invented_Here>.

Here's how it might be used:

    ==> myapp.psgi

    use Prancer;
    my $app = Prancer->new("/path/to/confdir", "MyApp");
    $app->run();

    ==> MyApp.pm

    package MyApp;

    use Prancer::Application qw(:all);
    use parent qw(Prancer::Application);

    sub handle {
        my $self = shift;

        mount('GET', '/', sub {
            context->header(set => 'Content-Type', value => 'text/plain');
            context->body("hello world");
            context->finalize(200);
        });

        return dispatch;
    }

Full documentation can be found in L<Prancer::Manual>.

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

If this ever makes it to CPAN you can install it with this simple command:

    perl -MCPAN -e 'install Prancer'

These optional libraries will enhance the functionality of Prancer:

=over 4

=item L<Template>

Without this the Prancer template interface will not work.

=item L<DBI>

Without this the Prancer database interface will not work. You also will need
a database driver like L<DBD::Pg>.

=item L<Plack::Middleware::Session>

Without this the Prancer session support will not work. If you want to use the
YAML session storage you will also need to have L<YAML> (preferably
L<YAML::XS>) installed. If you want support to write sessions do the database
you will also need L<DBI> installed along with a database driver like
L<DBD::Pg>.

=back

=head1 EXPORTABLE

The following methods are exportable: C<config>, C<logger>, C<database>,
C<template>. They can all be exported at once using C<:all>.

=head1 METHODS

With the exception of C<-E<gt>new> and C<-E<gt>run>, all methods should be
called in a static context. Additionally, with the same exception, all methods
are exportable individually or with C<qw(:all)>.

=over 4

=item ->new CONFIG PACKAGE ARGS

This will create your application. It takes two arguments:

=over 4

=item CONFIG

This a path to a directory containing configuration files. How configuration
files are loaded is detailed below.

=item PACKAGE

This is the name of a package that implements your application. The package
named should extend L<Prancer::Application> though this is not enforced.

=item ARGS

After the name of the package, any number of arguments may be added. Any extra
arguments are passed directly to the C<new> method on the named package when it
is created for a request.

=back

=item ->run

This starts your application. It takes no arguments.

=item logger

This gives access to the logger. For example:

    logger->info("Hello");
    logger->fatal("uh oh");
    logger->debug("here we are");

=item config

This gives access to the configuration. For example:

    config->has('foo');
    config->get('foo');
    config->set('foo', value => 'bar');
    config->remove('foo');

Any changes to the configuration do not persist back to the actual
configuration file. Additionally they do not persist between threads or
processes.

Whenever this method is used to get a configuration option and that option
is reference, the reference will be cloned by Storable to prevent changes to
one copy from affecting other uses. But this could have performance
implications if you are routinely getting large data structures out if your
configuration files.

=item template

This gives access to the configured template engine. For example:

    print template("foo.tt", {
        'title' => 'foobar',
        'var1' => 'val2',
    });

If no template engines are configured then this method will always return
C<undef>.

=item database

This gives access to the configured databases. For example:

    # handle to the database configured as 'default'
    my $dbh = database;

    # handle to the database configured as 'foo'
    my $dbh = database('foo');

    # prepare a statement on connection 'default'
    my $sth = database->prepare("SELECT * FROM foo");

In all cases, C<$dbh> will be a reference to a L<DBI> handle and anything that
can be done with L<DBI> can be done here.

If no databases are configured then this method will always return C<undef>.

=item session

Configures the session handler. For example:

    session:
        state:
            driver: Prancer::Session::State::Cookie
            options:
                key: PSESSION
        store:
            driver: Prancer::Session::Store::YAML
            options:
                path: /tmp/prancer/sessions

See L<Prancer::Session::State::Cookie>, L<Prancer::Session::Store::Memory>,
L<Prancer::Session::Store::YAML> and L<Prancer::Session::Store::Database> for
more options.

=back

=head1 CONFIGURATION

One doesn't need to create any configuration to use Prancer but then Prancer
wouldn't be very useful. Prancer uses L<Config::Any> to process configuration
files so anything supported by that will be supported by this. It will load
configuration files from given path set when your application initialized.
First it will look for a file named C<config.ext> where C<ext> is something
like C<yml> or C<ini>. Then it will look for a file named after the current
environment like C<develoment.ext> or C<production.ext>. The environment is
derived by looking first for an environment variable called C<ENVIRONMENT>,
then for an environment variable called C<PLACK_ENV>. If neither of those exist
then the default is C<development>. Configuration files will be merged such
that the environment configuration file will take precedence over the global
configuration file.

Arbitrary configuration directives can be put into your configuration files
and they can be accessed like this:

    config(get => 'foo');

The configuration accessors will only give you configuration directives found
at the root of the configuration file. So if you use any data structures you
will have to decode them yourself. For example, if you create a YAML file like
this:

    foo:
        bar1: asdf
        bar2: fdsa

Then you will only be able to get the value to C<bar1> like this:

    my $foo = config(get => 'foo')->{'bar1'};

=head2 Reserved Configuration Options

To support the components of Prancer, these keys are used:

=over 4

=item logger

Configures the logging system. For example:

    logger:
        driver: Prancer::Logger::WhateverLogger
        options:
            level: debug

For the console logger, see L<Prancer::Logger::Console> for more options.

=item template

Configures the templating system. For example:

    template:
        driver: Prancer::Template::WhateverEngine
        options:
            template_dir: /srv/www/site/templates
            encoding: utf8
            start_tag: "<%"
            end_tag: "%>"

For the Template Toolkit plugin, see L<Prancer::Template::TemplateToolkit> for
more options.

=item database

Configures database connections. For example:

    database:
        default:
            driver: Prancer::Database::Driver::WhateverDriver
            options:
                username: test
                password: test
                database: test

See L<Prancer::Database> for more options.

=item static

Configures a directory where static documents can be found and served using
L<Plack::Middleware::Static>. For example:

    static:
        path: /srv/www/site/static

The only configuration option for static documents is C<path>. If this path
is not defined your application will not start. If this path does not point
to a directory that is readable your application will not start.

=back

=head1 CREDITS

Large portions of this library were taken from the following locations and
projects:

=over 4

=item

HTTP status code documentation taken from L<Wikipedia|http://www.wikipedia.org>.

=item

L<Prancer::Config> is derived directly from L<Dancer2::Core::Role::Config>.
Thank you to the L<Dancer2|https://github.com/PerlDancer/Dancer2> team.

=item

L<Prancer::Request>, L<Prancer::Request::Upload> and L<Prancer::Response> are
but thin wrappers to and reimplementations of L<Plack::Request>,
L<Plack::Request::Upload> and L<Prancer::Response>. Thank you to Tatsuhiko
Miyagawa.

=item

L<Prancer::Database> is derived directly from L<Dancer::Plugin::Database>.
Thank you to David Precious.

=back

=head1 COPYRIGHT

Copyright 2013, 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
