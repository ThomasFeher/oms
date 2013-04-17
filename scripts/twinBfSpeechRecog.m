clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

%%%%%%%%%%+options%%%%%%%%%%
database = 'samurai';% 'samurai' or 'apollo'
resultDir = '/erk/tmp/feher/twinBfSpeechRecog/';
%noiseFile = '/erk/daten1/uasr-data-feher/audio/noise_pink_10s_16kHz.wav';
noiseFile1 = '/erk/daten1/uasr-data-feher/audio/nachrichten_female.wav';
noiseFile2 = '/erk/daten1/uasr-data-feher/audio/nachrichten_10s.wav';
shortSet = false;%process only first 100 files
distances = [1];%[0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];%noise distances
sourceDist = 1;
angles = [0:15:180];%[15 45 75 105 135 165];%[0:15:180];
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
mkdir(resultDir);mkdir([resultDir 'sphere']);
mkdir([resultDir 'cardioid']);
mkdir([resultDir 'binMask']);

for angleCnt = 1:numel(angles)
	for distCnt = 1:numel(distances)
		for fileCnt=1:fileNum
			%for testing, use a shorter set of first 100 utterances only
			if(shortSet) if(fileCnt>100) break; end; end;
			%for testing, do convolution for first file only
			%if(fileCnt>1) return; end;
			file = fileList{1}{fileCnt};%get file from list
			fileAbs = fullfile([sigDir 'sig'],file);%concatenate file and path
			options.doTdRestore = true;
			options.doConvolution = true;
			%options.inputSignals = {fileAbs};
			options.inputSignals = {fileAbs,noiseFile1,noiseFile2};
			options.irDatabaseSampleRate = 16000;
			options.irDatabaseName = 'twoChanMicHiRes';
			options.blockSize = 1024;
			options.timeShift = 512;
			options.doTwinMicNullSteering = true;
			%options.doTwinMicBeamforming = true;
			%options.twinMic.beamformer.angle = 60;
			%options.twinMic.beamformer.update = 0.2;
			%calculate amplification of second signal due to increased distance
			level = 20*log10(distances(distCnt)/sourceDist);
			%options.impulseResponses = struct('angle',0,...
			%'distance',1,'room','studio',...
			%'level',0);
			options.impulseResponses = struct('angle',{0 90 angles(angleCnt)},...
			'distance',{sourceDist sourceDist distances(distCnt)},'room','studio',...
			'level',{0 0 level},'length',-1);

			%beamforming
			[result opt] = start(options);
			%[snrImpBF(distCnt,angleCnt),snrBeforeBF(distCnt,angleCnt),...
			%snrAfterBF(distCnt,angleCnt)] = evalTwinMic(opt,result);

			%%%%%output signal%%%%%
			%store signals (sphere, cardioid and binMask)
			signal = result.signal(1,:).';
			signal = signal/max(abs(signal));
			wavName = fullfile([resultDir 'binMask'],file);
			wavwrite(signal,opt.fs,wavName);
			signal = result.input.signal(1,:).';
			signal = signal/max(abs(signal));
			wavName = fullfile([resultDir 'cardioid'],file);
			wavwrite(signal,opt.fs,wavName);
			signal = sum(result.input.signal).';
			signal = signal/max(abs(signal));
			wavName = fullfile([resultDir 'sphere'],file);
			wavwrite(signal,opt.fs,wavName);
			%dlmwrite(sprintf('%sImp.txt',resultDir),snrImpBF);
		end

	%speech recognition for all three signals
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
	%options.speechRecognition.sigDir = [resultDir 'cardioid'];
	%results = start(options);
	%wrrCardioid(angleCnt,distCnt) = results.speechRecognition.wrr;
	%corCardioid(angleCnt,distCnt) = results.speechRecognition.cor;
	%corConfCardioid(angleCnt,distCnt) = results.speechRecognition.corConf;
	%acrCardioid(angleCnt,distCnt) = results.speechRecognition.acr;
	%acrConfCardioid(angleCnt,distCnt) = results.speechRecognition.acrConf;
	%farCardioid(angleCnt,distCnt) = results.speechRecognition.far;
	%frrCardioid(angleCnt,distCnt) = results.speechRecognition.frr;
	%nCardioid(angleCnt,distCnt) = results.speechRecognition.n;
	%tpCardioid(angleCnt,distCnt) = results.speechRecognition.tp;
	%fpCardioid(angleCnt,distCnt) = results.speechRecognition.fp;
	%fnCardioid(angleCnt,distCnt) = results.speechRecognition.fn;
	%tnCardioid(angleCnt,distCnt) = results.speechRecognition.tn;
	%options.speechRecognition.sigDir = [resultDir 'sphere'];
	%results = start(options);
	%wrrSphere(angleCnt,distCnt) = results.speechRecognition.wrr;
	%corSphere(angleCnt,distCnt) = results.speechRecognition.cor;
	%corConfSphere(angleCnt,distCnt) = results.speechRecognition.corConf;
	%acrSphere(angleCnt,distCnt) = results.speechRecognition.acr;
	%acrConfSphere(angleCnt,distCnt) = results.speechRecognition.acrConf;
	%farSphere(angleCnt,distCnt) = results.speechRecognition.far;
	%frrSphere(angleCnt,distCnt) = results.speechRecognition.frr;
	%nSphere(angleCnt,distCnt) = results.speechRecognition.n;
	%tpSphere(angleCnt,distCnt) = results.speechRecognition.tp;
	%fpSphere(angleCnt,distCnt) = results.speechRecognition.fp;
	%fnSphere(angleCnt,distCnt) = results.speechRecognition.fn;
	%tnSphere(angleCnt,distCnt) = results.speechRecognition.tn;
	clear options;
	end

	%dlmwrite(fullfile(resultDir,'wrrSphere.txt'),[angles(angleCnt) wrrSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'corSphere.txt'),[angles(angleCnt) corSphere(angleCnt,:) corConfSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'acrSphere.txt'),[angles(angleCnt) acrSphere(angleCnt,:) acrConfSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'farSphere.txt'),[angles(angleCnt) farSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'frrSphere.txt'),[angles(angleCnt) frrSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'nSphere.txt'),[angles(angleCnt) nSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'tpSphere.txt'),[angles(angleCnt) tpSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'fpSphere.txt'),[angles(angleCnt) fpSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'fnSphere.txt'),[angles(angleCnt) fnSphere(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'tnSphere.txt'),[angles(angleCnt) tnSphere(angleCnt,:)],'-append');

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

	%dlmwrite(fullfile(resultDir,'wrrCardioid.txt'),[angles(angleCnt) wrrCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'corCardioid.txt'),[angles(angleCnt) corCardioid(angleCnt,:) corConfCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'acrCardioid.txt'),[angles(angleCnt) acrCardioid(angleCnt,:) acrConfCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'farCardioid.txt'),[angles(angleCnt) farCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'frrCardioid.txt'),[angles(angleCnt) frrCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'nCardioid.txt'),[angles(angleCnt) nCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'tpCardioid.txt'),[angles(angleCnt) tpCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'fpCardioid.txt'),[angles(angleCnt) fpCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'fnCardioid.txt'),[angles(angleCnt) fnCardioid(angleCnt,:)],'-append');
	%dlmwrite(fullfile(resultDir,'tnCardioid.txt'),[angles(angleCnt) tnCardioid(angleCnt,:)],'-append');
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
