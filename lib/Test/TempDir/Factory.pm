#!/usr/bin/perl

package Test::TempDir::Factory;
use Moose;

use Carp qw(croak carp);
use File::Spec;
use File::Temp;
use Path::Class;

use MooseX::Types::Path::Class qw(Dir);

use Test::TempDir::Handle;

use namespace::clean -except => [qw(meta)];

has lock => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has lock_opts => (
	isa => "HashRef",
	is  => "rw",
	default => sub { { lock_type => "NONBLOCKING" } },
);

has lock_attempts => (
	isa => "Int",
	is  => "rw",
	default => 2,
);

has dir_name => (
	isa => Dir,
	is  => "rw",
	coerce  => 1,
	default => sub { dir($ENV{TEST_TEMPDIR} || $ENV{TEST_TMPDIR} || "tmp") },
);

has cleanup_policy => (
	isa => "Str",
	is  => "rw",
	default => sub { $ENV{TEST_TEMPDIR_CLEANUP} || "success" },
);

has t_dir => (
	isa => Dir,
	is  => "rw",
	coerce  => 1,
	default => sub { dir("t") },
);

has options => (
	isa => "HashRef",
	is  => "rw",
	default => sub { {} },
);

has use_subdir => (
	isa => "Bool",
	is  => "rw",
	default => sub { $ENV{TEST_TEMPDIR_USE_SUBDIR} ? 1 : 0 },
);

has subdir_template => (
	isa => "Str",
	is  => "rw",
	default => File::Temp::TEMPXXX,
);

has handle_class => (
	isa => "ClassName",
	is  => "rw",
	default => "Test::TempDir::Handle",
	handles => { new_handle => "new" },
);

has verbose => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub create {
	my ( $self, @args ) = @_;

	my ( $path, $lock ) = $self->create_and_lock( $self->base_path(@args), @args );

	my $h = $self->new_handle(
		dir => $path,
		( defined($lock) ? ( lock => $lock ) : () ),
		cleanup_policy => $self->cleanup_policy,
		@args,
	);

	$h->empty;

	return $h;
}

sub create_and_lock {
	my ( $self, $preferred, @args ) = @_;

	if ( $self->use_subdir ) {
		$preferred = $self->make_subdir($preferred);
	} else {
		$preferred->mkpath unless -d $preferred;
	}

	unless ( $self->lock ) {
		return $preferred;
	} else {
		croak "When locking is enabled you must call create_and_lock in list context" unless wantarray;
		if ( my $lock = $self->try_lock($preferred) ) {
			return ( $preferred, $lock );
		}

		return $self->create_and_lock_fallback(@args);
	}
}

sub create_and_lock_fallback {
	my ( $self, @args ) = @_;

	my $base = $self->fallback_base_path;

	for ( 1 .. $self->lock_attempts ) {
		my $dir = $self->make_subdir($base);

		if ( $self->lock ) {
			if ( my $lock = $self->try_lock($dir) ) {
				return ( $dir, $lock );
			}

			rmdir $dir;
		} else {
			return $dir;
		}
	}

	croak "Unable to create locked tempdir";
}

sub try_lock {
	my ( $self, $path ) = @_;

	return 1 if !$self->lock;

	require File::NFSLock;
	File::NFSLock->new({
		file => $path->stringify . ".lock", # FIXME $path->file ? make sure it's not zapped by empty
		%{ $self->lock_opts },
	});
}

sub make_subdir {
	my ( $self, $dir ) = @_;
	$dir->mkpath unless -d $dir;
	dir( File::Temp::tempdir( $self->subdir_template, DIR => $dir->stringify ) );
}

sub base_path {
	my ( $self, @args ) = @_;

	my $dir = $self->dir_name;

	return $dir if -d $dir and -w $dir;

	my $t = $self->t_dir;

	if ( -d $t and -w $t ) {
		$dir = $t->subdir($dir);
		return $dir if -d $dir && -w $dir or not -e $dir;
	}

	$self->blurt("$t is not writable, using fallback");

	return $self->fallback_base_path(@args);
}

sub blurt {
	my ( $self, @blah ) = @_;
	if ( $self->can("logger") and my $logger = $self->logger ) {
		$logger->warn(@blah);
	} else {
		return unless $self->verbose;
		carp(@blah);
	}
}

sub fallback_base_path {
	return dir(File::Spec->tmpdir);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TempDir::Factory - A factory for creating L<Test::TempDir::Handle>
objects.

=head1 SYNOPSIS

	my $f = Test::TempDir::Factory->new;

	my $d = $f->create;

	$d->empty;

	# ...

	$d->cleanup

=head1 DESCRIPTION

This class creates L<Test::TempDir::Handle> objects with the right C<dir>
parameter, taking care of obtaining locks, creating directories, and handling
fallback logic.

=head1 ATTRIBUTES

=over 4

=item lock

Whether or not to enable locking.

Defaults to true.

=item lock_opts

A hash reference to pass to L<File::NFSLock>.

Defaults to C<NONBLOCKING>

=item lock_attempts

How many times to try to create and lock a dir.

Defaults to 2.

=item dir_name

The directory under C<t_dir> to use.

Defaults to C<tmp>

=item t_dir

Defaults to C<t>

=item use_subdir

Whether to always use a temporary subdirectory under the temporary root.

This means that with a C<success> cleanup policy all failures are retained.

When disabled, C<t/tmp> will be used directly as C<temp_root>.

Defaults to true.

=item subdir_template

The template to pass to C<tempdir>. Defaults to C<File::Temp::TEMPXXX>.

=item handle_class

Defaults to L<Test::TempDir::Handle>.

=item verbose

Whether or not to C<carp> diagnostics when falling back.

If you subclass this factory and add a C<logger> method a la L<MooseX::Logger>
then this parameter is ignored and all messages will be C<warn>ed on the
logger.

=back

=head1 METHODS

=over 4

=item create

Create a L<Test::TempDir::Handle> object with a proper C<dir> attribute.

=back

=cut
