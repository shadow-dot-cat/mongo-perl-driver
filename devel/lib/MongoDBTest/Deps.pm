#  Copyright 2018 - present MongoDB, Inc.
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

use 5.010;
use strict;
use warnings;

package MongoDBTest::Deps;

use Moo;
use Types::Standard -types;
use namespace::clean;
use Module::CPANfile;
use CPAN::Meta;
use File::Temp ();
use Cwd ();
use Carton::CLI;

has _tmp_file => (
    is => 'ro', lazy => 1,
    builder => '_build_tmp_file',
);

sub _build_tmp_file { return File::Temp->new( UNLINK => 1 ) }

sub _get_mymeta {
    my ($self) = @_;
    my $file = 'MYMETA.json';
    return unless -r $file;
    my $meta = CPAN::Meta->load_file('MYMETA.json');
    return $meta if $meta;
}

sub _find_all_prereqs {
    my ($self, $meta) = @_;
    my $prereqs = $meta->effective_prereqs;
    my $phases = [qw/runtime build configure test/];
    return {
        runtime => {
            requires => $prereqs->merged_requirements($phases)->as_string_hash
        },
    };
}

sub mymeta_cpanfile {
    my ($self) = @_;
    my $meta = $self->_get_mymeta or die "Could not locate any META files\n";
    my $cpanfile = Module::CPANfile->from_prereqs( $self->_find_all_prereqs($meta) );
    my $tmpfile = $self->_tmp_file;
    print $tmpfile $cpanfile->to_string;
    return $tmpfile->filename;
}

sub has_deep_xs {
    my ($self, $cpanfile) = @_;
    my $install_path = Cwd::getcwd() . '/devel/local-lib';
    my $carton = Carton::CLI->new;
    $carton->run(
        'install',
        '--cpanfile', $cpanfile,
        '--path', $install_path
    );
    my $env = Carton::Environment->build($cpanfile, $install_path);
    $env->snapshot->load;
    my @deep_xs;
    foreach my $dist ($env->snapshot->distributions) {
        push @deep_xs, $dist->distfile
            if $dist->distfile =~ /XS/;
    }
    return grep { $_ !~ /MaybeXS/ } @deep_xs;
}

1;
