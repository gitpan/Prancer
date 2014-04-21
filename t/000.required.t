#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Test::More;
use version;

my @modules = (
    { 'Plack'                      => '1.0029' },
    { 'Plack::Middleware::Session' => '0.21' },
    { 'Try::Tiny'                  => '0' },
    { 'Getopt::Long'               => '2.21' },
    { 'Parse::RecDescent'          => '1.965001' },
    { 'Config::Any'                => '0.19' },
    { 'Hash::Merge::Simple'        => '0.04' },
    { 'File::Basename'             => '0' },
    { 'File::Slurp'                => '0' },
    { 'Router::Boom'               => '1.01' },
);

for (@modules) {
    for my $module (keys %{$_}) {
        my $required_version = version->parse($_->{$module});

        # make sure we can load the module
        try {
            eval "require ${module}" or die;
            pass("successfully loaded ${module}");

            # make sure we have a required version
            my $actual_version = version->parse($module->VERSION);
            ok($actual_version >= $required_version, "${module} version check");
        } catch {
            fail("could not load ${module}");
        };
    }
}

done_testing();
