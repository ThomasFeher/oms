function fitnessAll = twinDistOptFnct(params)

%%%%%%%%%%+options%%%%%%%%%%
database = 'samurai';% 'samurai' or 'apollo'
resultDir = '/erk/tmp/feher/twinDistOpt/';
%noiseFile = '/erk/daten1/uasr-data-feher/audio/noise_pink_10s_16kHz.wav';
noiseFile1 = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';
noiseFile2 = '/erk/daten1/uasr-data-feher/audio/nachrichten_10s.wav';
noiseAmp = -15; %amplification of noise signal
shortSet = true;%process only first <shortSetNum> files
shortSetNum = 100;
distances = [0.3];%[0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];%noise distances
sourceDist = 0.05;
doFdStore = true;
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
%if(~exist([resultDir 'cardioid'],'dir')) mkdir([resultDir 'cardioid']); end
if(~exist([resultDir 'binMask'],'dir')) mkdir([resultDir 'binMask']); end

for fileCnt=1:fileNum
	%for testing, use a shorter set of first <shortSetNum> utterances only
	if(shortSet) if(fileCnt>shortSetNum) break; end; end;
	file = fileList{1}{fileCnt};%get file from list
	fileAbs = fullfile([sigDir 'sig'],file);%concatenate file and path
	options.doFdStore = doFdStore;
	options.doTdRestore = true;
	options.doConvolution = true;
	%options.doLogfile = true;
	options.resultDir = resultDir;
	%options.inputSignals = {fileAbs};
	options.inputSignals = {fileAbs,noiseFile2};
	options.irDatabaseSampleRate = 16000;
	options.irDatabaseName = 'twoChanMicHiRes';
	options.blockSize = 1024;
	options.timeShift = 512;
	options.doDistanceFiltering = true;
	%%%%%%%%%%+get parameters%%%%%%%%%%
	%1=update coeff
	options.distanceFilter.update = params(1);
	%2=threshold
	options.distanceFilter.threshold = params(2);
	%3=cutoff high
	options.distanceFilter.cutoffFrequencyHigh = params(3);
	%4=cutoff low
	options.distanceFilter.cutoffFrequencyLow = params(4);
	%%%%%%%%%%-get parameters%%%%%%%%%%
	%calculate amplification of second signal due to increased distance
	level = 20*log10(distances/sourceDist);
	options.impulseResponses = struct('angle',{0 0},...
	'distance',{sourceDist distances},'room','studio',...
	'level',{0 level+noiseAmp},'length',-1);

	%processing
	[result opt] = start(options);
	%[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
	%snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);
	%[snrImp,snrBefore,snrAfter] = evalTwinMic(opt,result);
	%snrImpAll = snrImpAll + snrImp;
	%snrBeforeAll = snrBeforeAll + snrBefore;
	%snrAfterAll = snrAfterAll + snrAfter;

	%%%%%output signal%%%%%
	%store signals (cardioid and binMask)
	signal = result.signal(1,:).';
	signal = signal/max(abs(signal));
	wavName = fullfile([resultDir 'binMask'],file);
	wavwrite(signal,opt.fs,wavName);
	%signal = result.input.signal(1,:).';
	%signal = signal/max(abs(signal));
	%wavName = fullfile([resultDir 'cardioid'],file);
	%wavwrite(signal,opt.fs,wavName);
	%dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
end %fileCnt

%speech recognition
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
%wrrBinMask(distCnt) = results.speechRecognition.wrr;
%corBinMask(distCnt) = results.speechRecognition.cor;
%corConfBinMask(distCnt) = results.speechRecognition.corConf;
%acrBinMask(distCnt) = results.speechRecognition.acr;
%acrConfBinMask(distCnt) = results.speechRecognition.acrConf;
%farBinMask(distCnt) = results.speechRecognition.far;
%frrBinMask(distCnt) = results.speechRecognition.frr;
%nBinMask(distCnt) = results.speechRecognition.n;
%tpBinMask(distCnt) = results.speechRecognition.tp;
%fpBinMask(distCnt) = results.speechRecognition.fp;
%fnBinMask(distCnt) = results.speechRecognition.fn;
%tnBinMask(distCnt) = results.speechRecognition.tn;
%options.speechRecognition.sigDir = [resultDir 'cardioid'];
%results = start(options);
%wrrCardioid(distCnt) = results.speechRecognition.wrr;
%corCardioid(distCnt) = results.speechRecognition.cor;
%corConfCardioid(distCnt) = results.speechRecognition.corConf;
%acrCardioid(distCnt) = results.speechRecognition.acr;
%acrConfCardioid(distCnt) = results.speechRecognition.acrConf;
%farCardioid(distCnt) = results.speechRecognition.far;
%frrCardioid(distCnt) = results.speechRecognition.frr;
%nCardioid(distCnt) = results.speechRecognition.n;
%tpCardioid(distCnt) = results.speechRecognition.tp;
%fpCardioid(distCnt) = results.speechRecognition.fp;
%fnCardioid(distCnt) = results.speechRecognition.fn;
%tnCardioid(distCnt) = results.speechRecognition.tn;
clear options;

%calculate fitness (smallest is best)
fitnessAll = results.speechRecognition.acr * (-1);
%store fitness in file
dlmwrite(fullfile(resultDir,'fitness_update_threshold_frHigh_frLow.csv'),[fitnessAll,params.'],'-append');
