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
%options.sortCorrBlock.blockSize = 0.4;%in seconds
%options.sortCorrBlock.corrThreshold = 0.5;
%options.iterICA = 0;

for cnt=1:3
	[result opt] = start(options);

	%spectrogram1 = transp(abs(squeeze(result.ica.sigVec(1,:,:))));
	%spectrogram1 = spectrogram1(end:-1:1,:);
	%spectrogram2 = transp(abs(squeeze(result.ica.sigVec(2,:,:))));
	%spectrogram2 = spectrogram2(end:-1:1,:);

	signal = transp(result.signal(:,:));
	signal = signal/max(abs(signal(:)));
	signame = sprintf('/erk/tmp/feher/sig%d_%s.wav',cnt,opt.ica.postProc);
	wavwrite(signal,opt.fs,signame);
	%eopen('/erk/tmp/feher/spectrogram1.eps');
	%eimagesc(spectrogram1);
	%eclose();
	%eopen('/erk/tmp/feher/spectrogram2.eps');
	%eimagesc(spectrogram2);
	%eclose();
end
options.ica.postProc = 'binMaskLevel';
for cnt=1:3
	[result opt] = start(options);

	signal = transp(result.signal(:,:));
	signal = signal/max(abs(signal(:)));
	signame = sprintf('/erk/tmp/feher/sig%d_%s.wav',cnt,opt.ica.postProc);
	wavwrite(signal,opt.fs,signame);
end
