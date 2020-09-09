
package projs::_rootid_::_proj_::edt;

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use utf8; 
use Encode;
binmode STDOUT, ":utf8";

use Base::RE::TeX;
use Date::Manip;

use base qw(
    Plg::Projs::Prj::Edit
);

use Data::Dumper qw(Dumper);

sub _sub_process_file {
    my ($self, $ref) = @_;
	
	return $ref;
}

sub _sub_edit_line_replace {
    my $self = shift;

    local $_ = shift;

    s/(\s+)–(\s+)/$1---$2/g;
    s/(\d+)–(\d+)/$1-$2/g;

    return $_;
}

sub _sub_edit_line {
    my $self = shift;

    local $_ = shift;

    #s/^\s*//g;
    #s/\s*$//g;

    my ($ref,$run) = @_;

    $_ = $self->_sub('edit_line_replace',$_);
    
    return $_;

}

sub init {
    my ($self) = @_;

    $self->SUPER::init();
   
    return $self;
}

1;
 


