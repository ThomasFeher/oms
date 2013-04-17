clear all;
close all;

%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath([fileparts(fileparts(mfilename('fullpath'))) '/adma']);
addpath([fileparts(fileparts(mfilename('fullpath'))) '/helper']);

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
distances = [1];
speaker_angle = 90;
angles = [90:15:180]+speaker_angle; %[30 60 90 120 150 180];%[0:15:180];
%angles = 180;
shortSet = true;%process only first <shortSetNum> files
shortSetNum = 10;

fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
fileNum = numel(fileList{1});
mkdir(tmpDir);
mkdir(resultDir);
mkdir([resultDir 'sphere']);
mkdir([resultDir 'cardioid']);
mkdir([resultDir 'binMask']);

distCnt = 1;
beta = 1;
mask_angle =0:0.1:1;%60:10:180;%TODO: delete?
delay = [14.3]*10^-3;
for angleCnt = 1:numel(angles)
%	for distCnt = 1:numel(distances)
        %for distCnt = 1:numel(delay)	
	for fileCnt=1:fileNum
		%for testing, use a shorter set of first <shortSetNum> utterances only
		if(shortSet) if(fileCnt>shortSetNum) break; end; end;
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
		options.adma.d = delay(distCnt);
		options.adma.zero_noise = false;	
		%options.doDistanceFiltering = true;
		%options.distanceFilter.withGate = true;
		%options.distanceFilter.threshold = 1.1;
		%options.distanceFilter.update = 1;
		sourceDist = 1;
		%calculate amplification of second signal due to increased distance
		%			level = 20*log10(distances(distCnt)/sourceDist)
		%level = 10;
		level = 10
		options.impulseResponses = struct(...
		'angle',{speaker_angle angles(angleCnt)}...
		,'distance',{sourceDist sourceDist}...
		,'room','studio',...
		'level',{0 level}...
		,'fileLocation','/erk/daten1/uasr-data-feher/audio/Impulsantworten/3ChanDMA/'...
		,'length',-1);

		options.adma.theta1 = speaker_angle;% options.impulseResponses(1).angle;
		options.adma.theta2 = angles(angleCnt);%options.impulseResponses(2).angle;
		options.adma.mask_update =0.2;
		options.adma.mask_angle = 0.5;
		%beamforming
		[result opt] = start(options);
		%[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
		%snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);

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
	end

	%speech recognition for all three signals
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
	%rmdir(tmpDir);
	%mkdir(tmpDir);
%end

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
% 	dlmwrite(fullfile(resultDir,'farCardioid.txt')...
		%,[angles(angleCnt) farCardioid(angleCnt,:)],'-append');
% 	dlmwrite(fullfile(resultDir,'frrCardioid.txt')...
		%,[angles(angleCnt) frrCardioid(angleCnt,:)],'-append');
  	dlmwrite(fullfile(resultDir,'nCardioid.txt')...
		,[angles(angleCnt) nCardioid(angleCnt,:)],'-append');
% 	dlmwrite(fullfile(resultDir,'tpCardioid.txt')...
		%,[angles(angleCnt) tpCardioid(angleCnt,:)],'-append');
% 	dlmwrite(fullfile(resultDir,'fpCardioid.txt')...
		%,[angles(angleCnt) fpCardioid(angleCnt,:)],'-append');
% 	dlmwrite(fullfile(resultDir,'fnCardioid.txt')...
		%,[angles(angleCnt) fnCardioid(angleCnt,:)],'-append');
% 	dlmwrite(fullfile(resultDir,'tnCardioid.txt')...
		%,[angles(angleCnt) tnCardioid(angleCnt,:)],'-append');
end
%dlmwrite(sprintf('%sBefore.txt',resultDir),snrBeforeBF);
%dlmwrite(sprintf('%sAfter.txt',resultDir),snrAfterBF);
%dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);

%eopen(sprintf('%s/distPolarBeforeAfter.eps',resultDir));
%eglobpar;
%ePolarPlotAreaAngStart = 0;
%ePolarPlotAreaAngEnd = 180;
%ePolarAxisRadValueVisible = 0;
%ePolarAxisRadVisible = 0;
%epolaris(snrBeforeBF,ecolors(2),'w',[0 0 40]);
%ePolarPlotAreaAngStart = 180;
%ePolarPlotAreaAngEnd = 360;
%ePolarAxisAngScale = [180 0 0];
%ePolarAxisRadVisible = 3;
%ePolarAxisRadValueVisible = 3;
%ePolarAxisRadScale = [0 0 1];
%%TODO plot recognition result
%%epolaris(snrAfterBF(:,end:-1:1),ecolors(2),'w',[0 0 40]);
%eclose;
%newbbox = ebbox(1);
