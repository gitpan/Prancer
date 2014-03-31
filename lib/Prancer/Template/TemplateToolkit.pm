package Prancer::Template::TemplateToolkit;

use strict;
use warnings FATAL => 'all';

use Carp;
use Cwd ();
use Try::Tiny;
use Prancer qw(logger);

sub new {
    my ($class, $config) = @_;
    my $self = bless({}, $class);

    # try to load template toolkit
    try {
        require Template;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->fatal("could not load Template: ${error}");
        croak;
    };

    die "no template path is configured\n" unless defined($config->{'template_dir'});
    my $include_path = Cwd::realpath($config->{'template_dir'});
    die "${include_path} does not exist\n" unless (-e $include_path);
    die "${include_path} is not readable\n" unless (-r $include_path);

    my $cache_path = (defined($config->{'cache_dir'}) ? Cwd::realpath($config->{'cache_dir'}) : undef);
    if (defined($cache_path)) {
        die "${cache_path} does not exist\n" unless (-e $cache_path);
        die "${cache_path} is not readable\n" unless (-r $cache_path);
        die "${cache_path} is not writable\n" unless (-w $cache_path);
    }

    my $engine = Template->new({
        'INCLUDE_PATH' => $include_path,
        'ANYCASE'      => 1,
        'START_TAG'    => $config->{'start_tag'} || '<%',
        'END_TAG'      => $config->{'end_tag'} || '%>',
        'ENCODING'     => $config->{'encoding'} || 'utf8',
        'PRE_PROCESS'  => $config->{'pre_process'},
        'POST_PROCESS' => $config->{'post_process'},
        'CACHE_SIZE'   => $config->{'cache_size'},
        'COMPILE_EXT'  => 'ttc',
        'COMPILE_DIR'  => $cache_path,
    });
    $self->{'_engine'} = $engine;

    logger->info("initialized template engine with templates from ${include_path}");
    logger->info("templates will be cached to ${cache_path}") if ($cache_path);

    return $self;
}

sub render {
    my ($self, $input, $vars) = @_;
    my $output = undef;

    try {
        $self->{'_engine'}->process($input, $vars, \$output) or croak $self->{'_engine'}->error();
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        logger->error("could not render template: ${error}");
    };

    return defined($output) ? $output : '';
}

1;

=head1 NAME

Prancer::Template::TemplateToolkit

=head1 SYNOPSIS

This template engine plugin requires L<Template>. If this plugin is configured
but L<Template> is not found your application will not start. To use this
template engine plugin, set your configuration to something like this:

    template:
        driver: Prancer::Template::TemplateToolkit
        options:
            template_dir: /srv/www/site/templates
            encoding: utf8
            start_tag: "<%"
            end_tag: "%>"

Then your templates should be placed under C</srv/www/site/templates> as
configured.

=head1 OPTIONS

=over 4

=item template_dir

B<REQUIRED> Sets the directory to look for templates. If this path is not
configured then your application will not start.

=item start_tag

Sets the start tag for your templates. The default is C<E<lt>%>.

=item end_tag

Sets the end tag for your templates. The default is C<%E<gt>>.

=item encoding

Sets the encoding of your templates. The default is C<utf8>.

=item pre_process

Names a template to add to the top of all templates.

=item post_process

Names a template to be added to the bottom of all templates.

=item cache_size

Sets the number of templates to cache. The default is cache all of them if the
cache is enabled.

=item cache_dir

Sets the directory to cache templates. The default is to not cache templates.

=back

=cut
