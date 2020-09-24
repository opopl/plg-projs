#!/bin/sh

Bin=`dirname $0`

perl $Bin/piwigo_sql.pl $*
