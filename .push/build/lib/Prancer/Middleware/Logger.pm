package Prancer::Middleware::Logger;

use strict;
use warnings FATAL => 'all';

use Plack::Middleware;
use parent qw(Plack::Middleware);

use Prancer qw(logger);

sub call {
    my ($self, $env) = @_;

    # set the logger to print to the configured prancer logger
    $env->{'psgix.logger'} = sub {
        my $args = shift;
        my $level = $args->{'level'};
        logger->$level($args->{'message'});
    };

    # now set warnings to go to the log
    local $SIG{__WARN__} = sub {
        for (@_) {
            $env->{'psgix.logger'}->({
                'level' => 'warn',
                'message' => $_,
            });
        }
    };

    return $self->app->($env);
}

1;

=head1 NAME

Prancer::Middleware::Logger

=head1 DESCRIPTION

This middleware ties C<psgix.logger> to the configured logger in your Prancer
application. It also redirects any warnings from your application to the same
configured logger. There is no configuration specifically for this middleware.

=cut
