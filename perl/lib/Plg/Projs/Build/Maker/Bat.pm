
package Plg::Projs::Build::Maker::Bat;

use strict;
use warnings;

sub _bat_ext {
    my ($self) = @_;

    my $ext = $^O eq 'MSWin32' ? 'bat' : 'sh';

    return $ext;
}

sub _bat_file {
    my ($self, $head) = @_;

    my $ext  = $self->_bat_ext;
    my $file = sprintf(q{%s.%s},$head,$ext);

    return $file;
}

sub _bat_sub_tex {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $exe    = $ref->{exe} || 'pdflatex';
    my $times  = $ref->{times} || 2;
    my $target = $ref->{target} || 'jnd';

    my $sub = sub {
        my @cmds;
        if ($^O eq 'MSWin32'){
            push @cmds, 
                ' ',
                sprintf('set opts='),
                sprintf('set opts=%%opts%% -file-line-error'),
                ' ';

            for(1 .. $times){
                push @cmds, 
                    sprintf('%s %%opts%% %s',$exe,$target)
                ;
            }

        }else{
            push @cmds, 
                '#!/bin/sh',
                ' ',
                sprintf(q{opts=}),
                sprintf(q{opts="$opts -file-line-error"})
                ;

            for(1 .. $times){
                push @cmds, 
                    sprintf('%s $opts %s',$exe,$target)
                ;
            }

        }

        return [@cmds];
    };

    return $sub;
}


1;
 

