
package Plg::Projs::Tex::Gen;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';

use Base::Arg qw( hash_inject );

sub new
{
	my ($class, %opts) = @_;
	my $self = bless (\%opts, ref ($class) || $class);

	$self->init if $self->can('init');

	return $self;
}

sub init {
	my ($self) = @_;
	
	my $h = {
		tex_lines => [],
	};
		
	hash_inject($self, $h);
	return $self;
}

sub add {
	my ($self, @tex) = @_;

	push @{$self->{tex_lines}}, @tex;
	return $self;
}

sub _tex {
	my ($self) = @_;

	join("\n",$self->_tex_lines) . "\n";
}

sub _tex_lines {
	my ($self) = @_;

	@{$self->{tex_lines}};
}

1;
 

