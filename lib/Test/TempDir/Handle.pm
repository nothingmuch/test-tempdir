#!/usr/bin/perl

package Test::TempDir::Handle;
use Moose;

use MooseX::Types::Path::Class qw(Dir);
use Moose::Util::TypeConstraints;

use namespace::clean -except => [qw(meta)];

has dir => (
	isa => Dir,
	is  => "ro",
	handles => [qw(file subdir rmtree)],
);

has lock => (
	isa => "File::NFSLock",
	is  => "ro",
	predicate => "has_lock",
	clearer   => "clear_lock",
);

has cleanup_policy => (
	isa => enum( __PACKAGE__ . "::CleanupPolicy", qw(success always never) ),
	is  => "rw",
	default => "success",
);

has test_builder => (
	isa => "Test::Builder",
	is  => "rw",
	lazy_build => 1,
	handles => { test_summary => "summary" },
);

sub _build_test_builder {
	require Test::Builder;
	Test::Builder->new;
}

sub failing_tests {
	my $self = shift;
	grep { !$_ } $self->test_summary;
}

sub empty {
	my $self = shift;
	return unless -d $self->dir;
	$self->rmtree({ keep_root => 1 });
}

sub delete {
	my $self = shift;
	return unless -d $self->dir;
	$self->rmtree({ keep_root => 0 });
	$self->dir->parent->remove; # rmdir, safe, and we don't care about errors
}

sub release_lock {
	my $self = shift;

	$self->clear_lock;

	# FIXME always unlock? or allow people to keep the locks around by enrefing them?

	#if ( $self->has_lock ) {
	#	$self->lock->unlock;
	#	$self->clear_lock;
	#}
}

sub DEMOLISH {
	my $self = shift;
	$self->cleanup;
}

sub cleanup {
	my ( $self, @args ) = @_;

	$self->release_lock;

	my $policy = "cleanup_policy_" . $self->cleanup_policy;

	$self->can($policy) or die "Unknown cleanup policy " . $self->cleanup_policy;

	$self->$policy(@args);
}

sub cleanup_policy_never {}

sub cleanup_policy_always {
	my ( $self, @args ) = @_;

	$self->delete;
}

sub cleanup_policy_success {
	my ( $self, @args ) = @_;

	if ( $self->failing_tests ) {
		$self->test_builder->diag("Leaving temporary directory '" . $self->dir . "' due to test fails");
	} else {
		$self->cleanup_policy_always(@args);
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TempDir::Handle - A handle for managing a temporary directory root.

=head1 SYNOPSIS

	use Test::TempDir::Handle;

	my $h = Test::TempDir::Handle->new( dir => dir("t/tmp") );

	$h->empty;

	# ...

	$h->cleanup; # will delete on success by default

=head1 DESCRIPTION

This class manages a temporary directory.

=head1 ATTRIBUTES

=over 4

=item dir

The L<Path::Class::Dir> that is being managed.

=item lock

An optional lock object (L<File::NFSLock>). Just kept around for reference counting.

=item cleanup_policy

One of C<success>, C<always> or C<never>.

C<success> means that C<cleanup> deletes only if C<test_builder> says the tests
have passed.

=item test_builder

The L<Test::Builder> singleton.

=back

=head1 METHODS

=over 4

=item empty

Cleans out the directory but doesn't delete it.

=item delete

Cleans out the directory and removes it.

=item cleanup

Calls C<delete> if the C<cleanup_policy> dictates to do so.

This is normally called automatically at destruction.

=back

=cut


