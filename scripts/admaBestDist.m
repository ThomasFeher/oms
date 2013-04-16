clear all;
close all;
tic

%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));

%% SETTINGS
dbDir='/erk/daten2/uasr-data-common/ssmg/common/';
filelistPath = [dbDir 'flists/SAMURAI_0.flst'];
signalPath = [dbDir '/sig'];

%dbDir='/erk/daten2/uasr-maintenance/uasr-data/apollo/';
%filelistPath = [dbDir '1020.flst'];
%signalPath = [dbDir '/sig'];

resultDir = '/erk/tmp/feher/threeMicSpeechRecog/';
tmpDir = '/erk/tmp/feher/threeMicSpeechRecog/';
noiseFile = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';

options.resultDir = resultDir;
options.tmpDir = tmpDir;

%% PARAMETER
distances = [0.2,0.3,0.4,0.5,0.75,1];
speaker_angle = 0;
angles = 90;%[90:15:180]+speaker_angle;
shortSet = false;%process only first <shortSetNum> files
shortSetNum = 1;
doSpeechRecog = false;
levelNorm = 0;%level for noise signal to get SNR of 0dB

fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
fileNum = numel(fileList{1});
if(shortSet&&shortSetNum<fileNum) fileNum=shortSetNum;end
mkdir(tmpDir);
mkdir(resultDir);
mkdir([resultDir 'sphere']);
mkdir([resultDir 'cardioid']);
mkdir([resultDir 'binMask']);
diary([resultDir 'log.txt']);

distCnt = 1;
beta = 1;
for angleCnt = 1:numel(angles)
	%reset mean snr
	snrImpAllCard=zeros(numel(angles),numel(distances));
	snrBeforeAllCard=zeros(numel(angles),numel(distances));
	snrAfterAllCard=zeros(numel(angles),numel(distances));
	snrImpAllBm=zeros(numel(angles),numel(distances));
	snrBeforeAllBm=zeros(numel(angles),numel(distances));
	snrAfterAllBm=zeros(numel(angles),numel(distances));
	for distCnt = 1:numel(distances)
	for fileCnt=1:fileNum
		file = fileList{1}{fileCnt};%get file from list
		fileAbs = fullfile(signalPath,file);%concatenate file and path
		options.doTdRestore = true;
		options.doConvolution = true;
		options.inputSignals = {fileAbs,noiseFile};
		options.irDatabaseSampleRate = 16000;
		options.irDatabaseName = 'threeChanDMA';
		options.blockSize = 1024;
		options.timeShift = 512;
		options.doADMA = true;
		options.adma.findMax = false;
		options.adma.findMin = false;
		options.adma.Mask = true;
		options.adma.speaker_range=[-45 45];
		options.adma.freqBand = [50 6000];
		options.adma.zero_noise = false;	
		sourceDist = 1;
		%calculate amplification of second signal due to increased distance
		level = 20*log10(distances(distCnt)/sourceDist);
		options.impulseResponses = struct(...
		'angle',{speaker_angle angles(angleCnt)}...
		...%,'distance',{sourceDist distances(distCnt)}...
		,'distance',{distances(distCnt) distances(distCnt)}...
		,'room','studio',...
		...%'level',{0 levelNorm+level}...
		'level',{0 levelNorm}...
		,'fileLocation','/erk/daten1/uasr-data-feher/audio/Impulsantworten/3ChanDMA/'...
		,'length',-1);

		options.adma.theta1 = speaker_angle;% options.impulseResponses(1).angle;
		options.adma.theta2 = angles(angleCnt);%options.impulseResponses(2).angle;
		options.adma.mask_update =0.2;
		options.adma.mask_angle = 0.9;
		%beamforming
		[result opt] = start(options);
		%[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
		%snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);

		[snrCardImpBF, snrCardBeforeBF, snrCardAfterBF] =...
			evalADMA(opt,result,2);
		snrImpAllCard(angleCnt,distCnt) =...
			snrImpAllCard(angleCnt,distCnt) + snrCardImpBF;
		snrBeforeAllCard(angleCnt,distCnt) =...
			snrBeforeAllCard(angleCnt,distCnt) + snrCardBeforeBF;
		snrAfterAllCard(angleCnt,distCnt) =...
			snrAfterAllCard(angleCnt,distCnt) + snrCardAfterBF;

		[snrBinImpBF, snrBinBeforeBF, snrBinAfterBF] =...
			evalADMA(opt,result,1);
		snrImpAllBm(angleCnt,distCnt) =...
			snrImpAllBm(angleCnt,distCnt) + snrBinImpBF;
		snrBeforeAllBm(angleCnt,distCnt) =...
			snrBeforeAllBm(angleCnt,distCnt) + snrBinBeforeBF;
		snrAfterAllBm(angleCnt,distCnt) =...
			snrAfterAllBm(angleCnt,distCnt) + snrBinAfterBF;

		%%%%%output signal%%%%%
		%store signals (sphere, cardioid and binMask)
		signal = result.signal(1,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile([resultDir 'binMask'],file);
		wavwrite(signal,opt.fs,wavName);
		signal = result.signal(2,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile([resultDir 'cardioid'],file);
		wavwrite(signal,opt.fs,wavName);
		signal = result.signal(3,:).';
		signal = signal/max(abs(signal))*0.95;
		wavName = fullfile([resultDir 'sphere'],file);
		wavwrite(signal,opt.fs,wavName);
		%dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
	end%filCnt

	%speech recognition for all three signals
	if(doSpeechRecog)
		clear options;
		options.speechRecognition.db = 'samurai';
		options.doSpeechRecognition = true;
		options.resultDir = resultDir;
		options.tmpDir = tmpDir;
		options.speechRecognition.sigDir = [resultDir 'binMask'];
		results = start(options);
		wrrBinMask(angleCnt,distCnt) = results.speechRecognition.wrr;
		acrBinMask(angleCnt,distCnt) = results.speechRecognition.acr;
		farBinMask(angleCnt,distCnt) = results.speechRecognition.far;
		frrBinMask(angleCnt,distCnt) = results.speechRecognition.frr;
		nBinMask(angleCnt,distCnt) = results.speechRecognition.n;
		tpBinMask(angleCnt,distCnt) = results.speechRecognition.tp;
		fpBinMask(angleCnt,distCnt) = results.speechRecognition.fp;
		fnBinMask(angleCnt,distCnt) = results.speechRecognition.fn;
		tnBinMask(angleCnt,distCnt) = results.speechRecognition.tn;
		options.speechRecognition.sigDir = [resultDir 'cardioid'];
		results = start(options);
		wrrCardioid(angleCnt,distCnt) = results.speechRecognition.wrr;
		acrCardioid(angleCnt,distCnt) = results.speechRecognition.acr;
		farCardioid(angleCnt,distCnt) = results.speechRecognition.far;
		frrCardioid(angleCnt,distCnt) = results.speechRecognition.frr;
		nCardioid(angleCnt,distCnt) = results.speechRecognition.n;
		tpCardioid(angleCnt,distCnt) = results.speechRecognition.tp;
		fpCardioid(angleCnt,distCnt) = results.speechRecognition.fp;
		fnCardioid(angleCnt,distCnt) = results.speechRecognition.fn;
		tnCardioid(angleCnt,distCnt) = results.speechRecognition.tn;
		options.speechRecognition.sigDir = [resultDir 'sphere'];
		results = start(options);
		wrrSphere(angleCnt,distCnt) = results.speechRecognition.wrr;
		acrSphere(angleCnt,distCnt) = results.speechRecognition.acr;
		farSphere(angleCnt,distCnt) = results.speechRecognition.far;
		frrSphere(angleCnt,distCnt) = results.speechRecognition.frr;
		nSphere(angleCnt,distCnt) = results.speechRecognition.n;
		tpSphere(angleCnt,distCnt) = results.speechRecognition.tp;
		fpSphere(angleCnt,distCnt) = results.speechRecognition.fp;
		fnSphere(angleCnt,distCnt) = results.speechRecognition.fn;
		tnSphere(angleCnt,distCnt) = results.speechRecognition.tn;
		clear options;
	end%if(doSpeechRecog)
	end%distCnt

	if(doSpeechRecog)
		dlmwrite(fullfile(resultDir,'wrrSphere.txt')...
			,[angles(angleCnt) wrrSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrSphere.txt')...
			,[angles(angleCnt) acrSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'farSphere.txt')...
			,[angles(angleCnt) farSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'frrSphere.txt')...
			,[angles(angleCnt) frrSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nSphere.txt')...
			,[angles(angleCnt) nSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'tpSphere.txt')...
			,[angles(angleCnt) tpSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'fpSphere.txt')...
			,[angles(angleCnt) fpSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'fnSphere.txt')...
			,[angles(angleCnt) fnSphere(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'tnSphere.txt')...
			,[angles(angleCnt) tnSphere(angleCnt,:)],'-append');

		dlmwrite(fullfile(resultDir,'wrrBinMask.txt')...
			,[angles(angleCnt) wrrBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrBinMask.txt')...
			,[angles(angleCnt) acrBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'farBinMask.txt')...
			,[angles(angleCnt) farBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'frrBinMask.txt')...
			,[angles(angleCnt) frrBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nBinMask.txt')...
			,[angles(angleCnt) nBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'tpBinMask.txt')...
			,[angles(angleCnt) tpBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'fpBinMask.txt')...
			,[angles(angleCnt) fpBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'fnBinMask.txt')...
			,[angles(angleCnt) fnBinMask(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'tnBinMask.txt')...
			,[angles(angleCnt) tnBinMask(angleCnt,:)],'-append');

		dlmwrite(fullfile(resultDir,'wrrCardioid.txt')...
			,[angles(angleCnt) wrrCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'acrCardioid.txt')...
			,[angles(angleCnt) acrCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'farCardioid.txt')...
			,[angles(angleCnt) farCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'frrCardioid.txt')...
			,[angles(angleCnt) frrCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'nCardioid.txt')...
			,[angles(angleCnt) nCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'tpCardioid.txt')...
			,[angles(angleCnt) tpCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'fpCardioid.txt')...
			,[angles(angleCnt) fpCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'fnCardioid.txt')...
			,[angles(angleCnt) fnCardioid(angleCnt,:)],'-append');
		dlmwrite(fullfile(resultDir,'tnCardioid.txt')...
			,[angles(angleCnt) tnCardioid(angleCnt,:)],'-append');
	end%if(doSpeechRecog)

	dlmwrite(sprintf('%ssnrCardBefore.txt',resultDir)...
		,[angles(angleCnt) snrBeforeAllCard(angleCnt,:)...
		/fileNum],'-append');
	dlmwrite(sprintf('%ssnrCardAfter.txt',resultDir)...
		,[angles(angleCnt) snrAfterAllCard(angleCnt,:)...
		/fileNum],'-append');
	dlmwrite(sprintf('%ssnrCardImp.txt',resultDir)...
		,[angles(angleCnt) snrImpAllCard(angleCnt,:)...
		/fileNum],'-append');
	dlmwrite(sprintf('%ssnrBinBefore.txt',resultDir)...
		,[angles(angleCnt) snrBeforeAllBm(angleCnt,:)...
		/fileNum],'-append');
	dlmwrite(sprintf('%ssnrBinAfter.txt',resultDir)...
		,[angles(angleCnt) snrAfterAllBm(angleCnt,:)...
		/fileNum],'-append');
	dlmwrite(sprintf('%ssnrBinImp.txt',resultDir)...
		,[angles(angleCnt) snrImpAllBm(angleCnt,:)...
		/fileNum],'-append');
end%angleCnt
disp('total time:');
toc
diary off;
