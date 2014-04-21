#Prancer
Another PSGI Framework

#Synopsis

Prancer is yet another PSGI framework. This one is designed to be a bit smaller
and more out of the way than others but it could probably be described best as 
project derived from NIH syndrome.

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

    ==> mytool.pl

    use Prancer qw(:all);

    Prancer->new("/path/to/confdir");
    my $foo = config->get("foo");
    config->set("foo", "bar");

Using various plugins, Prancer can also integrate into your application:

* logging
* templates
* sessions
* environment-aware configuration files
* static files


#Installation

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

To install from CPAN you can run this simple command:

    perl -MCPAN -e 'install Prancer'

These optional libraries will enhance the functionality of Prancer:

    DBI
    Template

#Credits

Large portions of this library were taken from the following locations and
projects:

- HTTP status code documentation taken from Wikipedia.
- Prancer::Config is derived directly from Dancer2::Core::Role::Config. Thank
  you to the Dancer2 team.
- Prancer::Request, Prancer::Request::Upload and Prancer::Response are but thin
  wrappers to and reimplementations of Plack::Request, Plack::Request::Upload
  and Prancer::Response. Thank you to Tatsuhiko Miyagawa.
- Prancer::Session and its components are but thin wrappers to and
  reimplementations of Plack::Middleware::Session. Thank you again to Tatsuhiko
  Miyagawa.
- Prancer::Database is derived directly from Dancer::Plugin::Database. Thank
  you to David Precious.

#Copyright

Copyright 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

