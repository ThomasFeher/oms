clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.inputSignals = ones(2,10);
options.doConvolution = true;
options.doTdRestore = true;
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
options.timeShift = 512;
resultDir = '/erk/tmp/feher/twinWfPolar_dist:0.05/';
options.resultDir = resultDir;
options.doTwinMicWienerFiltering = true;
options.twinMic.wienerFilter.update = 1;
sourceDist = 0.05;

options.tmpDir = resultDir;
distances = [0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];
angles = [0:15:180];
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

	signal = result.input.signal(:,:).';
	signal = signal/max(abs(signal(:)));
	wavName = sprintf('%s/sigInput_%03d_dist%01.2f.wav',...
			resultDir,angles(angleCnt),distances(distCnt));
	wavwrite(signal,opt.fs,wavName);
	dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
	end
end

eopen(sprintf('%s/polarImp.eps',resultDir));
eglobpar;
ePolarPlotAreaAngStart = 0;
ePolarPlotAreaAngEnd = 180;
epolaris(snrImpBF,ecolors(2),'s',[0 0 40]);
eclose;
newbbox = ebbox(1);

eopen(sprintf('%s/polarBeforeAfter.eps',resultDir));
eglobpar;
ePolarPlotAreaAngStart = 0;
ePolarPlotAreaAngEnd = 180;
ePolarAxisRadValueVisible = 0;
ePolarAxisRadVisible = 0;
epolaris(snrBeforeBF,ecolors(2),'s',[0 0 40]);
ePolarPlotAreaAngStart = 180;
ePolarPlotAreaAngEnd = 360;
ePolarAxisAngScale = [180 0 0];
ePolarAxisRadVisible = 3;
ePolarAxisRadValueVisible = 3;
ePolarAxisRadScale = [0 0 1];
epolaris(snrAfterBF(:,end:-1:1),ecolors(2),'s',[0 0 40]);
eclose;
newbbox = ebbox(1);

dlmwrite(sprintf('%sBefore.txt',resultDir),snrBeforeBF);
dlmwrite(sprintf('%sAfter.txt',resultDir),snrAfterBF);
dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
