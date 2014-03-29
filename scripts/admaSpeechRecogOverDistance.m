clear all;
close all;

omsDir = '~/Daten/Tom/oms/';
resultDir = '/erk/tmp/feher/twinAngle/';
resultDirRemote = '/erk/tmp/feher/home/';
tmpDir = resultDir;
noiseFile = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';
noiseFile2 = '/erk/daten1/uasr-data-feher/audio/nachrichten_10s.wav';
irDatabaseDir = '/erk/daten1/uasr-data-feher/audio/Impulsantworten/'
uasrPath = '~/Daten/Tom/uasr/';
uasrDataPath = '~/Daten/Tom/uasr-data/';

%%%%%parameters%%%%%
sourceDist = 0.05;
distances = [0.05,0.1,0.15,0.2,0.3,0.4,0.5,0.75,1];
level = -10;
speaker_angle = 0;
shortSet = false;%process only first <shortSetNum> files
shortSetNum = 0;%set to 0 and shortSet to true in order to use already
                %processed data
doSpeechRecog = true;
doDistSpeechRecog = false; % only relevant if doSpeechRecog is set
doSphereSpeechRecog = true; % only relevant if doSpeechRecog is set
doCardioidSpeechRecog = true; % only relevant if doSpeechRecog is set
doRemote = false; % do speech recognition at remote machine
doGetRemoteResults = false;%if true, only results of previous run are gathered
corpus = 'apollo';%'samurai','apollo';
model = '';%model to use for speech recognition:
                     % 3_15_A_twin_000_adma_label
                     % 3_15_A_twin_000_binMask_label
                     % 3_15_A_twin_000_binMask_noise_label
                     % 3_15_A_twin_000_adma_noise_label
					 % any other strings or missing variable model will result
					 % in usage of the standart model '3_15'
room = 'studio';%'studio' 'praktikum'
doStoreTmpData = false;%uses lots of space in tmpDir, but improves speed when
                      %run a second time with different algorithm
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
%3_15_A_twin_000_wiener_label.hmm
%3_15_A_twin_000_wiener_noise_label.hmm
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
diary(fullfile(resultDir,['logDist.txt']));%switch logging on

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
	filelistPath = [dbDir 'flists/SAMURAI_0.flst'];
	signalPath = [dbDir '/sig'];
elseif(strcmpi(corpus,'apollo'))
	dbDir = fullfile(uasrDataPath,'apollo/');
	filelistPath = [dbDir '1020.flst'];
	signalPath = [dbDir '/sig'];
else
	error(['unknown corpus: ' corpus]);
end

%set correct database
anglesPraktikum = [0:30:180];%all available angles for praktikum database
distancesPraktikum = [0.5 1.5];%all available distances for praktikum database
if(strcmpi(room,'studio'))
	levelNorm = -1;%level for noise signal to get SNR of 0dB
	irDatabaseName = 'twoChanMicHiRes';
elseif(strcmpi(room,'praktikum'))
	warning('calculate normalization level to get correct SNR values');
	levelNorm = 0;
	irDatabaseName = 'twoChanMic';
	%angles = intersect(angles,anglesPraktikum);
	%get closest distance
	distDiff = distancesPraktikum - distances;
	[noi distIdx] = min(distDiff);
	distances = distancesPraktikum(distIdx);
else
	error(['unknown room name: ' room]);
end

%set correct speech recognition model
binMaskModel = '3_15';
admaModel = '3_15';
sphereModel = '3_15';
if(exist('model','var') && ~isempty(model))
	binMaskModel = model;
	admaModel = model;
	sphereModel = model;
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
system(['rename .csv .csv.old ' resultDir '*.csv']);%rename previous results

for distCnt = 1:numel(distances)
	%reset mean snr
	snrImpAllCard=zeros(numel(distances),1);
	snrSphereAll=zeros(numel(distances),1);
	snrAllCard=zeros(numel(distances),1);
	snrImpAllBm=zeros(numel(distances),1);
	snrAllBm=zeros(numel(distances),1);
	disp(sprintf('current distance: %0.2f',distances(distCnt)));
	%current distance as directory name
	dirString = sprintf('%03d',distances(distCnt)*100);
	%create subdirs for each distance
	cardioidDir = [fullfile(resultDir,'cardioid') dirString];
	cardioidDirRemote = [fullfile(resultDirRemote,'cardioid') dirString];
	cardioidResultDir = [cardioidDir 'Result'];
	cardioidResultDirRemote = [cardioidDirRemote 'Result'];
	if(~exist(cardioidDir,'dir'))
		mkdir(cardioidDir);
	end
	admaDir = [fullfile(resultDir,'dist') dirString];
	admaDirRemote = [fullfile(resultDirRemote,'dist') dirString];
	admaResultDir = [admaDir 'Result'];
	admaResultDirRemote = [admaDirRemote 'Result'];
	if(~exist(admaDir,'dir'))
		mkdir(admaDir);
	end
	sphereDir = [fullfile(resultDir,'sphere') dirString];
	sphereDirRemote = [fullfile(resultDirRemote,'sphere') dirString];
	sphereResultDir = [sphereDir 'Result'];
	sphereResultDirRemote = [sphereDirRemote 'Result'];
	if(~exist(sphereDir,'dir'))
		mkdir(sphereDir);
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
		options.doDistanceFiltering = true;%set appropriate algo to true
		options.resultDir = resultDir;
		options.tmpDir = tmpDir;
		options.doTdRestore = true;
		options.doConvolution = true;
		options.inputSignals = {fileAbs,noiseFile};
		options.irDatabaseSampleRate = 16000;
		options.irDatabase.dir = irDatabaseDir;
		options.blockSize = 1024;
		options.timeShift = 512;
		options.irDatabaseName = irDatabaseName;
		levelDist = 20*log10(distances(distCnt)/sourceDist);
		options.impulseResponses = struct(...
			'angle',{speaker_angle speaker_angle}...
			,'distance',{sourceDist distances(distCnt)}...
			,'room',room...
			,'level',{0 levelNorm+level+levelDist}...
			,'length',-1);
		options.doFdStore = doStoreTmpData;
		% processing
		[result opt] = start(options);

		[noi, snrCardioid, snrBinMask, snrSphere] = evalTwinMic(opt,result);
		snrCardImp = snrCardioid - snrSphere;
		snrBinImp = snrBinMask - snrSphere;
		snrImpAllCard(distCnt,1) =...
			snrImpAllCard(distCnt,1) + snrCardImp;
		snrSphereAll(distCnt,1) =...
			snrSphereAll(distCnt,1) + snrSphere;
		snrAllCard(distCnt,1) =...
			snrAllCard(distCnt,1) + snrCardioid;

		snrImpAllBm(distCnt,1) =...
			snrImpAllBm(distCnt,1) + snrBinImp;
		snrAllBm(distCnt,1) =...
			snrAllBm(distCnt,1) + snrBinMask;

		%%%%%output signal%%%%%
		%store signals (sphere, cardioid and binMask)
		%binMask
		signal = result.signal(1,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile(admaDir,file);
		wavwrite(signal,opt.fs,wavName);
		%cardioid
		signal = result.input.signal(1,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile(cardioidDir,file);
		wavwrite(signal,opt.fs,wavName);
		%sphere
		signal = sum(result.input.signal).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile(sphereDir,file);
		wavwrite(signal,opt.fs,wavName);
	end%filCnt
	end%if(~doGetRemoteResults)
	diary on;

	%speech recognition for all three signals
	if(doSpeechRecog)
		clear options;
		%common options
		options.doSpeechRecognition = true;
		options.speechRecognition.doRemote = doRemote;
		options.speechRecognition.doGetRemoteResults = doGetRemoteResults;
		options.speechRecognition.db = corpus;
		options.speechRecognition.uasrPath = uasrPath;
		options.speechRecognition.uasrDataPath = uasrDataPath;
		%adma
		if(doDistSpeechRecog)
			options.speechRecognition.model = binMaskModel;
			options.resultDir = admaResultDir;
			options.speechRecognition.resultDirRemote = admaResultDirRemote;
			options.speechRecognition.sigDir = admaDir;
			options.speechRecognition.sigDirRemote = admaDirRemote;
			options.tmpDir = options.speechRecognition.sigDir;
			results = start(options);
			wrrBinMask(distCnt,1) = results.speechRecognition.wrr;
			wrrConfBinMask(distCnt,1) = results.speechRecognition.wrrConf;
			acrBinMask(distCnt,1) = results.speechRecognition.acr;
			acrConfBinMask(distCnt,1) = results.speechRecognition.acrConf;
			corBinMask(distCnt,1) = results.speechRecognition.cor;
			corConfBinMask(distCnt,1) = results.speechRecognition.corConf;
			latBinMask(distCnt,1) = results.speechRecognition.lat;
			latConfBinMask(distCnt,1) = results.speechRecognition.latConf;
			nBinMask(distCnt,1) = results.speechRecognition.n;
		end % doDistSpeechRecog
		%cardioid
		if(doCardioidSpeechRecog)
			options.speechRecognition.model = admaModel;
			options.resultDir = cardioidResultDir;
			options.speechRecognition.resultDirRemote = cardioidResultDirRemote;
			options.speechRecognition.sigDir = cardioidDir;
			options.speechRecognition.sigDirRemote = cardioidDirRemote;
			options.tmpDir = options.speechRecognition.sigDir;
			results = start(options);
			wrrCardioid(distCnt,1) = results.speechRecognition.wrr;
			wrrConfCardioid(distCnt,1) = results.speechRecognition.wrrConf;
			acrCardioid(distCnt,1) = results.speechRecognition.acr;
			acrConfCardioid(distCnt,1) = results.speechRecognition.acrConf;
			corCardioid(distCnt,1) = results.speechRecognition.cor;
			corConfCardioid(distCnt,1) = results.speechRecognition.corConf;
			latCardioid(distCnt,1) = results.speechRecognition.lat;
			latConfCardioid(distCnt,1) = results.speechRecognition.latConf;
			nCardioid(distCnt,1) = results.speechRecognition.n;
		end %if(doCardioidSpeechRecog)
		%sphere
		if(doSphereSpeechRecog)
			options.speechRecognition.model = sphereModel;
			options.resultDir = sphereResultDir;
			options.speechRecognition.resultDirRemote = sphereResultDirRemote;
			options.speechRecognition.sigDir = sphereDir;
			options.speechRecognition.sigDirRemote = sphereDirRemote;
			options.tmpDir = options.speechRecognition.sigDir;
			results = start(options);
			wrrSphere(distCnt,1) = results.speechRecognition.wrr;
			wrrConfSphere(distCnt,1) = results.speechRecognition.wrrConf;
			acrSphere(distCnt,1) = results.speechRecognition.acr;
			acrConfSphere(distCnt,1) = results.speechRecognition.acrConf;
			corSphere(distCnt,1) = results.speechRecognition.cor;
			corConfSphere(distCnt,1) = results.speechRecognition.corConf;
			latSphere(distCnt,1) = results.speechRecognition.lat;
			latConfSphere(distCnt,1) = results.speechRecognition.latConf;
			nSphere(distCnt,1) = results.speechRecognition.n;
		end %if(doSphereSpeechRecog)
		clear options;

		if(doDistSpeechRecog)
			dlmwrite(fullfile(resultDir,['wrrDist.csv'])...
				,[distances(distCnt) wrrBinMask(distCnt,:) ...
				wrrConfBinMask(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,['acrDist.csv'])...
				,[distances(distCnt) acrBinMask(distCnt,:) ...
				acrConfBinMask(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,['corDist.csv'])...
				,[distances(distCnt) corBinMask(distCnt,:) ...
				corConfBinMask(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,['latDist.csv'])...
				,[distances(distCnt) latBinMask(distCnt,:) ...
				latConfBinMask(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,['nDist.csv'])...
				,[distances(distCnt) nBinMask(distCnt,:)],'-append');
		end % if(doDistSpeechRecog)

		if(doCardioidSpeechRecog)
			dlmwrite(fullfile(resultDir,'wrrCardioid.csv')...
				,[distances(distCnt) wrrCardioid(distCnt,:) ...
				wrrConfCardioid(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'acrCardioid.csv')...
				,[distances(distCnt) acrCardioid(distCnt,:) ...
				acrConfCardioid(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'corCardioid.csv')...
				,[distances(distCnt) corCardioid(distCnt,:) ...
				corConfCardioid(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'latCardioid.csv')...
				,[distances(distCnt) latCardioid(distCnt,:) ...
				latConfCardioid(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'nCardioid.csv')...
				,[distances(distCnt) nCardioid(distCnt,:)],'-append');
		end %if(doCardioidSpeechRecog)

		if(doSphereSpeechRecog)
			dlmwrite(fullfile(resultDir,'wrrSphere.csv')...
				,[distances(distCnt) wrrSphere(distCnt,:) ...
				wrrConfSphere(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'acrSphere.csv')...
				,[distances(distCnt) acrSphere(distCnt,:) ...
				acrConfSphere(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'corSphere.csv')...
				,[distances(distCnt) corSphere(distCnt,:) ...
				corConfSphere(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'latSphere.csv')...
				,[distances(distCnt) latSphere(distCnt,:) ...
				latConfSphere(distCnt,:)],'-append');
			dlmwrite(fullfile(resultDir,'nSphere.csv')...
				,[distances(distCnt) nSphere(distCnt,:)],'-append');
		end %if(doSphereSpeechRecog)
	end%if(doSpeechRecog)

	if(~doGetRemoteResults)
		dlmwrite(fullfile(resultDir,'snrSphere.csv')...
			,[distances(distCnt) snrSphereAll(distCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,'snrCard.csv')...
			,[distances(distCnt) snrAllCard(distCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,'snrCardImp.csv')...
			,[distances(distCnt) snrImpAllCard(distCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,['snrDist.csv'])...
			,[distances(distCnt) snrAllBm(distCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,['snrDistImp.csv'])...
			,[distances(distCnt) snrImpAllBm(distCnt,:)...
			/fileNum],'-append');
	end
end%distCnt
%print time stamp to log file
currentTime = clock();
disp(sprintf('%d-%02d-%02d_%02d:%02d:%02d',currentTime(1),currentTime(2)...
					                      ,currentTime(3),currentTime(4)...
										  ,currentTime(5),fix(currentTime(6))));
diary off
