#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Test::TempDir',
	VERSION_FROM => 'lib/Test/TempDir.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'File::Path' => 0,
		'File::Spec' => 0,
		'File::Temp' => 0,
		'File::NFSLock' => 0,
		'Moose' => '0.50',
		'MooseX::Types::Path::Class' => 0,
		'Path::Class' => 0,
		'Sub::Exporter' => 0,
		'namespace::clean' => "0.08",
	},
);

