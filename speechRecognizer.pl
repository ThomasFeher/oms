#!/usr/bin/perl
#arguments: sigDir,logDir,database (db), resultFileName, [model]
use strict;
use warnings;
use File::Path 'rmtree';
use FileSemaphore;

my $maxProcNum = 3; #maximum number of running processes TODO make a parameter
my $semaFile = "sema"; #file name of the semaphore file TODO make a parameter

die 'too few arguments: '.$#ARGV if ($#ARGV < 2);
my $model = '3_15';
if ($#ARGV > 2){
	$model = $ARGV[3];
}
#my $resultFileName = $ARGV[3];#obsolete, remove
my $db = $ARGV[2];
my $logDir = $ARGV[1];
my $sigDir = $ARGV[0];
my $out;

print "model: $model\n";
#print "result file: $resultFileName\n";
print "corpus: $db\n";
print "log dir: $logDir\n";
print "sig dir: $sigDir\n";

#aquire semaphore
my $fh = FileSemaphore::aquire($semaFile,$maxProcNum);

#do recognition
if ($db=~/apollo/i){
	$out = `dlabpro ~/uasr/scripts/dlabpro/JLSS.xtp --offline \\
		/erk/daten2/uasr-maintenance/uasr-data/apollo/apollo.cfg \\
		-Pdir.sig=$sigDir \\
		-Pdir.log=$logDir \\
		-Pam.model=$model \\
		-Pdb=ssmg\\
		-Pexp=SAMURAI \\
		-Pvoc=/erk/daten2/uasr-maintenance/uasr-data/apollo/apollo.voc.txt \\
		-Psigl=/erk/daten2/uasr-maintenance/uasr-data/apollo/1020.flst \\
		-v2`;
	die "fatal error in uasr processing:\n$out\n" if $out=~/error - FATAL/;
	print "\n$out\n";
}
elsif ($db=~/samurai/i){
	$out = `dlabpro ~/uasr/scripts/dlabpro/HMM.xtp evl \\
		~/uasr-data/ssmg/common/info/SAMURAI_0.cfg \\
		-Pdir.sig=$sigDir \\
		-Pam.model=$model \\
		-Pdir.fea=$logDir \\
		-v2 \\
		2>&1`;
 
	die "fatal error in uasr processing:\n$out\n" if $out=~/error - FATAL/;
	print "\n$out\n";
}

system("echo \"results in: $logDir\" | \\
	mail -s \"recognition finished\" thomas.feher\@tu-dresden.de");

#remove remote signal files
rmtree($sigDir) or print "error deleting signal directory:\n$sigDir\n$!\n";

#release semaphore
FileSemaphore::release($fh);
