#!/bin/sh

export Bin=`dirname $0`

perl $Bin/bb_tex.pl $*
