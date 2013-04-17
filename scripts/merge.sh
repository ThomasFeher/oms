#!/usr/bin/sh
#merge all files in the two directories given as parameters to one file in
#first directory and sort entries numerically
#use for merging result data files

if [ $# -ne 2 ]
then
	echo "number of arguments: $#, but must be 2!"
	exit 1
fi

path1=$1
path2=$2

#make backup copies
mkdir $path1/backup
mkdir $path2/backup
cp $path1/*.* $path1/backup/
cp $path2/*.* $path2/backup/

#merge files
files=`find $path2 -maxdepth 1 -name *.txt -type f -printf '%f\n'`
filearray=( $files ) #() creates array
for name in ${filearray[@]}; do
	echo $name
	#paste -d, "$path1/$name" "$path2/$name" 
	echo 1:
	cat "$path1/$name" 
	echo 2:
	cat "$path2/$name" 
	echo to
	cat "$path1/$name" "$path2/$name" | sort -n #> $path1/$name
	echo
done
