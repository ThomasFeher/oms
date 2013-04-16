clear
addpath(fileparts(fileparts(mfilename('fullpath'))));

%%%%%parameters%%%%%
options.doSpeechRecognition = true;
options.speechRecognition.doRemote = true;
options.speechRecognition.doGetRemoteResults = true;
options.speechRecognition.db = 'samurai';
options.resultDir = '/erk/tmp/feher/testSpeechRecog/';
options.speechRecognition.sigDir = options.resultDir;
%%%%%parameters%%%%%

resultDir = options.resultDir;
dbDir='/erk/daten2/uasr-data-common/ssmg/common/';
filelistPath = [dbDir 'flists/SAMURAI_0.flst'];
signalPath = [dbDir '/sig'];
fId = fopen(filelistPath);
fileList = textscan(fId,'%s %s');
if(~exist(resultDir,'dir')) mkdir(resultDir); end

%copy some files for the recognizer
for fileCnt=1:20
	file = [fileList{1}{fileCnt} '.wav'];%get file from list
	fileAbs = fullfile(signalPath,file);%concatenate file and path
	copyfile(fileAbs ,resultDir);
end

results = start(options);
