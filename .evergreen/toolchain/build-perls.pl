#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use Cwd 'getcwd';
use File::Path qw/mkpath rmtree/;

# helper subroutine

sub try_system {
    my @command = @_;
    say "\nRunning: @command\n";
    system(@command) and die "Aborting: '@command' failed";
}

# constants

my $orig_dir      = getcwd();
my $root          = "opt";
my $prefix_prefix = "/$root/perl";
my $destdir       = "$orig_dir/build";
my @default_args  = ( '-j', 16, '-Doptimize=-g' );
my $tardir        = "$destdir/$root";

# define matrix of builds

my @perl_versions = qw(
  5.8.8
  5.10.1
  5.12.5
  5.14.4
  5.16.3
  5.18.4
  5.20.3
  5.22.2
  5.24.0
);

my %config_flags = (
    ''  => '',
    't' => '-Dusethreads',
    'ld' => '-Dusemorebits',
);

# configure local perl5 user directory
my $perl5lib = getcwd() . "/perl5";
my $cpanm    = "$perl5lib/bin/cpanm";
$ENV{PERL5LIB} = "$perl5lib/lib/perl5";
$ENV{PATH}     = "$perl5lib/bin:$ENV{PATH}";
mkpath "$perl5lib/$_" for qw{bin lib/perl5};

# get cpanm
try_system("curl -L https://cpanmin.us/ -o $cpanm");
chmod 0755, $cpanm;

# bootstrap perl-build into local 'perl5' library;
try_system( $cpanm, '-l', $perl5lib, "Perl::Build" );

# build all perls
for my $version (@perl_versions) {
    for my $config ( keys %config_flags ) {
        # prepare arguments
        ( my $short_ver = $version ) =~ s/^5\.//;
        my $dest = "$prefix_prefix/$short_ver$config";
        my @args = ( @default_args, $version, $dest );
        unshift @args, $config_flags{$config} if length $config_flags{$config};

        # run perl-build
        local $ENV{DESTDIR} = $destdir;
        try_system("perl-build @args >$short_ver$config.log 2>&1");

        # remove man dirs from $destdir$dest/...
        rmtree("$destdir$dest/man");

        # remove most pod files
        my $poddir = "$destdir$dest/lib/$version/pod";
        opendir my $dh, $poddir or die $!;
        my @files = grep { substr( $_, 0, 1 ) ne '.' } readdir($dh);
        for my $file (@files) {
            next if $file eq "perldiag.pod";
            my $fullpath = "$poddir/$file";
            unlink $fullpath or die "While deleting '$fullpath': $!";
        }
    }
}

# tar inside the destdir/opt
try_system("tar -czf perl.tar.gz -C $tardir perl");
