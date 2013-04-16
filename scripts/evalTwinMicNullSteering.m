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

options.doTwinMicNullSteering = true;

angles = [90:15:270];
%algos = {'ICA','NLMS','fix'};
%for algoCnt=1:numel(algos);
	%for angleCnt=1:numel(angles)
		%options.impulseResponses = struct('angle',{0,angles(angleCnt)},...
				%'distance',{1,1},...
				%'room','studio');
		%options.twinMic.nullSteering.algorithm = algos{algoCnt};
		%options.twinMic.nullSteering.angle = angles(angleCnt);

		%[result opt] = start(options);
		%[snrImp(algoCnt,angleCnt),...
				%snrBefore(algoCnt,angleCnt),...
				%snrAfter(algoCnt,angleCnt)] = evalTwinMic(opt,result);
		%wavwrite(result.input.signal(1,:),opt.fs,...
				%sprintf('%sSigInput%03d.wav',resultDir,angles(angleCnt)));
		%wavwrite(result.signal(1,:),opt.fs,...
				%sprintf('%sSigOutput%03d_%s.wav',resultDir,angles(angleCnt),...
				%algos{algoCnt}));
	%end
	%dlmwrite(sprintf('%sSNR-imp_%s.txt',resultDir,algos{algoCnt}),...
			%snrImp(algoCnt,:));
	%dlmwrite(sprintf('%sSNR-before_%s.txt',resultDir,algos{algoCnt}),...
			%snrBefore(algoCnt,:));
	%dlmwrite(sprintf('%sSNR-after_%s.txt',resultDir,algos{algoCnt}),...
			%snrAfter(algoCnt,:));
%end

%eopen(sprintf('%sSNR-imp.eps',resultDir));
%eglobpar;
%ePlotLegendPos = [40,100];
%eXAxisSouthScale = [90,30,270];
%eXAxisSouthLabelText = 'Winkel in Grad';
%eYAxisWestLabelText = 'Verbesserung des SNR in dB';
%eplot(angles,(snrAfter(2,:)-snrAfter(3,:)),algos{2},0);
%eplot(angles,(snrAfter(1,:)-snrAfter(3,:)),algos{1},1);
%eclose;
%newbbox = ebbox(1);

%reload written values:
afterFix = dlmread(sprintf('%sSNR-after_fix.txt',resultDir));
afterIca = dlmread(sprintf('%sSNR-after_ICA.txt',resultDir));
afterNlms = dlmread(sprintf('%sSNR-after_NLMS.txt',resultDir));

eopen(sprintf('%sSNR-imp.eps',resultDir));
eglobpar;
ePlotAreaHeight = 60;
ePlotLegendPos = [40,55];
eXAxisSouthScale = [90,30,270];
eXAxisSouthLabelText = 'Winkel in Grad';
eYAxisWestLabelText = 'Verbesserung des SNR in dB';
eplot(angles,(afterNlms-afterFix),'NLMS',0);
eplot(angles,(afterIca-afterFix),'ICA',1);
eclose;
newbbox = ebbox(1);
