clear
addpath(fileparts(fileparts(mfilename('fullpath'))));

options.doSpeechRecognition = true;
options.speechRecognition.sigDir = '/erk/tmp/feher/speechSig';
mkdir(options.speechRecognition.sigDir);
results = start(options);
