package Prancer::Session;

use strict;
use warnings FATAL => 'all';

use Storable qw(dclone);

sub new {
    my ($class, $env) = @_;
    my $self = bless({
        'env' => $env,
        '_session' => $env->{'psgix.session'},
        '_options' => $env->{'psgix.session.options'},
    }, $class);

    return $self;
}

sub id {
    my $self = shift;
    return $self->{'_options'}->{'id'};
}

sub has {
    my ($self, $key) = @_;
    return exists($self->{'_session'}->{$key});
}

sub get {
    my ($self, $key) = @_;

    # only return things if the are running in a non-void context
    if (defined(wantarray()) && defined($self->{'_session'}->{$key})) {
        # make a clone of the value to avoid inadvertently changing things
        # via references
        my $value = $self->{'_session'}->{$key};
        return dclone($value) if ref($value);
        return $value;
    }

    return;
}

sub set {
    my ($self, $key, $value) = @_;

    my $old = undef;
    $old = $self->get($key) if defined(wantarray());

    if (ref($value)) {
        # make a copy of the original value to avoid inadvertently changing
        # things via references
        $self->{'_session'}->{$key} = dclone($value);
    } else {
        # can't clone non-references
        $self->{'_session'}->{$key} = $value;
    }
    return $old;
}

sub remove {
    my ($self, $key) = @_;
    return delete($self->{'_session'}->{$key});
}

sub expire {
    my $self = shift;
    for my $key (keys %{$self->{'_session'}}) {
        delete($self->{'_session'}->{$key});
    }
    $self->{'_options'}->{'expire'} = 1;
    return;
}

sub as_hashref {
    my $self = shift;
    return $self->{'_session'};
}

1;

=head1 NAME

Prancer::Session

=head1 SYNOPSIS

This module should not be used directly to access a session. Instead, one
should use L<Prancer::Context>. For configuration options, please refer to the
documentation for the specific session state manager and session store manager
you wish to use.

=head1 SEE ALSO

=over 4

=item1 L<Prancer::Session::State::Cookie>
=item1 L<Prancer::Session::Store::Memory>
=item1 L<Prancer::Session::Store::YAML>
=item1 L<Prancer::Session::Store::Database>

=back

=cut
