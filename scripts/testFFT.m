clear
addpath(fileparts(fileparts(mfilename('fullpath'))));

%options.blockSize = 5120;
%options.timeShift = 5120/2;
options.doConvolution = true;
[result opt] = start(options);
wavwrite(result.signal(1,:),opt.fs,'/erk/tmp/feher/sig1.wav');

%options.inputSignals = ones(2,1000)
%options.inputSignals = kron([0 1 2 3 4 5 6 7 8 9],ones(2,100));
%options.fs = 16000;
%[result opt] = start(options);
