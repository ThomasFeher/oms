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
distances = [0.4];
level = -10;
speaker_angle = 0;
angles = [0:15:180]+speaker_angle;
doSecondNoiseSource = true;
shortSet = false;%process only first <shortSetNum> files
shortSetNum = 0;%set to 0 and shortSet to true in order to use already
                %processed data
doSpeechRecog = true;
doSphereAndCardioidSpeechRecog = true;%only relevant in doSpeechRecog is set
doRemote = true;
doGetRemoteResults = false;%if true, only results of previous run are gathered
admaAlgo = 'wiener1';%'binMask','wiener1','wiener2','dist','nsIca','nsNlms'...
                   %,'nsFix','eight'
corpus = 'apollo';%'samurai','apollo';
mic = 'twin';%'twin', 'three'
model = 'adapt';%model to use for speech recognition: 'adapt', 'adaptNoise'
                     %any other strings or missing variable model will result in
                     %usage of the standart model '3_15'
                     %'adapt' uses the corresponding adapted model for each
                     %algorithm (sphere,adma,binMask)
                     %'adaptNoise' uses the corresponding 10dB SNR noise models
room = 'studio';%'studio' 'praktikum'
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

%create the algorithm name with first letter upper case
%admaAlgoUpCase = regexprep(admaAlgo,'(^.?)','${upper($1)}');
admaAlgoUpCase = [upper(admaAlgo(1)) admaAlgo(2:end)];

%start logging
diary(fullfile(resultDir,['log' admaAlgoUpCase '.txt']));%switch logging on

%display file name
disp(['script: ' mfilename]);

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
disp(sprintf('%d-%d-%d_%d:%d:%d',currentTime(1),currentTime(2)...
					,currentTime(3),currentTime(4),currentTime(5)...
					,fix(currentTime(6))));

%configure paths for speech corpora
if(strcmpi(corpus,'samurai'))
	dbDir='/erk/daten2/uasr-data-common/ssmg/common/';
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
if(strcmpi(mic,'twin'))
	if(strcmpi(room,'studio'))
		levelNorm = -1;%level for noise signal to get SNR of 0dB
		irDatabaseName = 'twoChanMicHiRes';
	elseif(strcmpi(room,'praktikum'))
		warning('calculate normalization level to get correct SNR values');
		levelNorm = 0;
		irDatabaseName = 'twoChanMic';
		angles = intersect(angles,anglesPraktikum);
		%get closest distance
		distDiff = distancesPraktikum - distances;
		[noi distIdx] = min(distDiff);
		distances = distancesPraktikum(distIdx);
	else
		error(['unknown room name: ' room ' for microphon: ' mic]);
	end
elseif(strcmpi(mic,'three'))
	if(strcmpi(room,'studio'))
		levelNorm = 2;%level for noise signal to get SNR of 0dB
		irDatabaseName = 'threeChanDMA';
	else
		error(['unknown room name: ' room ' for microphon: ' mic]);
	end
else
	error(['unknown microphone: ' mic]);
end

%set correct speech recognition model
binMaskModel = '3_15';
admaModel = '3_15';
sphereModel = '3_15';
if(exist('model','var') & strcmpi(model,'adapt'))
	if(strcmpi(admaAlgo,'binMask'))
		binMaskModel = ['3_15_A_' mic '_000_binMask_label'];
	elseif(regexpi(admaAlgo,'wiener'))
		binMaskModel = ['3_15_A_' mic '_000_wiener_label'];
	elseif(strcmpi(admaAlgo,'nsIca'))
		binMaskModel = ['3_15_A_' mic '_000_adma_label'];
	elseif(strcmpi(admaAlgo,'nsNlms'))
		binMaskModel = ['3_15_A_' mic '_000_adma_label'];
	elseif(strcmpi(admaAlgo,'nsFix'))
		binMaskModel = ['3_15_A_' mic '_000_adma_label'];
	elseif(strcmpi(admaAlgo,'eight'))
		binMaskModel = ['3_15_A_' mic '_000_adma_label'];
	else
		error(['unknown algorithm: ' admaAlgo]);
	end
	admaModel = ['3_15_A_' mic '_000_adma_label'];
	sphereModel = ['3_15_A_' mic '_000_sphere_label'];
elseif(exist('model','var') & strcmpi(model,'adaptNoise'))
	if(strcmpi(admaAlgo,'binMask'))
		binMaskModel = ['3_15_A_' mic '_000_binMask_noise_label'];
	elseif(regexpi(admaAlgo,'wiener'))
		binMaskModel = ['3_15_A_' mic '_000_wiener_noise_label'];
	elseif(strcmpi(admaAlgo,'nsIca'))
		binMaskModel = ['3_15_A_' mic '_000_adma_noise_label'];
	elseif(strcmpi(admaAlgo,'nsNlms'))
		binMaskModel = ['3_15_A_' mic '_000_adma_noise_label'];
	elseif(strcmpi(admaAlgo,'nsFix'))
		binMaskModel = ['3_15_A_' mic '_000_adma_noise_label'];
	elseif(strcmpi(admaAlgo,'eight'))
		binMaskModel = ['3_15_A_' mic '_000_adma_noise_label'];
	else
		error(['unknown algorithm: ' admaAlgo]);
	end
	admaModel = ['3_15_A_' mic '_000_adma_noise_label'];
	sphereModel = ['3_15_A_' mic '_000_sphere_noise_label'];
end

%set correct settings for adma algorithm
optionString = '';
if(strcmpi(admaAlgo,'binMask')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicBeamforming';
elseif(strcmpi(admaAlgo,'wiener1')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicWienerFiltering';
	optionString = ['options.twinMic.wienerFilter.signalPlusNoiseEstimate '...
					   '= ''cardioid'';'...
					'options.twinMic.wienerFilter.signalToFilter '...
						'= ''cardioid'';'];
elseif(strcmpi(admaAlgo,'wiener2')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicWienerFiltering';
	optionString = ['options.twinMic.wienerFilter.signalPlusNoiseEstimate '...
					   '= ''sphere'';'...
					'options.twinMic.wienerFilter.signalToFilter '...
						'= ''sphere'';'];
elseif(strcmpi(admaAlgo,'nsIca')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicNullSteering';
	optionString = ['options.twinMic.nullSteering.algorithm = ''ICA'';'...
					'options.twinMic.nullSteering.update = 0.1;'...
		            'options.twinMic.nullSteering.angle = angles(angleCnt);'...
					'options.twinMic.nullSteering.iterations = 1;'];
elseif(strcmpi(admaAlgo,'nsFix')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicNullSteering';
	optionString = ['options.twinMic.nullSteering.algorithm = ''fix'';'...
		            'options.twinMic.nullSteering.angle = angles(angleCnt);'];
elseif(strcmpi(admaAlgo,'nsNlms')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicNullSteering';
	optionString = ['options.twinMic.nullSteering.algorithm = ''NLMS'';'...
					'options.twinMic.nullSteering.mu = 0.01;'...
		            'options.twinMic.nullSteering.angle = angles(angleCnt);'...
					'options.twinMic.nullSteering.alpha = 0;'];
elseif(strcmpi(admaAlgo,'eight')&strcmpi(mic,'twin'))
	admaSwitch = 'doTwinMicNullSteering';
	optionString = ['options.twinMic.nullSteering.algorithm = ''fix'';'...
		            'options.twinMic.nullSteering.angle = 90;'];
elseif(strcmpi(admaAlgo,'binMask')&strcmpi(mic,'three'))
	admaSwitch = 'doADMA';
elseif(regexpi(admaAlgo,'wiener')&strcmpi(mic,'three'))
	error('not yet implemented');
else
	error(['unknown algorithm ' admaAlgo ' for microphone ' mic]);
end

fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
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

for angleCnt = 1:numel(angles)
	%reset mean snr
	snrImpAllCard=zeros(numel(angles),1);
	snrSphereAll=zeros(numel(angles),1);
	snrAllCard=zeros(numel(angles),1);
	snrImpAllBm=zeros(numel(angles),1);
	%snrBeforeAllBm=zeros(numel(angles),1);
	snrAllBm=zeros(numel(angles),1);
		disp(sprintf('current angle: %d',angles(angleCnt)));
		dirString = num2str(angleCnt);%current angle count as directory name
		%create subdirs of each noise level
		cardioidDir = [fullfile(resultDir,'cardioid') dirString];
		cardioidDirRemote = [fullfile(resultDirRemote,'cardioid') dirString];
		cardioidResultDir = [cardioidDir 'Result'];
		cardioidResultDirRemote = [cardioidDirRemote 'Result'];
		if(~exist(cardioidDir,'dir'))
			mkdir(cardioidDir);
		end
		admaDir = [fullfile(resultDir,admaAlgo) dirString];
		admaDirRemote = [fullfile(resultDirRemote,admaAlgo) dirString];
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
		file = fileList{1}{fileCnt};%get file from list
		fileAbs = fullfile(signalPath,file);%concatenate file and path
		options.(admaSwitch) = true;%set appropriate algo to true
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
		options.twinMic.beamformer.update = 0.2;
		options.twinMic.beamformer.angle = 60;
		options.twinMic.wienerFilter.update = 1;
		options.twinMic.nullSteering.angle = angles(angleCnt);
		options.adma.pattern = 'cardioid';
		options.adma.Mask = true;
		options.adma.theta1 = speaker_angle;
		%options.adma.theta2 = angles(angleCnt);
		options.adma.mask_update = 0.2;
		options.adma.mask_angle = 0.9;
		options.impulseResponses = struct(...
			'angle',{speaker_angle angles(angleCnt)}...
			,'distance',{distances distances}...
			,'room',room...
			,'level',{0 levelNorm+level}...
			,'length',-1);
		if(doSecondNoiseSource)
			options.inputSignals{3} = noiseFile2;
			ir3 = options.impulseResponses(2);%copy properties of 1st noise sig
			ir3.angle = 90;%change angle to 90 degree fixed
			%append modified parameters for second noise signal
			options.impulseResponses = [options.impulseResponses,ir3];
		end
		eval(optionString);%set appropriate options
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
		snrImpAllCard(angleCnt,1) =...
			snrImpAllCard(angleCnt,1) + snrCardImp;
		snrSphereAll(angleCnt,1) =...
			snrSphereAll(angleCnt,1) + snrSphere;
		snrAllCard(angleCnt,1) =...
			snrAllCard(angleCnt,1) + snrCardioid;

		snrImpAllBm(angleCnt,1) =...
			snrImpAllBm(angleCnt,1) + snrBinImp;
		snrAllBm(angleCnt,1) =...
			snrAllBm(angleCnt,1) + snrBinMask;

		%%%%%output signal%%%%%
		%store signals (sphere, cardioid and binMask)
		%binMask
		signal = result.signal(1,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile(admaDir,file);
		wavwrite(signal,opt.fs,wavName);
		%cardioid
		if(strcmpi(mic,'twin'))
			signal = result.input.signal(1,:).';
		elseif(strcmpi(mic,'three'))
			signal = result.signal(2,:).';
		end
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile(cardioidDir,file);
		wavwrite(signal,opt.fs,wavName);
		%sphere
		if(strcmpi(mic,'twin'))
			signal = sum(result.input.signal).';
		elseif(strcmpi(mic,'three'))
			signal = result.signal(3,:).';
		end
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile(sphereDir,file);
		wavwrite(signal,opt.fs,wavName);
	end%filCnt
	end%if(~doGetRemoteResults)

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
		options.speechRecognition.model = binMaskModel;
		options.resultDir = admaResultDir;
		options.speechRecognition.resultDirRemote = admaResultDirRemote;
		options.speechRecognition.sigDir = admaDir;
		options.speechRecognition.sigDirRemote = admaDirRemote;
		options.tmpDir = options.speechRecognition.sigDir;
		results = start(options);
		wrrBinMask(angleCnt,1) = results.speechRecognition.wrr;
		wrrConfBinMask(angleCnt,1) = results.speechRecognition.wrrConf;
		acrBinMask(angleCnt,1) = results.speechRecognition.acr;
		acrConfBinMask(angleCnt,1) = results.speechRecognition.acrConf;
		corBinMask(angleCnt,1) = results.speechRecognition.cor;
		corConfBinMask(angleCnt,1) = results.speechRecognition.corConf;
		latBinMask(angleCnt,1) = results.speechRecognition.lat;
		latConfBinMask(angleCnt,1) = results.speechRecognition.latConf;
		nBinMask(angleCnt,1) = results.speechRecognition.n;
		%cardioid
		if(doSphereAndCardioidSpeechRecog)
			options.speechRecognition.model = admaModel;
			options.resultDir = cardioidResultDir;
			options.speechRecognition.resultDirRemote = cardioidResultDirRemote;
			options.speechRecognition.sigDir = cardioidDir;
			options.speechRecognition.sigDirRemote = cardioidDirRemote;
			options.tmpDir = options.speechRecognition.sigDir;
			results = start(options);
			wrrCardioid(angleCnt,1) = results.speechRecognition.wrr;
			wrrConfCardioid(angleCnt,1) = results.speechRecognition.wrrConf;
			acrCardioid(angleCnt,1) = results.speechRecognition.acr;
			acrConfCardioid(angleCnt,1) = results.speechRecognition.acrConf;
			corCardioid(angleCnt,1) = results.speechRecognition.cor;
			corConfCardioid(angleCnt,1) = results.speechRecognition.corConf;
			latCardioid(angleCnt,1) = results.speechRecognition.lat;
			latConfCardioid(angleCnt,1) = results.speechRecognition.latConf;
			nCardioid(angleCnt,1) = results.speechRecognition.n;
			%sphere
			options.speechRecognition.model = sphereModel;
			options.resultDir = sphereResultDir;
			options.speechRecognition.resultDirRemote = sphereResultDirRemote;
			options.speechRecognition.sigDir = sphereDir;
			options.speechRecognition.sigDirRemote = sphereDirRemote;
			options.tmpDir = options.speechRecognition.sigDir;
			results = start(options);
			wrrSphere(angleCnt,1) = results.speechRecognition.wrr;
			wrrConfSphere(angleCnt,1) = results.speechRecognition.wrrConf;
			acrSphere(angleCnt,1) = results.speechRecognition.acr;
			acrConfSphere(angleCnt,1) = results.speechRecognition.acrConf;
			corSphere(angleCnt,1) = results.speechRecognition.cor;
			corConfSphere(angleCnt,1) = results.speechRecognition.corConf;
			latSphere(angleCnt,1) = results.speechRecognition.lat;
			latConfSphere(angleCnt,1) = results.speechRecognition.latConf;
			nSphere(angleCnt,1) = results.speechRecognition.n;
		end %if(doSphereAndCardioidSpeechRecog)
		clear options;
	end%if(doSpeechRecog)

	if(doSpeechRecog)
		dlmwrite(fullfile(resultDir,['wrr' admaAlgoUpCase '.csv'])...
			,[angles(angleCnt) wrrBinMask(angleCnt,:) ...
			wrrConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,['acr' admaAlgoUpCase '.csv'])...
			,[angles(angleCnt) acrBinMask(angleCnt,:) ...
			acrConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,['cor' admaAlgoUpCase '.csv'])...
			,[angles(angleCnt) corBinMask(angleCnt,:) ...
			corConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,['lat' admaAlgoUpCase '.csv'])...
			,[angles(angleCnt) latBinMask(angleCnt,:) ...
			latConfBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,['n' admaAlgoUpCase '.csv'])...
			,[angles(angleCnt) nBinMask(angleCnt,:)],'-append');

		if(doSphereAndCardioidSpeechRecog)
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
		end %if(doSphereAndCardioidSpeechRecog)
	end%if(doSpeechRecog)

	if(~doGetRemoteResults)
		dlmwrite(fullfile(resultDir,'snrSphere.csv')...
			,[angles(angleCnt) snrSphereAll(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,'snrCard.csv')...
			,[angles(angleCnt) snrAllCard(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,'snrCardImp.csv')...
			,[angles(angleCnt) snrImpAllCard(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,['snr' admaAlgoUpCase '.csv'])...
			,[angles(angleCnt) snrAllBm(angleCnt,:)...
			/fileNum],'-append');
		dlmwrite(fullfile(resultDir,['snr' admaAlgoUpCase 'Imp.csv'])...
			,[angles(angleCnt) snrImpAllBm(angleCnt,:)...
			/fileNum],'-append');
	end
end%angleCnt
%print time stamp to log file
currentTime = clock();
disp(sprintf('%d-%d-%d_%d:%d:%d',currentTime(1),currentTime(2)...
					,currentTime(3),currentTime(4),currentTime(5)...
					,fix(currentTime(6))));
diary off
