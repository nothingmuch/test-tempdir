#!/usr/bin/perl

package Test::TempDir;

use strict;
use warnings;

use File::Temp ();

use Test::TempDir::Factory;

use Sub::Exporter -setup => {
	exports => [qw(temp_root tempdir tempfile scratch)],
	groups => {
		default => [qw(temp_root tempdir tempfile)],
	},
};

our ( $factory, $dir );

sub _factory   { $factory ||= Test::TempDir::Factory->new }
sub _dir       { $dir     ||= _factory->create }

END { undef $dir; undef $factory };

sub temp_root () { _dir->dir }

sub _temp_args { DIR => temp_root()->stringify, CLEANUP => 0 }
sub _template_args {
	if ( @_ % 2 == 0 ) {
		return ( _temp_args, @_ );
	} else {
		return ( $_[0], _temp_args, @_[1 .. $#_] );
	}
}

sub tempdir { File::Temp::tempdir( _optional_template_args(@_) ) }

sub tempfile { File::Temp::tempfile( _template_args(@_) ) }

sub scratch {
	require Directory::Scratch;
	Directory::Scratch->new( _temp_args, @_ );
}


__PACKAGE__

__END__

=pod

=head1 NAME

Test::TempDir - 

=head1 SYNOPSIS

	use Test::TempDir qw(tempdir tempfile scratch);

=head1 DESCRIPTION

=cut


