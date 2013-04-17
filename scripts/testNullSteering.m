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
resultDir = '/erk/tmp/feher/twinNullSteering/';
options.resultDir = resultDir;
options.impulseResponses = struct('angle',{0,135},...
		'distance',{1,1},...
		'room','studio');

options.doTwinMicNullSteering = true;
%options.doTwinMicBeamforming = true;
options.twinMic.nullSteering.algorithm = 'ICA';
options.twinMic.nullSteering.iterations = 3;

[result opt] = start(options);
[snrImp,snrBefore,snrAfter] = evalTwinMic(opt,result);
disp(sprintf('SNR improvement: %f',snrImp));

eopen(sprintf('%sangle.eps',resultDir));
eplot(result.twinMic.nullSteering.angle);
eclose;
