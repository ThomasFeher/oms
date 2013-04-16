%script to adapt the model of the speech recognizer
%result is a model file: 3_15_XXX.hmm in the standard model dir
%note: label offsets: threeMic: 0.06, twinMicStudio: 0.06 twinMicRef: 0.01
clear all;
close all;

%% Add related folders
addpath(fileparts(fileparts(mfilename('fullpath'))));

%% SETTINGS
resultDir = '/erk/tmp/feher/speechRecogAdapt2/';
tmpDir = resultDir;
sigDir = [resultDir 'audio'];
logDir = sigDir;
logFile = 'log2.txt';%log file name for remote processing, otherwise not used

%%%%%PARAMETER%%%%%
distance = 0.4;
speaker_angle = 0;
shortSet = false;%process only first <shortSetNum> files
shortSetNum = 0;
mic = 'three';%'twin', 'three', 'orig'
algo = 'sphere';%'sphere','adma','binMask'
withLabels = true;%phoneme labels are used to find phoneme positions
doRemoteUasr = true;%will execute uasr on eakss1
doConvolution = true;%if false, data in sigDir will be used directly
room = 'studio';%'studio' or 'refRaum' 
%extPlus = 'noise_label';%additional extension string,
						%will be appended at final string
%%%%%PARAMETER%%%%%

dbDir='/erk/daten2/uasr-data-common/ssmg/common/';
filelistPath = [dbDir 'flists/SAMURAI_0_adp.flst'];
signalPath = [dbDir '/sig'];
fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
fclose(fId);
fileNum = numel(fileList{1});
if(shortSet&&shortSetNum<fileNum) fileNum=shortSetNum;end
if(~exist(tmpDir,'dir')) mkdir(tmpDir); end
if(~exist(resultDir,'dir')) mkdir(resultDir); end
if(~exist(sigDir,'dir')) mkdir(sigDir); end
diary([resultDir 'log.txt']);
%generate model appendix
micText = lower(mic);
angleText = sprintf('%03d',speaker_angle);

doBinMask = false;%set default value
doAdma = false;%set default value
doSphere = false;%set default value
%set values according to algorithm:
if(strcmpi(algo,'sphere'))
	doSphere = true;
	algo = 'sphere';
elseif(strcmpi(algo,'adma'))
	doAdma = true;
	algo = 'adma';
elseif(strcmpi(algo,'binMask'))
	doBinMask = true;
	algo = 'binMask'
else
	error(['unknown algorithm: ' algo]);
end

extension = ['A_' micText '_' angleText '_' algo];%generate string
if(exist('extPlus','var'))
	extension = [extension '_' extPlus];
end

if(doConvolution)
	for fileCnt=1:fileNum
		file = fileList{1}{fileCnt};%get file from list
		fileAbs = fullfile(signalPath,file);%concatenate file and path
		options.resultDir = resultDir;
		options.tmpDir = tmpDir;
		options.doTdRestore = true;
		options.doConvolution = true;
		options.inputSignals = fileAbs;
		options.irDatabaseSampleRate = 16000;
		options.blockSize = 1024;
		options.timeShift = 512;
		if(strcmpi(mic,'twin'))
			options.irDatabaseName = 'twoChanMicHiRes';
			options.doTwinMicNullSteering = doAdma;
			options.twinMic.nullSteering.algorithm = 'fix';
			options.twinMic.nullSteering.angle = 180;
			options.doTwinMicBeamforming = doBinMask;
			options.dma.angle = 180;
			options.twinMic.beamformer.update = 0.2;
			options.twinMic.beamformer.angle = 60;
		elseif(strcmpi(mic,'three'))
			options.irDatabaseName = 'threeChanDMA';
			options.doADMA = doAdma;
			options.adma.Mask = doBinMask;
			options.adma.pattern = 'cardioid';
			options.adma.theta1 = speaker_angle;
			options.adma.freqBand = [50 6000];
			options.adma.mask_update =0.2;
			options.adma.mask_angle = 0.9;
		elseif(strcmpi(mic,'orig'))
		else
			error (['unknown microphone: ' mic]);
		end
		options.impulseResponses = struct(...
			'angle',speaker_angle...
			,'distance',distance...
			,'room',room...
			,'level',0 ...
			,'fileLocation'...
			,'/erk/daten1/uasr-data-feher/audio/Impulsantworten/3ChanDMA/'...
			,'length',-1);
		if(strcmpi(mic,'orig'))
			%copyfile(fileAbs ,fullfile(sigDir,[file '.wav']));
			disp(['copying' fileAbs '.wav to ' sigDir]);
			copyfile([fileAbs '.wav'],sigDir);
		else
			[result opt] = start(options);%processing
			%store processed signal
			if(strcmpi(mic,'twin'))
				if(doSphere)
					signal = sum(result.input.signal).';%sphere
				else
					%signal = result.input.signal(1,:).';%cardioid
					signal = result.signal(1,:).';%binMask or cardioid if not processed
				end
			elseif(strcmpi(mic,'three'))
				if(doSphere)
					signal = result.signal(3,:).';%sphere
				else
					%signal = result.signal(2,:).';%adma
					signal = result.signal(1,:).';%binMask or adma if not processed
				end
			end
			signal = signal/max(abs(signal))*0.95;
			wavName = fullfile(sigDir,file);
			wavwrite(signal,opt.fs,wavName);
		end
		clear options;
	end%filCnt
end%doConvolution

if(withLabels)
	configName = 'SAMURAI_0_adpl.cfg';
else
	configName = 'SAMURAI_0_adp.cfg';
end

if(doRemoteUasr)
	disp('copying files to remote machine...');
	system(['ssh eakss1 mkdir -p ' logDir]);%create log dir on remote machine
	system(['ssh eakss1 mkdir -p ' sigDir]);%create sig dir on remote machine
	system(['scp ' sigDir '/*.* eakss1://' sigDir],'-echo');%copy files
	disp(['Model file extension will be: ' extension]);
	disp(['running uasr on remote machine, see local logfile <'...
		logDir '/' logFile '>']);
	system(['ssh eakss1 "nohup ~/sim/framework/scripts/speechRecogAdapt.sh '...
		configName ' ' logDir ' ' logFile ' ' sigDir ' ' extension...
		' >/dev/null 2>&1 </dev/null &"']);
	%direct invocation of dlabpro on remote machine seems not to work
	%system(['ssh eakss1 "nohup dlabpro ~/uasr/scripts/dlabpro/HMM.xtp adp' ...
						   %' ~/uasr-data/ssmg/common/info/' configName ...
						   %' -Pam.model=3_15 ' ...
						   %' -Pdir.fea=' logDir ...
						   %' -Pdir.sig=' sigDir ...
						   %' -Pam.adapt.ext=' extension ...
						   %...%' -Plab.offset=0.06'
						   %' -v2'...
						   %' >' logDir '/' logFile ...
						   %' >2&1'...% </dev/null'...
						   %' &"']); %...
else
	disp(['Model file extension will be: ' extension]);
	[status out] = system(['dlabpro ~/uasr/scripts/dlabpro/HMM.xtp adp ' ...
						   '~/uasr-data/ssmg/common/info/' configName ...
						   ' -Pam.model=3_15 ' ...
						   ' -Pdir.fea=' logDir ...
						   ' -Pdir.sig=' sigDir ...
						   ' -Pam.adapt.ext=' extension ...
						   ' -v2'],'-echo'); %...
end
%disp(out);
diary off;
