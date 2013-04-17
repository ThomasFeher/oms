clear
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
resultDir = '/erk/tmp/feher/twinDistRangeTest/';
options.resultDir = resultDir;
options.doDistanceFiltering = true;
options.distanceFilter.withGate = true;
options.distanceFilter.threshold = 1.1;
options.distanceFilter.update = 1;
options.distanceGate.threshold = 0.5;
sourceDists = [0.05,0.1,0.15,0.2,0.3,0.5,0.75];

for distCnt = 1:numel(sourceDists)
	%calculate amplification of second signal due to increased distance
	level = 20*log10(1/sourceDists(distCnt));
	options.impulseResponses = struct('angle',{0 0},...
			'distance',{sourceDists(distCnt) 1},'room','studio',...
			'level',{0 level});
	[result opt] = start(options);
	[snrImpBF(distCnt),snrBeforeBF(distCnt),...
			snrAfterBF(distCnt)] = evalTwinMic(opt,result);
	
	eopen(sprintf('%s/spectrogram%d.eps',resultDir,sourceDists(distCnt)*100));
	spec = squeeze(result.twinMic.sigVec(1,:,1:100));
	plotSpec(spec,sprintf('%s/spectrogram%d.eps',resultDir,sourceDists(distCnt)*100));
end

dlmwrite(sprintf('%sBefore.txt',resultDir),snrBeforeBF);
dlmwrite(sprintf('%sAfter.txt',resultDir),snrAfterBF);
dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);

