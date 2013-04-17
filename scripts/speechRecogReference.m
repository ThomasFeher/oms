clear all;
close all;

%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));

%% SETTINGS
resultDir = '/erk/tmp/feher/speechRecogReference/';
tmpDir = resultDir;

%%%%%PARAMETER%%%%%
distance = 0.4;
speaker_angle = 0;
%speaker_angle = 90;
shortSet = false;%process only first <shortSetNum> files
shortSetNum = 20;
corpus = 'samurai';%'samurai','apollo';
doBinMask = true;
doOrig = false;
doTwinRef = false;
doTwinStudio = true;
doThreeStudio = true;
origModel = '3_15_A_orig';%model name (only necessary if adpted model is used
twinRefModel = '3_15_A_twin_000_binMask_refRaum_label';%model name (only necessary if
												%adpted model is used
twinStudioModel = '3_15_A_twin_000_binMask_label';%model name (only necessary if
												%adpted model is used
threeStudioModel = '3_15_A_three_000_binMask_label';%model name (only necessary
													%if adpted model is used
doExternSpeechRecog = true;
doGetResults = true;%if true and doExternSpeechRecog=true, only results of
					%previous external experiment with equal parameters are
					%gathered
%%%%%PARAMETER%%%%%

sigDirOrig = [resultDir 'orig/'];
resultDirOrig = [resultDir 'origResult/'];
%logFileOrig = fullfile(resultDir,'logOrig.txt');
%resultFileOrig = 'resultOrig.txt';
%resultDirFileOrig = fullfile(resultDir,resultFileOrig);
sigDirTwinRef = [resultDir 'twinRef/'];
resultDirTwinRef = [resultDir 'twinRefResult/'];
%logFileTwinRef = fullfile(resultDir,'logTwinRef.txt');
%resultFileTwinRef = 'resultTwinRef.txt';
%resultDirFileTwinRef = fullfile(resultDir,resultFileTwinRef);
sigDirTwinStudio = [resultDir 'twinStudio/'];
resultDirTwinStudio = [resultDir 'twinStudioResult/'];
%logFileTwinStudio = fullfile(resultDir,'logTwinStudio.txt');
%resultFileTwinStudio = 'resultTwinStudio.txt';
%resultDirFileTwinStudio = fullfile(resultDir,resultFileTwinStudio);
sigDirThreeStudio = [resultDir 'threeStudio/'];
resultDirThreeStudio = [resultDir 'threeStudioResult/'];
%logFileThreeStudio = fullfile(resultDir,'logThreeStudio.txt');
%resultFileThreeStudio = 'resultThreeStudio.txt';
%resultDirFileThreeStudio = fullfile(resultDir,resultFileThreeStudio);

%if(~(doGetResults&&doExternSpeechRecog))
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

	fId = fopen(filelistPath);
	fileList = textscan(fId,'%s %s');
	fclose(fId);
	fileNum = numel(fileList{1});
	if(shortSet&&shortSetNum<fileNum) fileNum=shortSetNum;end
	if(~exist(tmpDir,'dir')) mkdir(tmpDir); end
	if(~exist(resultDir,'dir')) mkdir(resultDir); end
	if(~exist([resultDir 'orig'],'dir')) mkdir([resultDir 'orig']); end
	if(~exist([resultDir 'twinRef'],'dir')) mkdir([resultDir 'twinRef']); end
	if(~exist([resultDir 'twinStudio'],'dir'))
		mkdir([resultDir 'twinStudio']);
	end
	if(~exist([resultDir 'threeStudio'],'dir'))
		mkdir([resultDir 'threeStudio']);
	end
	diary([resultDir 'log.txt']);

if(~doGetResults)
	for fileCnt=1:fileNum
		%%%%%original%%%%%
		if(doOrig)
			file = fileList{1}{fileCnt};%get file from list
			if(strcmpi(corpus,'samurai')) file = [file '.wav']; end%append .wav
			fileAbs = fullfile(signalPath,file);%concatenate file and path
			wavName = fullfile([resultDir 'orig'],file);
			copyfile(fileAbs ,wavName);
		end

		%%%%%twinMicRef%%%%%
		if(doTwinRef)
			file = fileList{1}{fileCnt};%get file from list
			fileAbs = fullfile(signalPath,file);%concatenate file and path
			options.resultDir = resultDir;
			options.tmpDir = tmpDir;
			options.doTdRestore = true;
			options.doConvolution = true;
			options.doTwinMicNullSteering = ~doBinMask;
			options.doTwinMicBeamforming = doBinMask;
			options.twinMic.beamformer.angle = 60;
			options.twinMic.beamformer.update = 0.2;
			options.twinMic.nullSteering.algorithm = 'fix';
			options.twinMic.nullSteering.angle = 180;
			options.inputSignals = fileAbs;
			options.irDatabaseSampleRate = 16000;
			options.irDatabaseName = 'twoChanMicHiRes';
			options.blockSize = 1024;
			options.timeShift = 512;
			options.impulseResponses = struct(...
				'angle',speaker_angle ...
				,'distance',distance...
				,'room','refRaum'...
				,'level',0 ...
				,'length',-1);
			[result opt] = start(options);%processing
			%store sphere signal
			%signal = sum(result.input.signal).';
			%store processed signal
			signal = result.signal(1,:).';
			signal = signal/max(abs(signal))*0.95;
			wavName = fullfile([resultDir 'twinRef'],file);
			wavwrite(signal,opt.fs,wavName);
			clear options;
		end

		%%%%%twinMicStudio%%%%%
		if(doTwinStudio)
			file = fileList{1}{fileCnt};%get file from list
			fileAbs = fullfile(signalPath,file);%concatenate file and path
			options.resultDir = resultDir;
			options.tmpDir = tmpDir;
			options.doTdRestore = true;
			options.doConvolution = true;
			options.doTwinMicNullSteering = ~doBinMask;
			options.doTwinMicBeamforming = doBinMask;
			options.twinMic.beamformer.angle = 60;
			options.twinMic.beamformer.update = 0.2;
			options.twinMic.nullSteering.algorithm = 'fix';
			options.twinMic.nullSteering.angle = 180;
			options.inputSignals = fileAbs;
			options.irDatabaseSampleRate = 16000;
			options.irDatabaseName = 'twoChanMicHiRes';
			options.blockSize = 1024;
			options.timeShift = 512;
			options.impulseResponses = struct(...
				'angle',speaker_angle...
				,'distance',distance...
				,'room','studio'...
				,'level',0 ...
				,'length',-1);
			[result opt] = start(options);%processing
			%store sphere signal
			%signal = sum(result.input.signal).';
			%store processed signal
			signal = result.signal(1,:).';
			signal = signal/max(abs(signal))*0.95;
			wavName = fullfile([resultDir 'twinStudio'],file);
			wavwrite(signal,opt.fs,wavName);
			clear options;
		end

		%%%%%threeMic%%%%%
		if(doThreeStudio)
			file = fileList{1}{fileCnt};%get file from list
			fileAbs = fullfile(signalPath,file);%concatenate file and path
			options.resultDir = resultDir;
			options.tmpDir = tmpDir;
			options.doTdRestore = true;
			options.doConvolution = true;
			options.doADMA = true;
			options.inputSignals = fileAbs;
			options.irDatabaseSampleRate = 16000;
			options.irDatabaseName = 'threeChanDMA';
			options.blockSize = 1024;
			options.timeShift = 512;
			options.adma.findMax = false;
			options.adma.findMin = false;
			options.adma.pattern = 'cardioid';
			options.adma.Mask = doBinMask;
			options.adma.speaker_range = speaker_angle+[-45 45];
			options.adma.freqBand = [50 6000];
			options.adma.zero_noise = false;	
			options.adma.mask_update =0.2;
			options.adma.mask_angle = 0.9;
			options.impulseResponses = struct(...
				'angle',speaker_angle...
				,'distance',distance...
				,'room','studio'...
				,'level',0 ...
				,'fileLocation'...
				,'/erk/daten1/uasr-data-feher/audio/Impulsantworten/3ChanDMA/'...
				,'length',-1);
			[result opt] = start(options);%processing
			%store sphere signal
			%signal = result.signal(3,:).';
			%store processed signal
			signal = result.signal(1,:).';
			signal = signal/max(abs(signal))*0.95;
			wavName = fullfile([resultDir 'threeStudio'],file);
			wavwrite(signal,opt.fs,wavName);
			clear options;
		end
	end%filCnt
end%if(~doGetResults)

	%speech recognition for all three signals
	%if(doSpeechRecog)
	clear options;
	options.speechRecognition.db = corpus;
	options.doSpeechRecognition = true;
	options.speechRecognition.doRemote = doExternSpeechRecog;
	options.speechRecognition.doGetRemoteResults = doGetResults;
	%options.resultDir = resultDir;
	%options.tmpDir = tmpDir;
	%%%%%original%%%%%
	if(doOrig)
		%if(doExternSpeechRecog)
			%disp('copying files to remote machine...');
			%system(['ssh eakss1 mkdir -p ' resultDir]);%create log dir on
														%%remote machine
			%system(['ssh eakss1 mkdir -p ' sigDirOrig]);%create sig dir on
														%%remote machine
			%system(['scp ' sigDirOrig '/*.* eakss1://' sigDirOrig]...
				%,'-echo');%copy files
			%disp(['running uasr on remote machine, see local logfile <'...
				%logFileOrig '>']);
			%system(['ssh eakss1 "nohup perl '...
				%' ~/sim/framework/speechRecognizer.pl '...
				%sigDirOrig ' ' resultDir ' ' corpus ' ' resultFileOrig ' '...
				%origModel ' >' logFileOrig ' 2>&1 </dev/null & "']);
		%else
			if(exist('origModel','var'))
				options.speechRecognition.model = origModel;
			end
			options.speechRecognition.sigDir = sigDirOrig;
			%options.speechRecognition.tmpDir = sigDirOrig;
			options.resultDir = resultDirOrig;
			results = start(options);
			wrrOrig = results.speechRecognition.wrr;
			wrrConfOrig = results.speechRecognition.wrrConf;
			acrOrig = results.speechRecognition.acr;
			acrConfOrig = results.speechRecognition.acrConf;
			corOrig = results.speechRecognition.cor;
			corConfOrig = results.speechRecognition.corConf;
			latOrig = results.speechRecognition.lat;
			latConfOrig = results.speechRecognition.latConf;
			nOrig = results.speechRecognition.n;
		%end
	end

	%%%%%twinMicRef%%%%%
	if(doTwinRef)
		%if(doExternSpeechRecog)
			%disp('copying files to remote machine...');
			%system(['ssh eakss1 mkdir -p ' resultDir]);%create log dir on
														%%remote machine
			%system(['ssh eakss1 mkdir -p ' sigDirTwinRef]);%create sig dir on
															%%remote machine
			%system(['scp ' sigDirTwinRef '/*.* eakss1://' sigDirTwinRef]...
				%,'-echo');%copy files
			%disp(['running uasr on remote machine, see local logfile <'...
				%logFileTwinRef '>']);
			%system(['ssh eakss1 "nohup perl '...
				%' ~/sim/framework/speechRecognizer.pl '...
				%sigDirTwinRef ' ' resultDir ' ' corpus ' ' resultFileTwinRef...
				%' ' twinRefModel ' >' logFileTwinRef ' 2>&1 </dev/null & "']);
		%else
			if(exist('twinRefModel','var'))
				options.speechRecognition.model = twinRefModel;
			end
			options.speechRecognition.sigDir = sigDirTwinRef;
			%options.speechRecognition.tmpDir = sigDirTwinRef;
			options.resultDir = resultDirTwinRef;
			results = start(options);
			wrrTwinRef = results.speechRecognition.wrr;
			wrrConfTwinRef = results.speechRecognition.wrrConf;
			acrTwinRef = results.speechRecognition.acr;
			acrConfTwinRef = results.speechRecognition.acrConf;
			corTwinRef = results.speechRecognition.cor;
			corConfTwinRef = results.speechRecognition.corConf;
			latTwinRef = results.speechRecognition.lat;
			latConfTwinRef = results.speechRecognition.latConf;
			nTwinRef = results.speechRecognition.n;
		%end
	end

	%%%%%twinMicStudio%%%%%
	if(doTwinStudio)
		%if(doExternSpeechRecog)
			%disp('copying files to remote machine...');
			%system(['ssh eakss1 mkdir -p ' resultDir]);%create log dir on
														%%remote machine
			%system(['ssh eakss1 mkdir -p ' sigDirTwinStudio]);%create sig dir on
															%%remote machine
			%system(['scp ' sigDirTwinStudio '/*.* eakss1://' sigDirTwinStudio]...
				%,'-echo');%copy files
			%disp(['running uasr on remote machine, see local logfile <'...
				%logFileTwinStudio '>']);
			%system(['ssh eakss1 "nohup perl '...
				%' ~/sim/framework/speechRecognizer.pl ' sigDirTwinStudio ' '...
				%resultDir ' ' corpus ' ' resultFileTwinStudio ' '...
				   %twinStudioModel ' >' logFileTwinStudio ' 2>&1 </dev/null & "']);
		%else
			if(exist('twinStudioModel','var'))
				options.speechRecognition.model = twinStudioModel;
			end
			options.speechRecognition.sigDir = sigDirTwinStudio;
			%options.speechRecognition.tmpDir = sigDirTwinStudio;
			options.resultDir = resultDirTwinStudio;
			results = start(options);
			wrrTwinStudio = results.speechRecognition.wrr;
			wrrConfTwinStudio = results.speechRecognition.wrrConf;
			acrTwinStudio = results.speechRecognition.acr;
			acrConfTwinStudio = results.speechRecognition.acrConf;
			corTwinStudio = results.speechRecognition.cor;
			corConfTwinStudio = results.speechRecognition.corConf;
			latTwinStudio = results.speechRecognition.lat;
			latConfTwinStudio = results.speechRecognition.latConf;
			nTwinStudio = results.speechRecognition.n;
		%end
	end

	%%%%%threeMic%%%%%
	if(doThreeStudio)
		%if(doExternSpeechRecog)
			%disp('copying files to remote machine...');
			%system(['ssh eakss1 mkdir -p ' resultDir]);%create log dir on
														%%remote machine
			%system(['ssh eakss1 mkdir -p ' sigDirThreeStudio]);%create sig dir on
															%%remote machine
			%system(['scp ' sigDirThreeStudio '/*.* eakss1://' sigDirThreeStudio]...
				%,'-echo');%copy files
			%disp(['running uasr on remote machine, see local logfile <'...
				%logFileThreeStudio '>']);
			%system(['ssh eakss1 "nohup perl '...
				%' ~/sim/framework/speechRecognizer.pl ' sigDirThreeStudio ' '...
				%resultDir ' ' corpus ' ' resultFileThreeStudio ' '...
				   %threeStudioModel ' >' logFileThreeStudio ' 2>&1 </dev/null & "']);
		%else
			if(exist('threeStudioModel','var'))
				options.speechRecognition.model = threeStudioModel;
			end
			options.speechRecognition.sigDir = sigDirThreeStudio;
			%options.speechRecognition.tmpDir = sigDirThreeStudio;
			options.resultDir = resultDirThreeStudio;
			results = start(options);
			wrrThreeStudio = results.speechRecognition.wrr;
			wrrConfThreeStudio = results.speechRecognition.wrrConf;
			acrThreeStudio = results.speechRecognition.acr;
			acrConfThreeStudio = results.speechRecognition.acrConf;
			corThreeStudio = results.speechRecognition.cor;
			corConfThreeStudio = results.speechRecognition.corConf;
			latThreeStudio = results.speechRecognition.lat;
			latConfThreeStudio = results.speechRecognition.latConf;
			nThreeStudio = results.speechRecognition.n;
			clear options;
		%end
	end
%end%if(~(doGetResults&&doExternSpeechRecog))

%if(doExternSpeechRecog&&doGetResults)
	%if(doOrig)
		%disp('copying result files from remote machine...');
		%disp(['scp eakss1://' resultDirFileOrig ' ' resultDir]);
		%system(['scp eakss1://' resultDirFileOrig ' ' resultDir],'-echo');
		%resultOrig = getExternalResults(resultDirFileOrig);
		%nOrig = resultOrig.n;
		%wrrOrig = resultOrig.wrr;
		%wrrconfOrig = confidence(wrrOrig/100*nOrig,nOrig) * 100;
		%acrOrig = resultOrig.acr;
		%acrconfOrig = resultOrig.acrconf;
		%corOrig = resultOrig.cor;
		%corconfOrig = resultOrig.corconf;
		%latOrig = resultOrig.lat;
		%latconfOrig = resultOrig.latconf;
		%farOrig = NaN;
		%frrOrig = NaN;
		%tpOrig = NaN;
		%fpOrig = NaN;
		%fnOrig = NaN;
		%tnOrig = NaN;
	%end%if(doOrig)

	%if(doTwinRef)
		%disp('copying result files from remote machine...');
		%disp(['scp eakss1://' resultDirFileTwinRef ' ' resultDir]);
		%system(['scp eakss1://' resultDirFileTwinRef ' ' resultDir],'-echo');
		%resultTwinRef = getExternalResults(resultDirFileTwinRef);
		%nTwinRef = resultTwinRef.n;
		%wrrTwinRef = resultTwinRef.wrr;
		%wrrconfTwinRef = confidence(wrrTwinRef/100*nTwinRef,nTwinRef) * 100;
		%acrTwinRef = resultTwinRef.acr;
		%acrconfTwinRef = resultTwinRef.acrconf;
		%corTwinRef = resultTwinRef.cor;
		%corconfTwinRef = resultTwinRef.corconf;
		%latTwinRef = resultTwinRef.lat;
		%latconfTwinRef = resultTwinRef.latconf;
		%farTwinRef = NaN;
		%frrTwinRef = NaN;
		%tpTwinRef = NaN;
		%fpTwinRef = NaN;
		%fnTwinRef = NaN;
		%tnTwinRef = NaN;
	%end%if(doTwinRef)

	%if(doTwinStudio)
		%disp('copying result files from remote machine...');
		%disp(['scp eakss1://' resultDirFileTwinStudio ' ' resultDir]);
		%system(['scp eakss1://' resultDirFileTwinStudio ' ' resultDir],'-echo');
		%resultTwinStudio = getExternalResults(resultDirFileTwinStudio);
		%nTwinStudio = resultTwinStudio.n;
		%wrrTwinStudio = resultTwinStudio.wrr;
		%wrrconfTwinStudio =...
			%confidence(wrrTwinStudio/100*nTwinStudio,nTwinStudio) * 100;
		%acrTwinStudio = resultTwinStudio.acr;
		%acrconfTwinStudio = resultTwinStudio.acrconf;
		%corTwinStudio = resultTwinStudio.cor;
		%corconfTwinStudio = resultTwinStudio.corconf;
		%latTwinStudio = resultTwinStudio.lat;
		%latconfTwinStudio = resultTwinStudio.latconf;
		%farTwinStudio = NaN;
		%frrTwinStudio = NaN;
		%tpTwinStudio = NaN;
		%fpTwinStudio = NaN;
		%fnTwinStudio = NaN;
		%tnTwinStudio = NaN;
	%end%if(doTwinStudio)

	%if(doThreeStudio)
		%disp('copying result files from remote machine...');
		%disp(['scp eakss1://' resultDirFileThreeStudio ' ' resultDir]);
		%system(['scp eakss1://' resultDirFileThreeStudio ' ' resultDir],'-echo');
		%resultThreeStudio = getExternalResults(resultDirFileThreeStudio);
		%nThreeStudio = resultThreeStudio.n;
		%wrrThreeStudio = resultThreeStudio.wrr;
		%wrrconfThreeStudio =...
			%confidence(wrrThreeStudio/100*nThreeStudio,nThreeStudio) * 100;
		%acrThreeStudio = resultThreeStudio.acr;
		%acrconfThreeStudio = resultThreeStudio.acrconf;
		%corThreeStudio = resultThreeStudio.cor;
		%corconfThreeStudio = resultThreeStudio.corconf;
		%latThreeStudio = resultThreeStudio.lat;
		%latconfThreeStudio = resultThreeStudio.latconf;
		%farThreeStudio = NaN;
		%frrThreeStudio = NaN;
		%tpThreeStudio = NaN;
		%fpThreeStudio = NaN;
		%fnThreeStudio = NaN;
		%tnThreeStudio = NaN;
	%end%if(doThreeStudio)
%end%if(doExternSpeechRecog&&doGetResults)

%if(~doExternSpeechRecog||doGetResults)
	%%%%%original%%%%%
	if(doOrig)
		dlmwrite(fullfile(resultDir,'latOrig.txt')...
			,[latOrig latConfOrig],'-append');
		dlmwrite(fullfile(resultDir,'wrrOrig.txt')...
			,[wrrOrig wrrConfOrig],'-append');
		dlmwrite(fullfile(resultDir,'acrOrig.txt')...
			,[acrOrig acrConfOrig],'-append');
		dlmwrite(fullfile(resultDir,'corOrig.txt')...
			,[corOrig corConfOrig],'-append');
		%dlmwrite(fullfile(resultDir,'farOrig.txt')...
			%,[farOrig],'-append');
		%dlmwrite(fullfile(resultDir,'frrOrig.txt')...
			%,[frrOrig],'-append');
		dlmwrite(fullfile(resultDir,'nOrig.txt')...
			,[nOrig],'-append');
		%dlmwrite(fullfile(resultDir,'tpOrig.txt')...
			%,[tpOrig],'-append');
		%dlmwrite(fullfile(resultDir,'fpOrig.txt')...
			%,[fpOrig],'-append');
		%dlmwrite(fullfile(resultDir,'fnOrig.txt')...
			%,[fnOrig],'-append');
		%dlmwrite(fullfile(resultDir,'tnOrig.txt')...
			%,[tnOrig],'-append');
	end

	%%%%%twinMicRef%%%%%
	if(doTwinRef)
		dlmwrite(fullfile(resultDir,'latTwinRef.txt')...
			,[latTwinRef latConfTwinRef],'-append');
		dlmwrite(fullfile(resultDir,'wrrTwinRef.txt')...
			,[wrrTwinRef wrrConfTwinRef],'-append');
		dlmwrite(fullfile(resultDir,'acrTwinRef.txt')...
			,[acrTwinRef acrConfTwinRef],'-append');
		dlmwrite(fullfile(resultDir,'corTwinRef.txt')...
			,[corTwinRef corConfTwinRef],'-append');
		%dlmwrite(fullfile(resultDir,'farTwinRef.txt')...
			%,[farTwinRef],'-append');
		%dlmwrite(fullfile(resultDir,'frrTwinRef.txt')...
			%,[frrTwinRef],'-append');
		dlmwrite(fullfile(resultDir,'nTwinRef.txt')...
			,[nTwinRef],'-append');
		%dlmwrite(fullfile(resultDir,'tpTwinRef.txt')...
			%,[tpTwinRef],'-append');
		%dlmwrite(fullfile(resultDir,'fpTwinRef.txt')...
			%,[fpTwinRef],'-append');
		%dlmwrite(fullfile(resultDir,'fnTwinRef.txt')...
			%,[fnTwinRef],'-append');
		%dlmwrite(fullfile(resultDir,'tnTwinRef.txt')...
			%,[tnTwinRef],'-append');
	end

	%%%%%twinMicStudio%%%%%
	if(doTwinStudio)
		dlmwrite(fullfile(resultDir,'latTwinStudio.txt')...
			,[latTwinStudio latConfTwinStudio],'-append');
		dlmwrite(fullfile(resultDir,'wrrTwinStudio.txt')...
			,[wrrTwinStudio wrrConfTwinStudio],'-append');
		dlmwrite(fullfile(resultDir,'acrTwinStudio.txt')...
			,[acrTwinStudio acrConfTwinStudio],'-append');
		dlmwrite(fullfile(resultDir,'corTwinStudio.txt')...
			,[corTwinStudio corConfTwinStudio],'-append');
		%dlmwrite(fullfile(resultDir,'farTwinStudio.txt')...
			%,[farTwinStudio],'-append');
		%dlmwrite(fullfile(resultDir,'frrTwinStudio.txt')...
			%,[frrTwinStudio],'-append');
		dlmwrite(fullfile(resultDir,'nTwinStudio.txt')...
			,[nTwinStudio],'-append');
		%dlmwrite(fullfile(resultDir,'tpTwinStudio.txt')...
			%,[tpTwinStudio],'-append');
		%dlmwrite(fullfile(resultDir,'fpTwinStudio.txt')...
			%,[fpTwinStudio],'-append');
		%dlmwrite(fullfile(resultDir,'fnTwinStudio.txt')...
			%,[fnTwinStudio],'-append');
		%dlmwrite(fullfile(resultDir,'tnTwinStudio.txt')...
			%,[tnTwinStudio],'-append');
	end

	%%%%%threeMic%%%%%
	if(doThreeStudio)
		dlmwrite(fullfile(resultDir,'latThreeStudio.txt')...
			,[latThreeStudio latConfThreeStudio],'-append');
		dlmwrite(fullfile(resultDir,'wrrThreeStudio.txt')...
			,[wrrThreeStudio wrrConfThreeStudio],'-append');
		dlmwrite(fullfile(resultDir,'acrThreeStudio.txt')...
			,[acrThreeStudio acrConfThreeStudio],'-append');
		dlmwrite(fullfile(resultDir,'corThreeStudio.txt')...
			,[corThreeStudio corConfThreeStudio],'-append');
		%dlmwrite(fullfile(resultDir,'farThreeStudio.txt')...
			%,[farThreeStudio],'-append');
		%dlmwrite(fullfile(resultDir,'frrThreeStudio.txt')...
			%,[frrThreeStudio],'-append');
		dlmwrite(fullfile(resultDir,'nThreeStudio.txt')...
			,[nThreeStudio],'-append');
		%dlmwrite(fullfile(resultDir,'tpThreeStudio.txt')...
			%,[tpThreeStudio],'-append');
		%dlmwrite(fullfile(resultDir,'fpThreeStudio.txt')...
			%,[fpThreeStudio],'-append');
		%dlmwrite(fullfile(resultDir,'fnThreeStudio.txt')...
			%,[fnThreeStudio],'-append');
		%dlmwrite(fullfile(resultDir,'tnThreeStudio.txt')...
			%,[tnThreeStudio],'-append');
	end
%end%if(~doExternSpeechRecog||doGetResults)
diary off;
