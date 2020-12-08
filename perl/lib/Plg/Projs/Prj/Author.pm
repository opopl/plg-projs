
package Plg::Projs::Prj::Author;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';

use File::Basename qw(basename dirname);
use File::Path qw(make_path remove_tree mkpath rmtree);

# see also: projs#author#get

sub _author_get {
	my ($self, $ref) = @_;
	$ref ||= {};

	my $author_id = $ref->{author_id} || '';

	my $data   = $self->_data_dict({ 'id' => 'authors' });
	my $author = $data->{'author_id'} || '';

	return $author;
}

# see also: projs#author#file

sub _author_file {
	my ($self, $ref) = @_;
	$ref ||= {};

	my $proj = $ref->{proj} || '';

	my $file = $self->_data_dict_file({ 
		proj => $proj,
		id   => 'authors',
	});
	my $dir = dirname($file);
	mkpath $dir unless -d $dir;

	return $file;
}



  #let file = projs#data#dict_file({ 'proj' : proj, 'id' : 'authors' })
  #let dir  = fnamemodify(file,':p:h')
  #call base#mkdir(dir)

  #return file

#endfunction

1;
 

