#!/usr/bin/perl
#evaluate the result list of the parameter optimizer for the binary masking
#needs the csv file containing the results as parameter
#format of csv file: fitness,param1,param2,param3,...
#use lib "/erk/tmp/feher/twinDistOpt/";
#use DateTime;
#use Date::Calc qw(Today_and_Now);
use strict;
use Time::Local;

my $file = $ARGV[0];
open FILE, "<", $file or die $!;
my @lines = <FILE>;
close File;
my @array;
my @arrayBest;
my $bestNum;#number of best individuals that will be evaluated
my $minFit = 9**9**9;
my $paramNum;#number of parameters
#results:
my @paramMean;#mean of parameters
my @paramVar;#variance of parameters
my @paramMin;#smallest parameter found
my @paramMax;#biggest parameter found

#plot current time
#my $dt = DateTime->new();
#print $dt->ymd."_".$dt->hms."\n";
print &now("y-m-d_H:M:S")."\n";

#read file in @array and find best fitness ($minFit)
while (my $line = <@lines>){
	chomp $line;
	#$line = &delEnd($line);
	my @fields = split(",",$line);
	push(@array,\@fields);
	$minFit = $fields[0] < $minFit ? $fields[0] : $minFit;
	#print "$line $fields[0] $minFit\n";
}
#print "@{$array[0]}\n";
print "number of individuals: ".scalar @lines."\n";
print "best fitness: $minFit\n";

#get number of parameters
$paramNum = (scalar @{$array[0]}) - 1;
print "number of parameters: $paramNum\n";

#get only those individuals that are best and calculate mean of their parameters
$paramMean[$_] = 0 for (1..$paramNum);#clear mean
$paramMin[$_] = 9**9**9 for (1..$paramNum);#clear minimum
$paramMax[$_] = -(9**9**9) for (1..$paramNum);#clear maximum
for my $line (@array){
	#print "@$line\n";
	#<STDIN>;
	if (@$line[0]==$minFit){
		push(@arrayBest,$line);
		#print "@$line\n" ;
		for my $paramCnt (1..$paramNum){
			$paramMean[$paramCnt] += @$line[$paramCnt];
			$paramMin[$paramCnt] = $paramMin[$paramCnt] > @$line[$paramCnt]
				?  @$line[$paramCnt]:$paramMin[$paramCnt];
			$paramMax[$paramCnt] = $paramMax[$paramCnt] < @$line[$paramCnt]
				?  @$line[$paramCnt]:$paramMax[$paramCnt];
		}
	}
}
$bestNum = scalar @arrayBest;
print "number of best individuals: $bestNum\n";
print "parameter min: @paramMin\n";
print "parameter max: @paramMax\n";

#divide by number of individuals
$paramMean[$_] /= $bestNum for (1..$paramNum);
print "parameter mean: @paramMean\n";

#calculate variance
$paramVar[$_] = 0 for (1..$paramNum);#clear variance
for my $line (@arrayBest){
	for my $paramCnt (1..$paramNum){
		$paramVar[$paramCnt] += (@$line[$paramCnt] - $paramMean[$paramCnt]) **2;
	}
}
$paramVar[$_] /= $bestNum for (1..$paramNum);
print "parameter variance: @paramVar\n";
my @paramStddev;#standard deviation
$paramStddev[$_] = sqrt($paramVar[$_]) for (1..$paramNum);
print "parameter standard deviation: @paramStddev\n";

sub now {
	my $format = $_[0];

	my $now = timelocal(localtime);
	my $y = sprintf("%04d",(localtime($now))[5]+1900);
	my $m = sprintf("%02d",(localtime($now))[4]+1);
	my $d = sprintf("%02d",(localtime($now))[3]);
	my $H = sprintf("%02d",(localtime($now))[2]);
	my $M = sprintf("%02d",(localtime($now))[1]);
	my $S = sprintf("%02d",(localtime($now))[0]);

	$format =~ s/y/$y/g;
	$format =~ s/m/$m/g;
	$format =~ s/d/$d/g;
	$format =~ s/H/$H/g;
	$format =~ s/M/$M/g;
	$format =~ s/S/$S/g;
	$format =~ s/y/$y/g;

	return $format;
}
