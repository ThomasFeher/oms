function fitness = fitfuncDeMat(parVec)
% set variable options
options.twinMic.icaMap.iterations = fix(parVec(1));
options.twinMic.icaMap.updateAngle = parVec(2);
options.twinMic.icaMap.updateAmp = parVec(3);
options.twinMic.icaMap.updateMask = parVec(4);
options.twinMic.icaMap.lhCoeff = parVec(5);

snr = -10;
% set constant options
options.doTwinMicIcaMap = true;
options.doTdRestore = true;
options.doConvolution = true;
options.doFdStore = true;
options.inputSignals{1,2} = '~/temp/nachrichten_female.wav';
options.irDatabaseSampleRate = 16000;
options.irDatabase.dir = '/home/tom/temp/';
options.blockSize = 1024;
options.timeShift = 512;
options.irDatabaseName = 'twoChanMicHiRes';
options.impulseResponses = struct('angle',{0 90}...
								 ,'distance',{0.4 0.4}...
								 ,'room','studio'...
								 ,'level',{0 2-snr}...
								 ,'length',-1);
dbPath = '~/Daten/Tom/uasr-data/apollo';
dbSigPath = fullfile(dbPath,'sig');

% generate result dir
resultDir = sprintf('/home/tom/temp/icaMapOptim-%d-%1.5f-%1.5f-%1.5f-%1.4f'...
                    ,parVec(1),parVec(2),parVec(3),parVec(4),parVec(5));
disp(resultDir);
options.resultDir = resultDir;
options.tmpDir = '~/temp/'; % write convolved audio data here and reuse it
mkdir(resultDir);

% read file list
fId = fopen(fullfile(dbPath,'1020.flst'));
fileList = textscan(fId,'%s %s');
fclose(fId);
fileNum = 100;

% process file list
for fileCnt=1:fileNum
	file = fileList{1}{fileCnt};
	fileAbs = fullfile(dbSigPath,file);%concatenate file and path
	options.inputSignals{1,1} = fileAbs;
	[result opt] = start(options);
	% write result audio data
	signal = result.signal(1,:).';
	signal = signal/max(abs(signal))*0.95;
	wavName = fullfile(resultDir,file);
	wavwrite(signal,opt.fs,wavName);
end

% speech recognizer
options.doTwinMicIcaMap = false;
options.doFdStore = false;
options.doConvolution = false;
options.doTdRestore = false;
options.doSpeechRecognition = true;
options.inputSignals = ones(2,1);
options.speechRecognition.db = 'apollo';
options.speechRecognition.uasrPath = '~/Daten/Tom/uasr/';
options.speechRecognition.uasrDataPath = '~/Daten/Tom/uasr-data/';
options.speechRecognition.model = '3_15_A_twin_000_binMask_noise_label';
options.speechRecognition.sigDir = resultDir;
result = start(options);
wrr = result.speechRecognition.wrr;
fitness.I_nc      = 0;%no constraints
fitness.FVr_ca    = 0;%no constraint array
fitness.I_no      = 1;%number of objectives (costs)
fitness.FVr_oa(1) = 10 - wrr; % 10% is maximum

% remove speech data
confirm_recursive_rmdir (false, "local");
[~,msg] = rmdir(resultDir,'s')
