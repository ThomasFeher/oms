package FileSemaphore;

use Fcntl ":flock";

sub aquire {
	my $file = shift; #semaphore file name
	my $maxCnt = shift; #maximum number of processes

	my $cnt = $maxCnt;
	my $fh; #handle to semaphore file

	open($fh,"+>>",$file) or die "semaphore file open failed: $!";
	while (1) {
		#try to get lock
		if (flock($fh,LOCK_EX | LOCK_NB)){ #succeeded
			#go to file start
			seek($fh,0,0);
			#read counter
			$cnt = <$fh>;
			if ($cnt < $maxCnt){ #there are free resources
				#clear file
				truncate($fh,0);
				#write increment count by 1
				$cnt += 1;
				print $fh $cnt;
				#release lock
				flock($fh,LOCK_UN);
				#leave loop to run code
				last;
			}
			else{ #no free resources
				#close lock
				flock($fh,LOCK_UN) or die "release lock failed: $!";
			}
			sleep(10); #wait some time
		}
	} 
	return($fh);
}

sub release {
	$fh = shift;

	#aquire lock again to signal finish
	flock($fh,LOCK_EX);
	#go to file start
	seek($fh,0,0);
	#read counter
	$cnt = <$fh>;
	#clear file
	truncate($fh,0);
	#decrement counter
	$cnt -= 1;
	#write new counter
	print $fh $cnt;
	#close file
	close($fh);
}

1;
