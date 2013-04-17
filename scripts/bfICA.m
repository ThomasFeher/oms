%this does not work very good, because beamforming as an linear opration does
		%not increase dimensionality of the data
clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
options.impulseResponses =...
		struct('angle',{0 30 60},'distance',1.8,'room','refRaum');
options.inputSignals = {'~/AudioDaten/speech1.wav' '~/AudioDaten/speech2.wav'...
		'~/AudioDaten/nachrichten_10s.wav'};
options.doBeamforming = true;
options.beamforming.doWeightMatSynthesis = true;
options.beamforming.muMVDR = -50;
options.beamforming.noiseAngle = 60;
[result opt] = start(options);
wavwrite(result.signal(1,:)',opt.fs,'/erk/tmp/feher/sig1.wav');
eopen('/erk/tmp/feher/bf1.eps');
eimagesc(abs(squeeze(result.beamforming.beampattern(:,:,1))));
eclose;

options.beamforming.noiseAngle = 30;
[result opt] = start(options);
wavwrite(result.signal(1,:)',opt.fs,'/erk/tmp/feher/sig2.wav');
eopen('/erk/tmp/feher/bf2.eps');
eimagesc(abs(squeeze(result.beamforming.beampattern(:,:,1))));

options.beamforming.noiseAngle = 'diffuse';
[result opt] = start(options);
wavwrite(result.signal(1,:)',opt.fs,'/erk/tmp/feher/sig3.wav');
eopen('/erk/tmp/feher/bf3.eps');
eimagesc(abs(squeeze(result.beamforming.beampattern(:,:,1))));
eclose;close;

clear options;
inDir = '/erk/tmp/feher/';
options.inputSignals =...
		{[inDir 'sig1.wav'],[inDir 'sig2.wav'],[inDir 'sig3.wav']};
options.doICA = true;
options.geometry = [1 0 1;0 0 0;0 0 0];
[result opt] = start(options);
wavwrite(result.signal(:,:)',opt.fs,'/erk/tmp/feher/sigICA.wav');
