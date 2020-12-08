
package Plg::Projs::Prj::Author;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';

use File::Basename qw(basename dirname);
use File::Path qw(make_path remove_tree mkpath rmtree);
use File::Slurp::Unicode;

###see_also projs#author#get

sub _author_get {
	my ($self, $ref) = @_;
	$ref ||= {};

	my $author_id = $ref->{author_id} || '';

	my $data   = $self->_data_dict({ 'id' => 'authors' });
	my $author = $data->{'author_id'} || '';

	return $author;
}

###see_also projs#author#file

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

###see_also projs#author#add

sub author_add {
	my ($self, $ref) = @_;
	$ref ||= {};

	my $author    = $ref->{author} || '';
	my $author_id = $ref->{author_id} || '';

	my $hash = $self->_data_dict({ 'id' => 'authors' });

	if ($author_id) {
		$hash->{$author_id} = $author;
	}
	$self->{hash_authors} = $hash;

	$self->author_hash_save;

	return $self;
}

###see_also projs#author#hash_save

sub author_hash_save {
	my ($self) = @_;

	my $file = $self->_author_file;

	my $hash = $self->{hash_authors} || {};
	my @ids = sort keys %$hash;

	my @lines;
	foreach my $author_id (@ids) {
		my $author = $hash->{$author_id} || '';
		next unless $author;
		push @lines, sprintf('%s %s', $author_id, $author);
	}
	write_file($file,join("\n",@lines));

	return $self;
}

1;
 
