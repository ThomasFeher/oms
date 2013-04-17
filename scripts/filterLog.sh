#!/usr/bin/sh
#print only statements of a logfile that did not originate in framework or uasr
grep -Pv "^In|twinDist|Evaluation result|Creating|done|^\/\/|Time|Lattice|Accuracy|Correctness|sequences|Performance|Sample|Valid|- Parameters|Model|File|Translit|Feature|Log dir|Constraints|Decoder|HMM|Sensor|Evaluation mode|^$|at \d+|Elapsed|sigLength|^\s*\d+\s*$|\.{3}|sublist|options|warning|error" log.txt
