clear all;
close all;

omsDir = '~/Daten/Tom/oms/';
resultDir = '/erk/tmp/feher/twinAngle/';
resultDirRemote = '/erk/tmp/feher/home/';
tmpDir = resultDir;
noiseFile = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';

%%%%%parameters%%%%%
distances = [0.4];
levels = [5,0,-5,-10,-15,-20,-25,-30];
%levels = [-10];
speaker_angle = 0;
%speaker_angle = 90;
angles = 90;%[90:15:180]+speaker_angle;
%angles = 0;%[90:15:180]+speaker_angle;
shortSet = false;%process only first <shortSetNum> files
shortSetNum = 2;
doSpeechRecog = true;
doRemote = true;
doGetRemoteResults = true;%if true, only results of previous run are gathered
corpus = 'samurai';%'samurai','apollo';
mic = 'three';%'twin', 'three'
model = '3_15_A_three_000_sphere';%model name (only necessary if
												%adpted model is used
doAdapt = false;%if true, file list for second samurai-corpus is used
					%(for model adaption)
%%%%%parameters%%%%%

%models:
%3_15_A_orig.hmm
%3_15_A_three_000_adma.hmm
%3_15_A_three_000_adma_label.hmm
%3_15_A_three_000_adma_noise_label.hmm
%3_15_A_three_000_binMask.hmm
%3_15_A_three_000_binMask_label.hmm
%3_15_A_three_000_binMask_noise_label.hmm
%3_15_A_three_000_sphere.hmm
%3_15_A_three_000_sphere_noise_label.hmm
%3_15_A_twin_000_adma.hmm
%3_15_A_twin_000_adma_label.hmm
%3_15_A_twin_000_adma_noise_label.hmm
%3_15_A_twin_000_adma_refRaum.hmm
%3_15_A_twin_000_adma_refRaum_label.hmm
%3_15_A_twin_000_binMask.hmm
%3_15_A_twin_000_binMask_label.hmm
%3_15_A_twin_000_binMask_noise_label.hmm
%3_15_A_twin_000_sphere.hmm
%3_15_A_twin_000_sphere_noise_label.hmm
%3_15.hmm

%add oms folders
addpath(omsDir);
addpath([omsDir '/scripts/']);

%expand directories if necessary
if ~isMatlab()
	tmpDir = tilde_expand(tmpDir);
	resultDir = tilde_expand(resultDir);
	irDatabaseDir = tilde_expand(irDatabaseDir);
end

%create result dir
if(~exist(tmpDir,'dir'))
	mkdir(tmpDir);
end
if(~exist(resultDir,'dir'))
	mkdir(resultDir);
end

%start logging
diary(fullfile(resultDir,['log' admaAlgoUpCase '.txt']));%switch logging on

%display file name
disp(['script: ' mfilename]);

%display commit hash
[~,gitCommit] = system(['cd ' omsDir ';git rev-parse HEAD']);
disp(['oms commit: ' gitCommit]);

%display all variables
disp('settings:');
variables = who;%store variable names in cell array
for varCnt=1:numel(variables)
	disp([repmat([char(variables(varCnt)) ' = ']...
			,size(eval(char(variables(varCnt))),1),1)...
			num2str(eval(char(variables(varCnt))))]);
end

%print time stamp to log file
currentTime = clock();
disp(sprintf('%d-%02d-%02d_%02d:%02d:%02d',currentTime(1),currentTime(2)...
					                      ,currentTime(3),currentTime(4)...
										  ,currentTime(5),fix(currentTime(6))));

%configure paths for speech corpora
if(strcmpi(corpus,'samurai'))
	dbDir = fullfile(uasrDataPath,'ssmg/common/');
	if(doAdapt)
		filelistPath = [dbDir 'flists/SAMURAI_0_adp.flst'];
	else
		filelistPath = [dbDir 'flists/SAMURAI_0.flst'];
	end
	signalPath = [dbDir '/sig'];
elseif(strcmpi(corpus,'apollo'))
	dbDir = fullfile(uasrDataPath,'apollo/');
	filelistPath = [dbDir '1020.flst'];
	signalPath = [dbDir '/sig'];
else
	error(['unknown corpus: ' corpus]);
end

if(strcmpi(mic,'twin'))
	levelNorm = -1;%level for noise signal to get SNR of 0dB
elseif(strcmpi(mic,'three'))
	levelNorm = 2;%level for noise signal to get SNR of 0dB
else
	error(['unknown microphone: ' mic]);
end
fId = fopen(filelistPath);
if(strcmpi(corpus,'samurai'))
	fileList = textscan(fId,'%s');
elseif(strcmpi(corpus,'apollo'))
	fileList = textscan(fId,'%s %*s');
end
fclose(fId);
fileNum = numel(fileList{1});
if(shortSet&&shortSetNum<fileNum)
	fileNum=shortSetNum;
end
if(~exist(resultDir,'dir'))
	mkdir(resultDir);
end
%delete([resultDir '/*.csv']);%delete previous results
system(['rename .csv .csv.old ' resultDir '*.csv']);%rename previous results
%if(~exist([resultDir 'cardioid'],'dir')) mkdir([resultDir 'cardioid']); end
%if(~exist([resultDir 'binMask'],'dir')) mkdir([resultDir 'binMask']); end
%if(~exist([resultDir 'sphere'],'dir')) mkdir([resultDir 'sphere']); end

for angleCnt = 1:numel(angles) % TODO remove
for levelCnt = 1:numel(levels)
	%reset mean snr
	snrImpAllCard=zeros(numel(angles),numel(distances));
	snrSphereAll=zeros(numel(angles),numel(distances));
	snrAllCard=zeros(numel(angles),numel(distances));
	snrImpAllBm=zeros(numel(angles),numel(distances));
	%snrBeforeAllBm=zeros(numel(angles),numel(distances));
	snrAllBm=zeros(numel(angles),numel(distances));
	for distCnt = 1:numel(distances)
		dirString = [num2str(angleCnt) num2str(levelCnt) num2str(distCnt)];
		%create subdirs of each noise level
		if(~exist([resultDir 'cardioid' dirString],'dir'))
			mkdir([resultDir 'cardioid' dirString]);
		end
		if(~exist([resultDir 'binMask' dirString],'dir'))
			mkdir([resultDir 'binMask' dirString]);
		end
		if(~exist([resultDir 'sphere' dirString],'dir'))
			mkdir([resultDir 'sphere' dirString]);
		end

	if(~doGetRemoteResults)
	for fileCnt=1:fileNum
		if(fileCnt>1)
			diary off;
		end
		file = fileList{1}{fileCnt};%get file from list
		if(strcmpi(corpus,'samurai'))
			file = [file '.wav'];
		end
		fileAbs = fullfile(signalPath,file);%concatenate file and path
		options.resultDir = resultDir;
		options.tmpDir = tmpDir;
		options.doTdRestore = true;
		options.doConvolution = true;
		options.inputSignals = {fileAbs,noiseFile};
		options.irDatabaseSampleRate = 16000;
		options.irDatabaseName = 'threeChanDMA';
		options.blockSize = 1024;
		options.timeShift = 512;
		if(strcmpi(mic,'twin'))
			options.irDatabaseName = 'twoChanMicHiRes';
			options.doTwinMicBeamforming = true;
			options.twinMic.beamformer.update = 0.2;
			options.twinMic.beamformer.angle = 60;
		elseif(strcmpi(mic,'three'))
			options.doADMA = true;
			options.adma.findMax = false;
			options.adma.findMin = false;
			options.adma.pattern = 'cardioid';
			options.adma.Mask = true;
			options.adma.speaker_range = speaker_angle+[-45 45];
			%options.adma.freqBand = [50 6000];
			options.adma.theta1 = speaker_angle;
			options.adma.theta2 = angles(angleCnt);
			options.adma.mask_update =0.2;
			options.adma.mask_angle = 0.9;
		end
		options.impulseResponses = struct(...
			'angle',{speaker_angle angles(angleCnt)}...
			...%,'distance',{sourceDist distances(distCnt)}...
			,'distance',{distances(distCnt) distances(distCnt)}...
			,'room','studio'...
			,'level',{0 levelNorm+levels(levelCnt)}...
			,'fileLocation'...
			,'/erk/daten1/uasr-data-feher/audio/Impulsantworten/3ChanDMA/'...
			,'length',-1);
		%beamforming
		[result opt] = start(options);

		if(strcmpi(mic,'twin'))
			[noi, snrCardioid, snrBinMask, snrSphere] = evalTwinMic(opt,result);
			snrCardImp = snrCardioid - snrSphere;
			snrBinImp = snrBinMask - snrSphere;
		elseif(strcmpi(mic,'three'))
			[snrCardImp, snrSphere, snrCardioid] = evalADMA(opt,result,2);
			[snrBinImp, snrSphere, snrBinMask] = evalADMA(opt,result,1);
		end
		snrImpAllCard(angleCnt,distCnt) =...
			snrImpAllCard(angleCnt,distCnt) + snrCardImp;
		snrSphereAll(angleCnt,distCnt) =...
			snrSphereAll(angleCnt,distCnt) + snrSphere;
		snrAllCard(angleCnt,distCnt) =...
			snrAllCard(angleCnt,distCnt) + snrCardioid;

		snrImpAllBm(angleCnt,distCnt) =...
			snrImpAllBm(angleCnt,distCnt) + snrBinImp;
		snrAllBm(angleCnt,distCnt) =...
			snrAllBm(angleCnt,distCnt) + snrBinMask;

		%%%%%output signal%%%%%
		%store signals (sphere, cardioid and binMask)
		%binMask
		signal = result.signal(1,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile([resultDir 'binMask' dirString],file);
		wavwrite(signal,opt.fs,wavName);
		%cardioid
		if(strcmpi(mic,'twin'))
			signal = result.input.signal(1,:).';
		elseif(strcmpi(mic,'three'))
			signal = result.signal(2,:).';
		end
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile([resultDir 'cardioid' dirString],file);
		wavwrite(signal,opt.fs,wavName);
		%sphere
		if(strcmpi(mic,'twin'))
			signal = sum(result.input.signal).';
		elseif(strcmpi(mic,'three'))
			signal = result.signal(3,:).';
		end
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile([resultDir 'sphere' dirString],file);
		wavwrite(signal,opt.fs,wavName);
	end%filCnt
	end%if(~doGetRemoteResults)
	diary on;

	%speech recognition for all three signals
	if(doSpeechRecog)
		clear options;
		if(exist('model','var')) options.speechRecognition.model = model; end
		options.doSpeechRecognition = true;
		options.speechRecognition.doRemote = doRemote;
		options.speechRecognition.doGetRemoteResults = doGetRemoteResults;
		options.speechRecognition.db = corpus;
		options.resultDir = [resultDir 'binMaskResult' dirString];
		options.speechRecognition.sigDir = ...
				[resultDir 'binMask' dirString];
		options.tmpDir = options.speechRecognition.sigDir;
		results = start(options);
		wrrBinMask(angleCnt,distCnt) = results.speechRecognition.wrr;
		wrrConfBinMask(angleCnt,distCnt) = results.speechRecognition.wrrConf;
		acrBinMask(angleCnt,distCnt) = results.speechRecognition.acr;
		acrConfBinMask(angleCnt,distCnt) = results.speechRecognition.acrConf;
		corBinMask(angleCnt,distCnt) = results.speechRecognition.cor;
		corConfBinMask(angleCnt,distCnt) = results.speechRecognition.corConf;
		latBinMask(angleCnt,distCnt) = results.speechRecognition.lat;
		latConfBinMask(angleCnt,distCnt) = results.speechRecognition.latConf;
		nBinMask(angleCnt,distCnt) = results.speechRecognition.n;
		options.resultDir = [resultDir 'cardioidResult' dirString];
		options.speechRecognition.sigDir = ...
				[resultDir 'cardioid' dirString];
		options.tmpDir = options.speechRecognition.sigDir;
		results = start(options);
		wrrCardioid(angleCnt,distCnt) = results.speechRecognition.wrr;
		wrrConfCardioid(angleCnt,distCnt) = results.speechRecognition.wrrConf;
		acrCardioid(angleCnt,distCnt) = results.speechRecognition.acr;
		acrConfCardioid(angleCnt,distCnt) = results.speechRecognition.acrConf;
		corCardioid(angleCnt,distCnt) = results.speechRecognition.cor;
		corConfCardioid(angleCnt,distCnt) = results.speechRecognition.corConf;
		latCardioid(angleCnt,distCnt) = results.speechRecognition.lat;
		latConfCardioid(angleCnt,distCnt) = results.speechRecognition.latConf;
		nCardioid(angleCnt,distCnt) = results.speechRecognition.n;
		options.resultDir = [resultDir 'sphereResult' dirString];
		options.speechRecognition.sigDir = ...
				[resultDir 'sphere' dirString];
		options.tmpDir = options.speechRecognition.sigDir;
		results = start(options);
		wrrSphere(angleCnt,distCnt) = results.speechRecognition.wrr;
		wrrConfSphere(angleCnt,distCnt) = results.speechRecognition.wrrConf;
		acrSphere(angleCnt,distCnt) = results.speechRecognition.acr;
		acrConfSphere(angleCnt,distCnt) = results.speechRecognition.acrConf;
		corSphere(angleCnt,distCnt) = results.speechRecognition.cor;
		corConfSphere(angleCnt,distCnt) = results.speechRecognition.corConf;
		latSphere(angleCnt,distCnt) = results.speechRecognition.lat;
		latConfSphere(angleCnt,distCnt) = results.speechRecognition.latConf;
		nSphere(angleCnt,distCnt) = results.speechRecognition.n;
		clear options;
	end%if(doSpeechRecog)
	end%distCnt

	if(doSpeechRecog)
		dlmwrite(fullfile(resultDir,'wrrSphere.csv')...
			,[(-1)*levels(levelCnt) wrrSphere(angleCnt,:) ...
			wrrConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrSphere.csv')...
			,[(-1)*levels(levelCnt) acrSphere(angleCnt,:) ...
			acrConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'corSphere.csv')...
			,[(-1)*levels(levelCnt) corSphere(angleCnt,:) ...
			corConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'latSphere.csv')...
			,[(-1)*levels(levelCnt) latSphere(angleCnt,:) ...
			latConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nSphere.csv')...
			,[(-1)*levels(levelCnt) nSphere(angleCnt,:)],'-append');

		dlmwrite(fullfile(resultDir,'wrrBinMask.csv')...
			,[(-1)*levels(levelCnt) wrrBinMask(angleCnt,:) ...
			wrrConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrBinMask.csv')...
			,[(-1)*levels(levelCnt) acrBinMask(angleCnt,:) ...
			acrConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'corBinMask.csv')...
			,[(-1)*levels(levelCnt) corBinMask(angleCnt,:) ...
			corConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'latBinMask.csv')...
			,[(-1)*levels(levelCnt) latBinMask(angleCnt,:) ...
			latConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nBinMask.csv')...
			,[(-1)*levels(levelCnt) nBinMask(angleCnt,:)],'-append');

		dlmwrite(fullfile(resultDir,'wrrCardioid.csv')...
			,[(-1)*levels(levelCnt) wrrCardioid(angleCnt,:) ...
			wrrConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrCardioid.csv')...
			,[(-1)*levels(levelCnt) acrCardioid(angleCnt,:) ...
			acrConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'corCardioid.csv')...
			,[(-1)*levels(levelCnt) corCardioid(angleCnt,:) ...
			corConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'latCardioid.csv')...
			,[(-1)*levels(levelCnt) latCardioid(angleCnt,:) ...
			latConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nCardioid.csv')...
			,[(-1)*levels(levelCnt) nCardioid(angleCnt,:)],'-append');
	end%if(doSpeechRecog)

	if(~doGetRemoteResults)
		dlmwrite(sprintf('%ssnrSphere.csv',resultDir)...
			,[(-1)*levels(levelCnt) snrSphereAll(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(sprintf('%ssnrCard.csv',resultDir)...
			,[(-1)*levels(levelCnt) snrAllCard(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(sprintf('%ssnrCardImp.csv',resultDir)...
			,[(-1)*levels(levelCnt) snrImpAllCard(angleCnt,:)...
			/fileNum],'-append');
		%dlmwrite(sprintf('%ssnrBinBefore.csv',resultDir)...
			%,[(-1)*levels(levelCnt) snrBeforeAllBm(angleCnt,:)...
			%/fileNum],'-append');
		dlmwrite(sprintf('%ssnrBin.csv',resultDir)...
			,[(-1)*levels(levelCnt) snrAllBm(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(sprintf('%ssnrBinImp.csv',resultDir)...
			,[(-1)*levels(levelCnt) snrImpAllBm(angleCnt,:)...
			/fileNum],'-append');
	end
end%levelCnt
end%angleCnt
diary off;
