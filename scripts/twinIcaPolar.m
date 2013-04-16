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
%resultDir = '/erk/tmp/feher/twinIcaPolar_dist:0.05/';
resultDir = '/erk/tmp/feher/twinIcaPolar_dist:1.00/';
mkdir(resultDir);
options.doFDICA = true;
options.iterICA = 100;
sourceDist = 0.05;

%distances = [0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];
%angles = [0:15:180];
%for angleCnt = 1:numel(angles)
	%for distCnt = 1:numel(distances)
	%%calculate amplification of second signal due to increased distance
	%level = 20*log10(distances(distCnt)/sourceDist);
	%sourcDist = 1;
	%options.impulseResponses = struct('angle',{0 angles(angleCnt)},...
			%'distance',{sourceDist distances(distCnt)},'room','studio',...
			%'level',{0 level});

	%%process
	%[result opt] = start(options);
	%%evaluate
	%[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
			%snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);

	%%%%%%output signal%%%%%
	%signal = transp(result.signal(:,:));
	%signal = signal(:,1)/max(abs(signal(:)));
	%wavName = sprintf('%s/sigBF_angle%03d_dist%01.2f_1.wav',...
			%resultDir,angles(angleCnt),distances(distCnt));
	%wavwrite(signal,opt.fs,wavName);
	%signal = transp(result.signal(:,:));
	%signal = signal(:,2)/max(abs(signal(:)));
	%wavName = sprintf('%s/sigBF_angle%03d_dist%01.2f_2.wav',...
			%resultDir,angles(angleCnt),distances(distCnt));
	%wavwrite(signal,opt.fs,wavName);
	%%signal = transp(result.signalEval{1}(:,:));
	%%signal = signal(:,1)/max(abs(signal(:)));
	%%wavName = sprintf('%s/sigBFEval_angle%03d_dist%01.2f_11.wav',...
			%%resultDir,angles(angleCnt),distances(distCnt));
	%%wavwrite(signal,opt.fs,wavName);
	%%signal = transp(result.signalEval{1}(:,:));
	%%signal = signal(:,2)/max(abs(signal(:)));
	%%wavName = sprintf('%s/sigBFEval_angle%03d_dist%01.2f_12.wav',...
			%%resultDir,angles(angleCnt),distances(distCnt));
	%%wavwrite(signal,opt.fs,wavName);
	%%signal = transp(result.signalEval{2}(:,:));
	%%signal = signal(:,1)/max(abs(signal(:)));
	%%wavName = sprintf('%s/sigBFEval_angle%03d_dist%01.2f_21.wav',...
			%%resultDir,angles(angleCnt),distances(distCnt));
	%%wavwrite(signal,opt.fs,wavName);
	%%signal = transp(result.signalEval{2}(:,:));
	%%signal = signal(:,2)/max(abs(signal(:)));
	%%wavName = sprintf('%s/sigBFEval_angle%03d_dist%01.2f_22.wav',...
			%%resultDir,angles(angleCnt),distances(distCnt));
	%%wavwrite(signal,opt.fs,wavName);
	%%keyboard

	%signal = transp(result.input.signal(:,:));
	%signal = signal/max(abs(signal(:)));
	%wavName = sprintf('%s/sigInput_%03d_dist%01.2f.wav',...
			%resultDir,angles(angleCnt),distances(distCnt));
	%wavwrite(signal,opt.fs,wavName);
	%end
%end

%reload written values and print black end white version
snrBeforeBF = dlmread(sprintf('%sBefore.txt',resultDir));
snrAfterBF = dlmread(sprintf('%sAfter.txt',resultDir));
snrImpBF = dlmread(sprintf('%sImp.txt',resultDir));

%eopen(sprintf('%s/polarImp.eps',resultDir));
%eglobpar;
%ePolarPlotAreaAngStart = 0;
%ePolarPlotAreaAngEnd = 180;
%epolaris(snrImpBF,ecolors(2),'s',[0 0 40]);
%eclose;
%newbbox = ebbox(1);

eopen(sprintf('%s/icaPolarBeforeAfter.eps',resultDir));
eglobpar;
ePolarPlotAreaAngStart = 0;
ePolarPlotAreaAngEnd = 180;
ePolarAxisRadValueVisible = 0;
ePolarAxisRadVisible = 0;
epolaris(snrBeforeBF,ecolors(2),'w',[0 0 40]);
ePolarPlotAreaAngStart = 180;
ePolarPlotAreaAngEnd = 360;
ePolarAxisAngScale = [180 0 0];
ePolarAxisRadVisible = 3;
ePolarAxisRadValueVisible = 3;
ePolarAxisRadScale = [0 0 1];
epolaris(snrAfterBF(:,end:-1:1),ecolors(2),'w',[0 0 40]);
eclose;
newbbox = ebbox(1);

%dlmwrite(sprintf('%sBefore.txt',resultDir),snrBeforeBF);
%dlmwrite(sprintf('%sAfter.txt',resultDir),snrAfterBF);
%dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);

%eopen(sprintf('%s/icaPolarBeforeAfter_bw.eps',resultDir));
%eglobpar;
%ePolarPlotAreaAngStart = 0;
%ePolarPlotAreaAngEnd = 180;
%ePolarPlotAreaRadMin = 0;
%ePolarAxisRadValueVisible = 0;
%ePolarAxisRadVisible = 0;
%epolaris(snrBeforeBF,ecolors(0),'e',[0 0 35]);
%ePolarPlotAreaAngStart = 180;
%ePolarPlotAreaAngEnd = 360;
%ePolarAxisAngScale = [180 0 0];
%ePolarAxisRadVisible = 3;
%ePolarAxisRadValueVisible = 3;
%ePolarAxisRadScale = [0 0 1];
%epolaris(snrAfterBF(:,end:-1:1),ecolors(0),'e',[0 0 35]);
%eclose;
%newbbox = ebbox(1);
%eopen(sprintf('%s/icaPlotBeforeAfter_bw.eps',resultDir))
%eglobpar;
%ePlotAreaHeight = 70;
%eXAxisSouthLabelText = 'Einfallswinkel in Grad';
%eYAxisWestLabelText = 'St\366rger\344uschunterdr\374ckung in dB';
%ePlotLegendPos = [5,65];
%eplot([0:15:180],snrBeforeBF(6,:),'DMA 1. Ordnung (Nierencharakteristik)',1);
%eplot([0:15:180],snrAfterBF(6,:),'ICA im Frequenzbereich',0);
%%eplot(snrImpBF(9,:));
%eclose;
%newbbox = ebbox(1);
