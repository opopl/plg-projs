#!/bin/sh

export Bin=`dirname $0`
perl $Bin/run_tex.pl $*
