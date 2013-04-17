clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
options.inputSignals = ...
		{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		'~/AudioDaten/nachrichten_10s.wav'};
opitions.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
resultDir = '/erk/tmp/feher/twinDma/';
options.resultDir = resultDir;
options.impulseResponses = struct('angle',{0,135},...
		'distance',{1,1},...
		'room','studio');

options.doDma = true;
options.dma.angle = 135;

[result opt] = start(options);
[snrImp,snrBefore,snrAfter] = evalTwinMic(opt,result);
disp(sprintf('SNR improvement: %f',snrImp));
