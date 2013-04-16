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
resultDir = '/erk/tmp/feher/testTwinNullSteering/';
options.resultDir = resultDir;
options.doTwinMicNullSteering = true;

angles = [90:15:270];
for angleCnt=1:numel(angles)
	options.impulseResponses = struct('angle',{0,angles(angleCnt)},...
			'distance',0.3,...
			'room','studio');
	options.twinMic.nullSteering.algorithm = 'fix';
	options.twinMic.nullSteering.angle = angles(angleCnt);

	[result opt] = start(options);
	[snrImp(angleCnt),...
			snrBefore(angleCnt),...
			snrAfter(angleCnt)] = evalTwinMic(opt,result);
	wavwrite(result.input.signal(1,:),opt.fs,...
			sprintf('%sInput%03d.wav',resultDir,angles(angleCnt)));
	wavwrite(result.signal(1,:),opt.fs,...
			sprintf('%sOutput%03d.wav',resultDir,angles(angleCnt)));
end

dlmwrite(sprintf('%sSNR-imp.txt',resultDir),snrImp);
dlmwrite(sprintf('%sSNR-before.txt',resultDir),snrBefore);
dlmwrite(sprintf('%sSNR-after.txt',resultDir),snrAfter);

eopen(sprintf('%sSNR-imp.eps',resultDir));
eglobpar;
ePlotLegendPos = [40,100];
eXAxisSouthScale = [90,30,270];
eXAxisSouthLabelText = 'Winkel in Grad';
eYAxisWestLabelText = 'Verbesserung des SNR in dB';
eplot(angles,(snrImp(:)));
eclose;
newbbox = ebbox(1);
