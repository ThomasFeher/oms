clear
addpath(fileparts(fileparts(mfilename('fullpath'))));

%%%%%%%%%%+options%%%%%%%%%%
database = 'samurai';% 'samurai' or 'apollo'
resultDir = '/erk/tmp/feher/twinDistSpeechRecog/';
%noiseFile = '/erk/daten1/uasr-data-feher/audio/noise_pink_10s_16kHz.wav';
noiseFile1 = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';
noiseFile2 = '/erk/daten1/uasr-data-feher/audio/nachrichten_10s.wav';
noiseAmp = -15; %amplification of noise signal
shortSet = false;%process only first 100 files
distances = [0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];%noise distances
sourceDist = 0.05;
angles = [0];%[15 45 75 105 135 165];%[0:15:180];
%%%%%%%%%%-options%%%%%%%%%%

if(strcmp(database,'samurai'))
	sigDir = '/erk/home/feher/uasr-data/ssmg/common/';
	fileListName = '~/uasr-data/ssmg/common/flists/SAMURAI_0.flst';
elseif(strcmp(database,'apollo'))
	sigDir='/erk/home/feher/uasr/data/apollo/';
	fileListName = '/erk/daten2/uasr-maintenance/uasr-data/apollo/1020.flst';
else
	error('unknown database');
end
fId = fopen(fileListName);
%fileList = textscan(fId,'%s %s');
fileList = textscan(fId,'%s %*[^\n]');
fileNum = numel(fileList{1});
if(~exist(resultDir,'dir')) mkdir(resultDir); end
if(~exist([resultDir 'cardioid'],'dir')) mkdir([resultDir 'cardioid']); end
if(~exist([resultDir 'binMask'],'dir')) mkdir([resultDir 'binMask']); end

for distCnt=1:numel(distances)
	snrImpAll=0; snrBeforeAll=0; snrAfterAll=0; %reset mean snr
	for fileCnt=1:fileNum
		%for testing, use a shorter set of first 100 utterances only
		if(shortSet) if(fileCnt>100) break; end; end;
		%for testing, do convolution for first file only
		%if(fileCnt>1) return; end;
		file = fileList{1}{fileCnt};%get file from list
		fileAbs = fullfile([sigDir 'sig'],file);%concatenate file and path
		options.doTdRestore = true;
		options.doConvolution = true;
		%options.inputSignals = {fileAbs};
		options.inputSignals = {fileAbs,noiseFile2};
		options.irDatabaseSampleRate = 16000;
		options.irDatabaseName = 'twoChanMicHiRes';
		options.blockSize = 1024;
		options.timeShift = 512;
		%options.doTwinMicNullSteering = true;
		%options.doTwinMicBeamforming = true;
		options.doDistanceFiltering = true;
		options.distanceFilter.update = 0.6;%optimized
		options.distanceFilter.threshold = 0.85;%optimized
		options.distanceFilter.cutoffFrequencyHigh = 669;%optimized
		options.distanceFilter.cutoffFrequencyLow = 75;%optimized
		%options.twinMic.beamformer.angle = 60;
		%options.twinMic.beamformer.update = 0.2;
		%calculate amplification of second signal due to increased distance
		level = 20*log10(distances(distCnt)/sourceDist);
		%options.impulseResponses = struct('angle',0,...
		%'distance',1,'room','studio',...
		%'level',0);
		options.impulseResponses = struct('angle',{0 0},...
		'distance',{sourceDist distances(distCnt)},'room','studio',...
		'level',{0 level+noiseAmp},'length',-1);

		%processing
		[result opt] = start(options);
		%[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
		%snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);
		[snrImp,snrBefore,snrAfter] = evalTwinMic(opt,result);
		snrImpAll = snrImpAll + snrImp;
		snrBeforeAll = snrBeforeAll + snrBefore;
		snrAfterAll = snrAfterAll + snrAfter;

		%%%%%output signal%%%%%
		%store signals (cardioid and binMask)
		signal = result.signal(1,:).';
		signal = signal/max(abs(signal));
		wavName = fullfile([resultDir 'binMask'],file);
		wavwrite(signal,opt.fs,wavName);
		signal = result.input.signal(1,:).';
		signal = signal/max(abs(signal));
		wavName = fullfile([resultDir 'cardioid'],file);
		wavwrite(signal,opt.fs,wavName);
		%dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
	end %fileCnt

	%speech recognition for all three signals
	clear options;
	%options.doLogfile = true;
	options.doSpeechRecognition = true;
	options.resultDir = resultDir;
	if(strcmp(database,'samurai'))
		options.speechRecognition.db = 'samurai';
	elseif(strcmp(database,'apollo'))
		options.speechRecognition.db = 'apollo';
	else
		error('unknown database');
	end
	options.speechRecognition.sigDir = [resultDir 'binMask'];
	results = start(options);
	wrrBinMask(distCnt) = results.speechRecognition.wrr;
	corBinMask(distCnt) = results.speechRecognition.cor;
	corConfBinMask(distCnt) = results.speechRecognition.corConf;
	acrBinMask(distCnt) = results.speechRecognition.acr;
	acrConfBinMask(distCnt) = results.speechRecognition.acrConf;
	farBinMask(distCnt) = results.speechRecognition.far;
	frrBinMask(distCnt) = results.speechRecognition.frr;
	nBinMask(distCnt) = results.speechRecognition.n;
	tpBinMask(distCnt) = results.speechRecognition.tp;
	fpBinMask(distCnt) = results.speechRecognition.fp;
	fnBinMask(distCnt) = results.speechRecognition.fn;
	tnBinMask(distCnt) = results.speechRecognition.tn;
	options.speechRecognition.sigDir = [resultDir 'cardioid'];
	results = start(options);
	wrrCardioid(distCnt) = results.speechRecognition.wrr;
	corCardioid(distCnt) = results.speechRecognition.cor;
	corConfCardioid(distCnt) = results.speechRecognition.corConf;
	acrCardioid(distCnt) = results.speechRecognition.acr;
	acrConfCardioid(distCnt) = results.speechRecognition.acrConf;
	farCardioid(distCnt) = results.speechRecognition.far;
	frrCardioid(distCnt) = results.speechRecognition.frr;
	nCardioid(distCnt) = results.speechRecognition.n;
	tpCardioid(distCnt) = results.speechRecognition.tp;
	fpCardioid(distCnt) = results.speechRecognition.fp;
	fnCardioid(distCnt) = results.speechRecognition.fn;
	tnCardioid(distCnt) = results.speechRecognition.tn;
	clear options;

dlmwrite(fullfile(resultDir,'snrImp.txt'),...
	[distances(distCnt) snrImpAll/results.speechRecognition.n],'-append');
dlmwrite(fullfile(resultDir,'snrBefore.txt'),...
	[distances(distCnt) snrBeforeAll/results.speechRecognition.n],'-append');
dlmwrite(fullfile(resultDir,'snrAfter.txt'),...
	[distances(distCnt) snrAfterAll/results.speechRecognition.n],'-append');

dlmwrite(fullfile(resultDir,'wrrBinMask.txt'),...
	[distances(distCnt) wrrBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'corBinMask.txt'),...
	[distances(distCnt) corBinMask(distCnt) corConfBinMask(distCnt)],...
	'-append');
dlmwrite(fullfile(resultDir,'acrBinMask.txt'),...
	[distances(distCnt) acrBinMask(distCnt) acrConfBinMask(distCnt)],...
	'-append');
dlmwrite(fullfile(resultDir,'farBinMask.txt'),...
	[distances(distCnt) farBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'frrBinMask.txt'),...
	[distances(distCnt) frrBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'nBinMask.txt'),...
	[distances(distCnt) nBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'tpBinMask.txt'),...
	[distances(distCnt) tpBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'fpBinMask.txt'),...
	[distances(distCnt) fpBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'fnBinMask.txt'),...
	[distances(distCnt) fnBinMask(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'tnBinMask.txt'),...
	[distances(distCnt) tnBinMask(distCnt)],'-append');

dlmwrite(fullfile(resultDir,'wrrCardioid.txt'),...
	[distances(distCnt) wrrCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'corCardioid.txt'),...
	[distances(distCnt) corCardioid(distCnt) corConfCardioid(distCnt)],...
	'-append');
dlmwrite(fullfile(resultDir,'acrCardioid.txt'),...
	[distances(distCnt) acrCardioid(distCnt) acrConfCardioid(distCnt)],...
	'-append');
dlmwrite(fullfile(resultDir,'farCardioid.txt'),...
	[distances(distCnt) farCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'frrCardioid.txt'),...
	[distances(distCnt) frrCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'nCardioid.txt'),...
	[distances(distCnt) nCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'tpCardioid.txt'),...
	[distances(distCnt) tpCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'fpCardioid.txt'),...
	[distances(distCnt) fpCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'fnCardioid.txt'),...
	[distances(distCnt) fnCardioid(distCnt)],'-append');
dlmwrite(fullfile(resultDir,'tnCardioid.txt'),...
	[distances(distCnt) tnCardioid(distCnt)],'-append');
end %distCnt
