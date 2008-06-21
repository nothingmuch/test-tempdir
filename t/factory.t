#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Path::Class;
use File::Temp qw(tempdir);

use ok 'Test::TempDir::Factory';

my $tmp = dir( tempdir( CLEANUP => 1 ) );

delete @ENV{qw(TEST_TEMPDIR TEST_TMPDIR)};

my $f = Test::TempDir::Factory->new;

isa_ok( $f, "Test::TempDir::Factory" );

is( $f->dir_name, dir("tmp"), "default dir_name" );
is( $f->t_dir, dir("t"), "default t_dir" );

$f->t_dir($tmp);

my $subdir = $tmp->subdir($f->dir_name);

is( $f->base_path, $subdir, "base path" );

ok( not(-d $f->base_path), "base path doesn't exist yet" );

ok( !$f->use_subdir, "subdirs disabled" );

my ( $path, $lock ) = $f->create_and_lock($f->base_path);

isa_ok( $path, "Path::Class::Dir" );

is( $path, $subdir, "preferred path used" );

ok( -d $path, "created" );

isa_ok( $lock, "File::NFSLock", "lock" );

my ( $fallback_path, $fallback_lock ) = $f->create_and_lock_fallback($f->base_path);

isa_ok( $fallback_path, "Path::Class::Dir" );

isnt( $fallback_path, $path, "fallback path is different" );

isa_ok( $fallback_lock, "File::NFSLock" );

{
	$f->lock(0);

	my ( $new_fb ) = $f->create_and_lock_fallback($f->base_path);

	isnt( $new_fb, $path, "second fallback is different from base path" );
	isnt( $new_fb, $fallback_path, "and from first fallback path" );

	rmdir $new_fb;
}


$f->lock(1);

isa_ok( my $dir = $f->create, "Test::TempDir::Handle" );

is( $dir->dir, $path, "dir created" );

isa_ok( $dir->lock, "File::NFSLock" );

SKIP: {
	my $lockfile = $dir->lock->{lock_file} or skip "no lockfile", 2;

	ok( -f $lockfile, "lockfile exists" );

	$dir->empty;

	ok( -f $lockfile, "lockfile exists after ->empty" );
}

rmdir $fallback_path;


