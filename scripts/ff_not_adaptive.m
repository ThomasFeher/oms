clear all;
close all;

%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));
%addpath([fileparts(fileparts(mfilename('fullpath'))) '/adma']);
%addpath([fileparts(fileparts(mfilename('fullpath'))) '/helper']);

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

%% PARAMETER
%distances = [1];
speaker_angle2 = 90;
angles =270:-15:90;%[-90 -120 -180]+speaker_angle; %[30 60 90 120 150 180];%[0:15:180];
%angles = 180;
fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
fileNum = numel(fileList{1});
if(~exist(tmpDir,'dir')) mkdir(tmpDir); end
if(~exist(resultDir,'dir')) mkdir(resultDir); end
if(~exist([resultDir 'cardioid'],'dir')) mkdir([resultDir 'cardioid']); end
if(~exist([resultDir 'binMask'],'dir')) mkdir([resultDir 'binMask']); end
if(~exist([resultDir 'sphere'],'dir')) mkdir([resultDir 'sphere']); end

%distCnt =[1 1];
beta = 1;
mask_angle =0:0.1:1;%60:10:180;

for angleCnt = 1:numel(angles)
  for distCnt = 1:numel(speaker_angle2)
	speaker_angle=speaker_angle2(distCnt)   ;
 for fileCnt=1:fileNum
			%for testing, do convolution for first file only
     % if(fileCnt>300) break; end;
			file = fileList{1}{fileCnt};%get file from list
			fileAbs = fullfile(signalPath,file);%concatenate file and path
			
      options.doLogfile = true;
      options.resultDir = resultDir;
      options.tmpDir = tmpDir;
      options.doTdRestore = true;
      options.doConvolution = true;
			options.inputSignals = {fileAbs,noiseFile};
			options.irDatabaseSampleRate = 16000;
			options.irDatabaseName = 'threeChanDMA';
			options.blockSize =1024;
      options.timeShift = 512;
      options.doADMA = true;
%      options.adma.findMax = true;
%      options.adma.findMin = true;
%	if (distCnt == 2)
	options.adma.findMax = false;
	options.adma.findMin = false;     
%	end;

	 options.adma.Mask = true;
      options.adma.speaker_range=speaker_angle+ [-45 45];
      options.adma.freqBand = [50 3000];
      options.adma.d = 24.8e-3;
      options.adma.zero_noise = false;	
     options.adma.search_range = 0:5:355;
	options.adma.doICA = false; 
      sourceDist = 0.3;
options.doSpeechRecognition = false;			
      %calculate amplification of second signal due to increased distance
      %level = 20*log10(distances(distCnt)/sourceDist)
      %level = 10;
      level = -10
			options.impulseResponses = ...
            struct('angle',       {ib(speaker_angle) ib(angles(angleCnt))},...
                   'distance',    {sourceDist sourceDist},...
                   'room',        'studio',...
                   'level',       {0, level},...
                   'fileLocation','~/Matlab/databases/3ChanDMA/',...
                   'length',      -1);

      options.adma.theta1 = speaker_angle;% options.impulseResponses(1).angle;
      options.adma.theta2 =angles(angleCnt);%options.impulseResponses(2).angle;
      options.adma.mask_update =0.2;
      options.adma.mask_angle = 0.9;
			%beamforming
			[result opt] = start(options);
			
      [snrCardImpBF(angleCnt,distCnt), ...
       snrCardBeforeBF(angleCnt,distCnt), ...
       snrCardAfterBF(angleCnt,distCnt)] = evalADMA(opt,result,2);

      [snrBinImpBF(angleCnt,distCnt), ...
       snrBinBeforeBF(angleCnt,distCnt), ...
       snrBinAfterBF(angleCnt,distCnt)] = evalADMA(opt,result,1);
     
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
clear options;
  options.doSpeechRecognition = true;
	options.resultDir = resultDir;
  options.speechRecognition.db = 'samurai';
    speech_recog = true;
	%speech recognition for all three signals
if (speech_recog)
	options.speechRecognition.sigDir = [resultDir 'binMask'];
	results = start(options);
	wrrBinMask(angleCnt,distCnt) = results.speechRecognition.wrr;
	corBinMask(angleCnt,distCnt) = results.speechRecognition.cor;
	corConfBinMask(angleCnt,distCnt) = results.speechRecognition.corConf;
	acrBinMask(angleCnt,distCnt) = results.speechRecognition.acr;
	acrConfBinMask(angleCnt,distCnt) = results.speechRecognition.acrConf;
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
	corCardioid(angleCnt,distCnt) = results.speechRecognition.cor;
	corConfCardioid(angleCnt,distCnt) = results.speechRecognition.corConf;
	acrCardioid(angleCnt,distCnt) = results.speechRecognition.acr;
	acrConfCardioid(angleCnt,distCnt) = results.speechRecognition.acrConf;
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
	corSphere(angleCnt,distCnt) = results.speechRecognition.cor;
	corConfSphere(angleCnt,distCnt) = results.speechRecognition.corConf;
	acrSphere(angleCnt,distCnt) = results.speechRecognition.acr;
	acrConfSphere(angleCnt,distCnt) = results.speechRecognition.acrConf;
	farSphere(angleCnt,distCnt) = results.speechRecognition.far;
	frrSphere(angleCnt,distCnt) = results.speechRecognition.frr;
	nSphere(angleCnt,distCnt) = results.speechRecognition.n;
	tpSphere(angleCnt,distCnt) = results.speechRecognition.tp;
	fpSphere(angleCnt,distCnt) = results.speechRecognition.fp;
	fnSphere(angleCnt,distCnt) = results.speechRecognition.fn;
	tnSphere(angleCnt,distCnt) = results.speechRecognition.tn;
	clear options;
	end
	end
if (speech_recog)
	dlmwrite(fullfile(resultDir,'wrrSphere.txt'),[angles(angleCnt) wrrSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'corSphere.txt'),[angles(angleCnt) corSphere(angleCnt,:) corConfSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'acrSphere.txt'),[angles(angleCnt) acrSphere(angleCnt,:) acrConfSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'farSphere.txt'),[angles(angleCnt) farSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'frrSphere.txt'),[angles(angleCnt) frrSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'nSphere.txt'),[angles(angleCnt) nSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'tpSphere.txt'),[angles(angleCnt) tpSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'fpSphere.txt'),[angles(angleCnt) fpSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'fnSphere.txt'),[angles(angleCnt) fnSphere(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'tnSphere.txt'),[angles(angleCnt) tnSphere(angleCnt,:)],'-append');

	dlmwrite(fullfile(resultDir,'wrrBinMask.txt'),[angles(angleCnt) wrrBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'corBinMask.txt'),[angles(angleCnt) corBinMask(angleCnt,:) corConfBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'acrBinMask.txt'),[angles(angleCnt) acrBinMask(angleCnt,:) acrConfBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'farBinMask.txt'),[angles(angleCnt) farBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'frrBinMask.txt'),[angles(angleCnt) frrBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'nBinMask.txt'),[angles(angleCnt) nBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'tpBinMask.txt'),[angles(angleCnt) tpBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'fpBinMask.txt'),[angles(angleCnt) fpBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'fnBinMask.txt'),[angles(angleCnt) fnBinMask(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'tnBinMask.txt'),[angles(angleCnt) tnBinMask(angleCnt,:)],'-append');

	dlmwrite(fullfile(resultDir,'wrrCardioid.txt'),[angles(angleCnt) wrrCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'corCardioid.txt'),[angles(angleCnt) corCardioid(angleCnt,:) corConfCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'acrCardioid.txt'),[angles(angleCnt) acrCardioid(angleCnt,:) acrConfCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'farCardioid.txt'),[angles(angleCnt) farCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'frrCardioid.txt'),[angles(angleCnt) frrCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'nCardioid.txt'),[angles(angleCnt) nCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'tpCardioid.txt'),[angles(angleCnt) tpCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'fpCardioid.txt'),[angles(angleCnt) fpCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'fnCardioid.txt'),[angles(angleCnt) fnCardioid(angleCnt,:)],'-append');
	dlmwrite(fullfile(resultDir,'tnCardioid.txt'),[angles(angleCnt) tnCardioid(angleCnt,:)],'-append');
end

  dlmwrite(sprintf('%ssnrCardBefore.txt',resultDir),[angles(angleCnt) snrCardBeforeBF(angleCnt,:)],'-append');
  dlmwrite(sprintf('%ssnrCardAfter.txt',resultDir),[angles(angleCnt) snrCardAfterBF(angleCnt,:)],'-append');
  dlmwrite(sprintf('%ssnrCardImp.txt',resultDir),[angles(angleCnt) snrCardImpBF(angleCnt,:)],'-append');

  dlmwrite(sprintf('%ssnrBinBefore.txt',resultDir),[angles(angleCnt) snrBinBeforeBF(angleCnt,:)],'-append');
  dlmwrite(sprintf('%ssnrBinAfter.txt',resultDir),[angles(angleCnt) snrBinAfterBF(angleCnt,:)],'-append');
  dlmwrite(sprintf('%ssnrBinImp.txt',resultDir),[angles(angleCnt) snrBinImpBF(angleCnt,:)],'-append');


end
