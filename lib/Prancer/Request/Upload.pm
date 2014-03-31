package Prancer::Request::Upload;

use strict;
use warnings FATAL => 'all';

sub new {
    my $class = shift;
    my %args = @_;

    return bless({
        '_headers'  => $args{'headers'},
        '_tempname' => $args{'tempname'},
        '_size'     => $args{'size'},
        '_filename' => $args{'filename'},
    }, $class);
}

sub filename {
    my $self = shift;
    return $self->{'_filename'};
}

sub headers {
    my $self = shift;
    return $self->{'_headers'};
}

sub size {
    my $self = shift;
    return $self->{'_size'};
}

sub tempname {
    my $self = shift;
    return $self->{'_tempname'};
}

sub path {
    my $self = shift;
    return $self->{'_tempname'};
}

sub content_type {
    my $self = shift;
    return $self->{'_headers'}->content_type(@_);
}

sub basename {
    my $self = shift;

    unless (defined($self->{'_basename'})) {
        require File::Spec::Unix;
        my $basename = $self->{'_filename'};
        $basename =~ s|\\|/|gx;
        $basename = (File::Spec::Unix->splitpath($basename))[2];
        $basename =~ s|[^\w\.-]+|_|gx;
        $self->{'_basename'} = $basename;
    }

    return $self->{'_basename'};
}

1;

=head1 NAME

Prancer::Request::Upload

=head1 SYNOPSIS

Uploads come from the L<Prancer::Request> object passed to your handler. They
can be used like this:

    # in your HTML
    <form method="POST" enctype="multipart/form-data">
        <input type="file" name="foobar" />
    </form>

    # in the Prancer handler
    my $upload = context->upload('foo');
    my $upload = context->request->upload('bar');
    $upload->size();
    $upload->path();
    $upload->content_type();
    $upload->filename();
    $upload->basename();

=head1 ATTRIBUTES

=over 4

=item size

Returns the size of uploaded file.

=item path

Returns the path to the temporary file where uploaded file is saved.

=item content_type

Returns the content type of the uploaded file.

=item filename

Returns the original filename in the client.

=item basename

Returns basename for "filename".

=back

=cut
