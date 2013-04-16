clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
%options.inputSignals =...
		%{'~/AudioDaten/DLF_Gespraech_48kHz_10s.wav',...
		%'~/AudioDaten/nachrichten_10s_48kHz.wav'};
options.inputSignals =...
		{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		'~/AudioDaten/nachrichten_10s.wav'};
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
%options.doDistanceFiltering = true;
%options.distanceFilter.withGate = true;
resultDir = '/erk/tmp/feher/';
mkdir(resultDir);

options.impulseResponses = struct('angle',{0 90},...
		'distance',{1 1},'room','studio');

%beamforming
options.doTwinMicBeamforming = true;
options.twinMic.beamformer. angle = 30;
[result opt] = start(options);
[snrImpBF snrBefore] = evalTwinMic(opt,result)

%%%%%output signal%%%%%
signal = transp(result.signal(:,:));
signal = signal(:,1)/max(abs(signal(:)));
wavName = sprintf('%s/sigBF.wav',resultDir);
wavwrite(signal,opt.fs,wavName);

signal = transp(result.input.signal(:,:));
signal = signal/max(abs(signal(:)));
wavwrite(signal,opt.fs,[resultDir 'sigInput.wav']);

%null steering
options.doTwinMicBeamforming = false;
options.doTwinMicNullSteering = true;
options.twinMic.nullSteering.angle = 90;

[result opt] = start(options);
[snrImpNS snrBefore] = evalTwinMic(opt,result)

%%%%%output signal%%%%%
signal = transp(result.signal(:,:));
signal = signal(:,1)/max(abs(signal(:)));
wavName = sprintf('%s/sigNS.wav',resultDir);
wavwrite(signal,opt.fs,wavName);

disp('beamforming nullsteering');
disp([snrImpBF snrImpNS]);
