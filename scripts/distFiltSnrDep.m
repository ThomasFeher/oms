clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
%options.irDatabaseChannels = [2 3];
%options.inputSignals =...
		%{'~/AudioDaten/DLF_Gespraech_48kHz_10s.wav',...
		%'~/AudioDaten/nachrichten_10s_48kHz.wav'};
options.inputSignals =...
		{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		'~/AudioDaten/nachrichten_10s.wav'};
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
options.doDistanceFiltering = true;
options.distanceFilter.withGate = true;
resultDir = '/erk/tmp/feher/';
mkdir(resultDir);

shiftList = [64];
dist1List = [0.05];
dist2List = [1];
updateList = [0.7];
thresholdList = [1];
frequList = [800];
dGateThList = [0.7]
noiseLevelList = [-30:5:30]+29;

for dist1=dist1List
for dist2=dist2List
for updateCnt=updateList
for thCnt=thresholdList
for frequCnt=frequList
for shiftCnt=shiftList
for dGateThCnt=dGateThList
for noiseLevelCnt=noiseLevelList

	options.impulseResponses = struct('angle',0,...
	'distance',{dist1 dist2},'room','refRaum',...
	'level',{1 noiseLevelCnt});
	options.distanceFilter.threshold = thCnt;
	options.distanceFilter.update = updateCnt;
	options.distanceFilter.cutoffFrequencyHigh = frequCnt;
	options.distanceGate.threshold = dGateThCnt;
	options.timeShift = shiftCnt;
	[result opt] = start(options);
	[snrImp snrBefore] = evalTwinMic(opt,result)
	expString = sprintf(['refRaum_snr:%2.1f_cutoff:%d_threshold:%1.1f_'...
	'update:%0.2f_timeShift:%03d_dGateTh:%1.2f_-_%02.1f']...
	,snrBefore,frequCnt,thCnt,updateCnt,shiftCnt,dGateThCnt,snrImp);

	%%%%%output signal%%%%%
	signal = transp(result.signal(:,:));
	signal = signal(:,1)/max(abs(signal(:)));
	wavName = sprintf('%s/sig_%s.wav',resultDir,expString);
	wavwrite(signal,opt.fs,wavName);

	%%%%%evaluation signal%%%%%
	%1
	signalBefore = transp(result.input.signalEval{1}(1,:));
	signalAfter = transp(result.signalEval{1}(1,:));
	signal = [signalBefore(:,1) signalAfter(:,1)];
	signal = signal/max(abs(signal(:)));
	wavName = sprintf('%s/sigEval1Before_%s.wav',resultDir,expString);
	wavwrite(signal(:,1),opt.fs,wavName);
	wavName = sprintf('%s/sigEval1After_%s.wav',resultDir,expString);
	wavwrite(signal(:,2),opt.fs,wavName);

	%2
	signalBefore = transp(result.input.signalEval{2}(1,:));
	signalAfter = transp(result.signalEval{2}(1,:));
	signal = [signalBefore(:,1) signalAfter(:,1)];
	signal = signal/max(abs(signal(:)));
	wavName = sprintf('%s/sigEval2Before_%s.wav',resultDir,expString);
	wavwrite(signal(:,1),opt.fs,wavName);
	wavName = sprintf('%s/sigEval2After_%s.wav',resultDir,expString);
	wavwrite(signal(:,2),opt.fs,wavName);

end
end
end
end
end
end
end
end
signal = transp(result.input.signal(:,:));
signal = signal/max(abs(signal(:)));
wavwrite(signal,opt.fs,[resultDir 'sigInput.wav']);
