#!/usr/bin/perl

package Test::TempDir;

use strict;
use warnings;

our $VERSION = "0.01";

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

Test::TempDir - Temporary files support for testing.

=head1 SYNOPSIS

	use Test::TempDir;

	my $test_tempdir = temp_root();

	my ( $fh, $file ) = tempfile();

	my $directory_scratch_obj = scratch();

=head1 DESCRIPTION

Test::TempDir provides temporary directory creation with testing in mind.

The differences between using this and using L<File::Temp> are:

=over 4

=item *

If C<t/tmp> is available (writable, creatable, etc) it's preferred over
C<$ENV{TMPDIR}> etc. Otherwise a temporary directory will be used.

This is C<temp_root>

=item *

Lockfiles are used on C<t/tmp>, to prevent race conditions when running under a
parallel test harness.

=item *

The C<temp_root> is cleaned at the end of a test run, but not if tests failed.

=item *

C<temp_root> is emptied at the begining of a test run unconditionally.

=item *

The default policy is not to clean the individual C<tempfiles> and C<tempdirs>
within C<temp_root>, in order to aid in debugging of failed tests.

=back

=head1 EXPORTS

=over 4

=item temp_root

The root of the temporary stuff.

=item tempfile

=item tempdir

Wrappers for the L<File::Temp> functions of the same name.

The default options are changed to use C<temp_root> for C<DIR> and disable
C<CLEANUP>, but these are overridable.

=item scrach

Loads L<Directory::Scratch> and instantiates a new one, with the same default
options as C<tempfile> and C<tempdir>.

=back

=head1 SEE ALSO

L<File::Temp>, L<Directory::Scratch>, L<Path::Class>

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
