
package Plg::Projs::Prj;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);

use Plg::Projs::Piwigo::SQL;

sub new
{
	my ($class, %opts) = @_;
	my $self = bless (\%opts, ref ($class) || $class);

	$self->init if $self->can('init');

	return $self;
}

sub init {
	my $self = shift;

	my ($proj)  = ($Script =~ m/^(\w+)\..*$/);
	my $root_id = basename($Bin);
	my $root    = $Bin;

	my $pwg = Plg::Projs::Piwigo::SQL->new;

	my $db_file = catfile($root,'projs.sqlite');

	my $h = {
		proj     => $proj,
		root     => $root,
		root_id  => $root_id,
		tags_img => [qw(projs), ($proj, $root_id)],
		pwg      => $pwg,
		db_file  => $db_file,
	};
		
	my @k = keys %$h;

	for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

	return $self;
}

sub _files {
	my ($self, $ref) = @_;

	$ref ||= {};
}

1;
 

