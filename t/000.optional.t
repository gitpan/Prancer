#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Test::More;
use version;

my @modules = (
    { 'Template'                   => '0' },
    { 'DBI'                        => '0' },
    { 'DBD::Pg'                    => '0' },
    { 'Plack::Middleware::Session' => '0.21' },
);

for (@modules) {
    for my $module (keys %{$_}) {
        my $required_version = version->parse($_->{$module});

        SKIP: {
            eval "require $module" or skip("optional module ${module} not installed", 2);
            pass("successfully loaded ${module}");

            # make sure we have a required version
            my $actual_version = version->parse($module->VERSION);
            ($actual_version >= $required_version) or skip("version ${required_version} of optional module ${module} required but only found ${actual_version}", 2);
            ok($actual_version >= $required_version, "${module} version check");
        }
    }
}

done_testing();
