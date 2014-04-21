#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'prancer',
    'AUTHOR'        => 'Paul Lockaby <plockaby AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Prancer.pm',
    'PREREQ_PM'     => {
        'Plack'                      => '1.0029',
        'Plack::Middleware::Session' => '0.21',
        'Try::Tiny'                  => '0',
        'Config::Any'                => '0',
        'Hash::Merge::Simple'        => '0',
        'Hash::MultiValue'           => '0',
        'Module::Load'               => '0',
        'Router::Boom'               => '1.01',
        'URI'                        => '0',
        'YAML'                       => '0',
    },
    'INSTALLDIRS'   => (($] < 5.011) ? 'perl' : 'site'),

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);
