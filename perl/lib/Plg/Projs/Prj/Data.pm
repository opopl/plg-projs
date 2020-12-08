
package Plg::Projs::Prj::Data;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);

=head3 _data_dict

	see also:
		projs#data#dict

=cut

sub _data_dict {
	my ($self) = @_;

	my $data;

	return $data;
}

# see also: projs#data#dict_file

sub _data_dict_file {
	my ($self, $ref) = @_;
	$ref ||= {};

	my $id   = $ref->{id} || '';
	my $proj = $ref->{proj} || '';
	my $root = $self->{root};

	my @a = ( $root,qw(data dict));
	if ($proj) {
		push @a,$proj;
	}

	my $file = catfile(@a,printf(q{%s.i.dat}, $id) );
	return $file;
}

1;
 

