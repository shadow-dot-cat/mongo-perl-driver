#  Copyright 2014 - present MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;
use Test::More;
use MongoDBTest::Deps;
use Data::Dumper;

ok(my $mongodb_deps = MongoDBTest::Deps->new, 'got deps manager object');

subtest 'main deps' => sub {
    like( my $main_cpanfile = $mongodb_deps->mymeta_cpanfile, qr{^/tmp},
          'got main cpanfile' );
    ok( -r $main_cpanfile, 'main cpanfile exists' );

    my @deep_xs = $mongodb_deps->has_deep_xs($main_cpanfile);
    ok(! scalar @deep_xs, 'check deep xs deps' )
        or warn Dumper(\@deep_xs);
};

subtest 'devel deps' => sub {
    like(my $devel_cpanfile = $mongodb_deps->devel_cpanfile, qr{/devel},
         'got devel cpanfile');
    ok( -r $devel_cpanfile, 'devel cpanfile exists' );

    my @deep_xs = $mongodb_deps->has_deep_xs($devel_cpanfile);
    ok(! scalar @deep_xs, 'check deep xs deps' )
        or warn Dumper(\@deep_xs);
};

done_testing;
