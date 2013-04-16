clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

%options.doConvolution = true;
%options.inputSignals =...
		%{'~/AudioDaten/speech1.wav','~/AudioDaten/nachrichten_10s.wav'};
options.inputSignals = '~/AudioDaten/Frontend_2009_03_03_10_36_01_16khz.wav';
%options.irDatabaseChannels = [2 3];
options.blockSize = 512;
options.ica.beampatternResolution = 10;
options.doFDICA = true;
options.ica.postProc = 'binMaskLevel';
%options.sortCorrBlock.blockSize = 0.4;%in seconds
%options.sortCorrBlock.corrThreshold = 0.5;
%options.iterICA = 0;
[result opt] = start(options);

%spectrogram = abs(squeeze(result.sigVecTFDomain(1,:,:)))';
spectrogram1 = transp(abs(squeeze(result.ica.sigVec(1,:,:))));
spectrogram1 = spectrogram1(end:-1:1,:);
spectrogram2 = transp(abs(squeeze(result.ica.sigVec(2,:,:))));
spectrogram2 = spectrogram2(end:-1:1,:);

signal = transp(result.signal(:,:));
signal = signal/max(abs(signal(:)));
wavwrite(signal,opt.fs,'/erk/tmp/feher/sig.wav');
eopen('/erk/tmp/feher/spectrogram1.eps');
eimagesc(spectrogram1);
eclose();
eopen('/erk/tmp/feher/spectrogram2.eps');
eimagesc(spectrogram2);
eclose();
