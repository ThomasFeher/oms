clear all;
close all;


%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath([fileparts(fileparts(mfilename('fullpath'))) '/adma']);
addpath([fileparts(fileparts(mfilename('fullpath'))) '/helper']);



%% SETTINGS
%Samurai Korpus
dbDir='/erk/daten2/uasr-data-common/ssmg/common/';
filelistPath = [dbDir 'flists/SAMURAI_0.flst'];
signalPath = [dbDir '/sig'];

%Apollo Korpus
%dbDir='/erk/daten2/uasr-maintenance/uasr-data/apollo/';
%filelistPath = [dbDir '1020.flst'];
%signalPath = [dbDir '/sig'];


resultDir = '/erk/tmp/ica/';
tmpDir = '/erk/tmp/ica/temporary/';
noiseFile = '~/Matlab/audio/nachrichten_female.wav';    %Stoersignal




%% PARAMETER
speaker_angle = 90;
angles =90:15:270;
fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
fileNum = numel(fileList{1});
mkdir(tmpDir);
mkdir(resultDir);
mkdir([resultDir 'ica']);

for angleCnt = 1:numel(angles)
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
      options.adma.findMax = false;
      options.adma.findMin = false;     
      options.adma.Mask = false;
      options.adma.d = 24.8e-3;
      options.adma.zero_noise = false;	
      options.adma.doICA = false; 
      
      sourceDist = 0.3;
      options.doSpeechRecognition = false;			
      level = -10;
			
      options.impulseResponses = ...
            struct('angle',       {limitAngle(speaker_angle) limitAngle(angles(angleCnt))},...
                   'distance',    {sourceDist sourceDist},...
                   'room',        'studio',...
                   'level',       {0, level},...
                   'fileLocation','~/Matlab/databases/3ChanDMA/',...
                   'length',      -1);

      options.adma.theta1 = 0;
      options.adma.theta2 = 180;
      
      
      [result opt] = start(options);

      %Preform ICA
      sigVecCard = result.adma.sigVecCard;
      
      signals = toTimeDomain(sigVecCard,3,opt.blockSize,opt.timeShift,opt.zeroPads,opt.blockNum);
      signals = real(signals);
      
      W=FastICA(signals,100);   %culculate weights
      
      x = W * signals;          %calculate unmixed signals
      
      x = 0.95 * x / max(max(x)); %normalize
      
      [noi idx] = min(sum(x(:,1:8000).^2,2) + sum(x(:,end-8000:end).^2,2)); %leistung am anfang u. ende des signals
  
   
			%%%%%output signal%%%%%
			%store signals (sphere, cardioid and binMask)
			signal = x(idx,:).';
			signal = signal/max(abs(signal))*0.95;
			wavName = fullfile([resultDir 'ica'],file);
			wavwrite(signal,opt.fs,wavName);
  end
  
  clear options;
  options.doSpeechRecognition = true;
	options.resultDir = resultDir;
  options.speechRecognition.db = 'samurai';
  speech_recog = true;
	
  %speech recognition for all three signals
  if (speech_recog)
    options.speechRecognition.sigDir = [resultDir 'ica'];
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
    clear options;

    dlmwrite(fullfile(resultDir,'wrr.txt'),[angles(angleCnt) wrrBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'cor.txt'),[angles(angleCnt) corBinMask(angleCnt,:) corConfBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'acr.txt'),[angles(angleCnt) acrBinMask(angleCnt,:) acrConfBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'far.txt'),[angles(angleCnt) farBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'frr.txt'),[angles(angleCnt) frrBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'n.txt'),[angles(angleCnt) nBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'tp.txt'),[angles(angleCnt) tpBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'fp.txt'),[angles(angleCnt) fpBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'fn.txt'),[angles(angleCnt) fnBinMask(angleCnt,:)],'-append');
    dlmwrite(fullfile(resultDir,'tn.txt'),[angles(angleCnt) tnBinMask(angleCnt,:)],'-append');

  end
end
