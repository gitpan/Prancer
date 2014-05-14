package Prancer::Request::Upload;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, $upload) = @_;
    return bless({ '_upload' => $upload }, $class);
}

sub filename {
    my $self = shift;
    return $self->{'_upload'}->filename();
}

sub size {
    my $self = shift;
    return $self->{'_upload'}->size();
}

sub path {
    my $self = shift;
    return $self->{'_upload'}->path();
}

sub content_type {
    my $self = shift;
    return $self->{'_upload'}->content_type();
}

sub basename {
    my $self = shift;

    unless (defined($self->{'_basename'})) {
        require File::Spec::Unix;
        my $basename = $self->{'_upload'}->path();
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
