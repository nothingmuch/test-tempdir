#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	use File::Spec;
	plan skip_all => "No writable temp dir" unless grep { -d && -w } File::Spec->tmpdir;
	plan 'no_plan';
}

use ok 'Test::TempDir' => qw(temp_root scratch tempfile);

isa_ok( my $root = temp_root, "Path::Class::Dir" );

ok( -d $root, "root exists" );

ok( my ( $fh, $file ) = tempfile(), "tempfile" );

ok( $fh, "file handle returned" );
ok( $file, "file name returned" );

ok( ref($fh), "filehandle is a ref" );
ok( eval { fileno($fh) }, "file opened" );
ok( (print $fh "bar"), "writable" );;

ok( !ref($file), "file name is not a ref" );
ok( -f $file, "file exists" );

ok( $root->contains($file), "root contains file" );

SKIP: {
	skip "no Directory::Scratch", 2 unless eval { require Directory::Scratch };

	isa_ok( my $s = scratch(), "Directory::Scratch" );

	ok( $root->contains($s->base), "root contains scratch dir" );
}

