clear all;
close all;

%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));

resultDir = '/erk/tmp/feher/threeMicSpeechRecog/';
%resultDir = '/erk/tmp/feher/speechRecogAdapt2/';
noiseFile = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';

%%%%%parameters%%%%%
distances = [0.5];
%levels = [5,0,-5,-10,-15,-20,-25,-30];
level = -10;
speaker_angle = 0;
%speaker_angle = 90;
%angles = [0:15:180]+speaker_angle;
angles = [0:30:180]+speaker_angle;
shortSet = true;%process only first <shortSetNum> files
shortSetNum = 0;
doSpeechRecog = true;
doRemote = true;
doGetRemoteResults = true;%if true, only results of previous run are gathered
corpus = 'apollo';%'samurai','apollo';
mic = 'twin';%'twin', 'three'
model = 'adaptNoise';%model to use for speech recognition: 'adapt', 'adaptNoise'
					%any other strings or missing variable model will result in
					%usage of the standart model '3_15'
					%'adapt' uses the corresponding adapted model for each
					%algorithm (sphere,adma,binMask)
					%'adaptNoise' uses the corresponding 10dB SNR noise models
irDatabaseName = 'twoChanMic';% 'twoChanMicHiRes', 'twoChanMic'
								%only used if mic = 'twin'
room = 'praktikum';%'studio' 'praktikum'
%%%%%parameters%%%%%

%models:
%3_15_A_orig.hmm
%3_15_A_three_000_adma.hmm
%3_15_A_three_000_adma_label.hmm
%3_15_A_three_000_adma_noise_label.hmm
%3_15_A_three_000_binMask.hmm
%3_15_A_three_000_binMask_label.hmm
%3_15_A_three_000_binMask_noise_label.hmm
%3_15_A_three_000_sphere_label.hmm
%3_15_A_three_000_sphere_noise_label.hmm
%3_15_A_twin_000_adma.hmm
%3_15_A_twin_000_adma_label.hmm
%3_15_A_twin_000_adma_noise_label.hmm
%3_15_A_twin_000_adma_refRaum.hmm
%3_15_A_twin_000_adma_refRaum_label.hmm
%3_15_A_twin_000_binMask.hmm
%3_15_A_twin_000_binMask_label.hmm
%3_15_A_twin_000_binMask_noise_label.hmm
%3_15_A_twin_000_sphere_label.hmm
%3_15_A_twin_000_sphere_noise_label.hmm
%3_15.hmm

if(strcmpi(corpus,'samurai'))
	dbDir='/erk/daten2/uasr-data-common/ssmg/common/';
	filelistPath = [dbDir 'flists/SAMURAI_0.flst'];
	signalPath = [dbDir '/sig'];
elseif(strcmpi(corpus,'apollo'))
	dbDir='/erk/daten2/uasr-maintenance/uasr-data/apollo/';
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

binMaskModel = '3_15';
admaModel = '3_15';
sphereModel = '3_15';
if(exist('model','var') & strcmpi(model,'adapt'))
	binMaskModel = ['3_15_A_' mic '_000_binMask_label'];
	admaModel = ['3_15_A_' mic '_000_adma_label'];
	sphereModel = ['3_15_A_' mic '_000_sphere_label'];
elseif(exist('model','var') & strcmpi(model,'adaptNoise'))
	binMaskModel = ['3_15_A_' mic '_000_binMask_noise_label'];
	admaModel = ['3_15_A_' mic '_000_adma_noise_label'];
	sphereModel = ['3_15_A_' mic '_000_sphere_noise_label'];
end

fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
fclose(fId);
fileNum = numel(fileList{1});
if(shortSet&&shortSetNum<fileNum) fileNum=shortSetNum;end
if(~exist(resultDir,'dir')) mkdir(resultDir); end
%delete([resultDir '/*.csv']);%delete previous results
system(['rename .csv .csv.old ' resultDir '*.csv']);%rename previous results
%if(~exist([resultDir 'cardioid'],'dir')) mkdir([resultDir 'cardioid']); end
%if(~exist([resultDir 'binMask'],'dir')) mkdir([resultDir 'binMask']); end
%if(~exist([resultDir 'sphere'],'dir')) mkdir([resultDir 'sphere']); end
if(~doGetRemoteResults) diary([resultDir 'log.txt']); end

%distCnt = 1;
for angleCnt = 1:numel(angles)
	%reset mean snr
	snrImpAllCard=zeros(numel(angles),numel(distances));
	snrSphereAll=zeros(numel(angles),numel(distances));
	snrAllCard=zeros(numel(angles),numel(distances));
	snrImpAllBm=zeros(numel(angles),numel(distances));
	%snrBeforeAllBm=zeros(numel(angles),numel(distances));
	snrAllBm=zeros(numel(angles),numel(distances));
	for distCnt = 1:numel(distances)
		dirString = num2str(angleCnt);
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
		file = fileList{1}{fileCnt};%get file from list
		fileAbs = fullfile(signalPath,file);%concatenate file and path
		options.resultDir = resultDir;
		options.tmpDir = resultDir;
		options.doTdRestore = true;
		options.doConvolution = true;
		options.inputSignals = {fileAbs,noiseFile};
		options.irDatabaseSampleRate = 16000;
		options.blockSize = 1024;
		options.timeShift = 512;
		if(strcmpi(mic,'twin'))
			options.irDatabaseName = irDatabaseName;
			options.doTwinMicBeamforming = true;
			options.twinMic.beamformer.update = 0.2;
			options.twinMic.beamformer.angle = 60;
		elseif(strcmpi(mic,'three'))
			options.irDatabaseName = 'threeChanDMA';
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
		%sourceDist = 1;
		%calculate amplification of second signal due to increased distance
		%levelDist = 20*log10(distances(distCnt)/sourceDist);
		options.impulseResponses = struct(...
			'angle',{speaker_angle angles(angleCnt)}...
			...%,'distance',{sourceDist distances(distCnt)}...
			,'distance',{distances(distCnt) distances(distCnt)}...
			,'room',room...
			,'level',{0 levelNorm+level}...
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

	%speech recognition for all three signals
	if(doSpeechRecog)
		clear options;
		%if(exist('model','var')) options.speechRecognition.model = model; end
		%binary masking
		options.doSpeechRecognition = true;
		options.speechRecognition.doRemote = doRemote;
		options.speechRecognition.doGetRemoteResults = doGetRemoteResults;
		options.speechRecognition.db = corpus;
		options.speechRecognition.model = binMaskModel;
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
		%adma
		options.speechRecognition.model = admaModel;
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
		%sphere
		options.speechRecognition.model = sphereModel;
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
			,[angles(angleCnt) wrrSphere(angleCnt,:) ...
			wrrConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrSphere.csv')...
			,[angles(angleCnt) acrSphere(angleCnt,:) ...
			acrConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'corSphere.csv')...
			,[angles(angleCnt) corSphere(angleCnt,:) ...
			corConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'latSphere.csv')...
			,[angles(angleCnt) latSphere(angleCnt,:) ...
			latConfSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nSphere.csv')...
			,[angles(angleCnt) nSphere(angleCnt,:)],'-append');

		dlmwrite(fullfile(resultDir,'wrrBinMask.csv')...
			,[angles(angleCnt) wrrBinMask(angleCnt,:) ...
			wrrConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrBinMask.csv')...
			,[angles(angleCnt) acrBinMask(angleCnt,:) ...
			acrConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'corBinMask.csv')...
			,[angles(angleCnt) corBinMask(angleCnt,:) ...
			corConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'latBinMask.csv')...
			,[angles(angleCnt) latBinMask(angleCnt,:) ...
			latConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nBinMask.csv')...
			,[angles(angleCnt) nBinMask(angleCnt,:)],'-append');

		dlmwrite(fullfile(resultDir,'wrrCardioid.csv')...
			,[angles(angleCnt) wrrCardioid(angleCnt,:) ...
			wrrConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrCardioid.csv')...
			,[angles(angleCnt) acrCardioid(angleCnt,:) ...
			acrConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'corCardioid.csv')...
			,[angles(angleCnt) corCardioid(angleCnt,:) ...
			corConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'latCardioid.csv')...
			,[angles(angleCnt) latCardioid(angleCnt,:) ...
			latConfCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nCardioid.csv')...
			,[angles(angleCnt) nCardioid(angleCnt,:)],'-append');
	end%if(doSpeechRecog)

	if(~doGetRemoteResults)
		dlmwrite(sprintf('%ssnrSphere.csv',resultDir)...
			,[angles(angleCnt) snrSphereAll(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(sprintf('%ssnrCard.csv',resultDir)...
			,[angles(angleCnt) snrAllCard(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(sprintf('%ssnrCardImp.csv',resultDir)...
			,[angles(angleCnt) snrImpAllCard(angleCnt,:)...
			/fileNum],'-append');
		%dlmwrite(sprintf('%ssnrBinBefore.csv',resultDir)...
			%,[angles(angleCnt) snrBeforeAllBm(angleCnt,:)...
			%/fileNum],'-append');
		dlmwrite(sprintf('%ssnrBin.csv',resultDir)...
			,[angles(angleCnt) snrAllBm(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(sprintf('%ssnrBinImp.csv',resultDir)...
			,[angles(angleCnt) snrImpAllBm(angleCnt,:)...
			/fileNum],'-append');
	end
end%angleCnt
diary off;
