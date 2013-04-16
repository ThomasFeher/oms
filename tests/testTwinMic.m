function testTwinMic(tmpDir)
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doTdRestore = true;
options.doConvolution = true;
options.inputSignals =...
		{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		'~/AudioDaten/nachrichten_10s.wav'};
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
resultDir = tmpDir;
options.resultDir = resultDir;
options.tmpDir = tmpDir;
options.doTwinMicBeamforming = true;
options.twinMic.beamformer.angle = 60;
options.doDistanceFiltering = true;
options.distanceFilter.withGate = true;
options.distanceFilter.threshold = 1.1;
options.distanceFilter.update = 1;
sourceDist = 0.05; %1;
distance = 1;
angle = 15;

%calculate amplification of second signal due to increased distance
level = 20*log10(distance/sourceDist);
options.impulseResponses = struct('angle',{0 angle},...
'distance',{sourceDist distance},'room','studio',...
'level',{0 level});

%beamforming
[result opt] = start(options);
[snrImpBF,snrBeforeBF,snrAfterBF] = evalTwinMic(opt,result);
