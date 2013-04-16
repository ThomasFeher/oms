#!/usr/bin/sh
#parameters:
# 	config file name
# 	log directory
# 	log file name
# 	signal directory
# 	model extension string

if [$# -ne 5]
then
	echo 'number of paramers is $# but should be 5!'
	exit 1
fi

dlabpro ~/uasr/scripts/dlabpro/HMM.xtp adp  ~/uasr-data/ssmg/common/info/$1 \
	-Pam.model=3_15   -Pdir.fea=$2  -Pdir.sig=$4 -Pam.adapt.ext=$5 \
	-Plab.offset=0.06 -v2 > $2/$3

echo "results in: $2" | \
	mail -s "model adaption finished" thomas.feher@tu-dresden.de
