clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
%addpath('~/epstk/m');

options.doTdRestore = true;
options.doConvolution = true;
options.inputSignals =...
		{'~/uni/audio/DLF_Gespraech_10s.wav',...
		'~/uni/audio/nachrichten_10s.wav'};
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
resultDir = '/home/Tom/tmp/twinDist/';
options.resultDir = resultDir;
options.tmpDir = '/home/Tom/tmp/';
%options.doTwinMicBeamforming = true;
%options.twinMic.beamformer.angle = 60;
options.doDistanceFiltering = true;
options.distanceFilter.withGate = true;
options.distanceFilter.threshold = 1.1;
options.distanceFilter.update = 1;
sourceDist = 0.05; %1;

distances = [0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];
angles = 0;
for angleCnt = 1:numel(angles)
	for distCnt = 1:numel(distances)
	%calculate amplification of second signal due to increased distance
	level = 20*log10(distances(distCnt)/sourceDist);
	options.impulseResponses = struct('angle',{0 angles(angleCnt)},...
			'distance',{sourceDist distances(distCnt)},'room','studio',...
			'level',{0 level});

	%beamforming
	[result opt] = start(options);
	[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
			snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);

	%%%%%output signal%%%%%
	signal = result.signal(:,:).';
	signal = signal(:,1)/max(abs(signal(:)));
	wavName = sprintf('%s/sigBF_angle%03d_dist%01.2f.wav',...
			resultDir,angles(angleCnt),distances(distCnt));
	wavwrite(signal,opt.fs,wavName);

	signal = transp(result.input.signal(:,:));
	signal = signal/max(abs(signal(:)));
	wavName = sprintf('%s/sigInput_%03d_dist%01.2f.wav',...
			resultDir,angles(angleCnt),distances(distCnt));
	wavwrite(signal,opt.fs,wavName);
	dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
	end
end

dlmwrite(sprintf('%sBefore.txt',resultDir),snrBeforeBF);
dlmwrite(sprintf('%sAfter.txt',resultDir),snrAfterBF);
dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
