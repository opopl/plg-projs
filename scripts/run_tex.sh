#!/bin/sh

export Bin=`dirname $0`
perl $Bin/run_tex.pl $*
#perl -d $Bin/run_tex.pl $*
