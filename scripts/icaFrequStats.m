%clear
%addpath(fileparts(fileparts(mfilename('fullpath'))));
%addpath('~/epstk/m');

%options.doConvolution = true;
%options.inputSignals =...
		%{'~/AudioDaten/speech1.wav','~/AudioDaten/nachrichten_10s.wav'};
%%options.irDatabaseChannels = [2 3];
%options.blockSize = 512;
%options.ica.beampatternResolution = 10;
%options.doFDICA = true;

%[result opt] = start(options);

histReso = 1000;
histMax = 0.1;
blockNum = size(result.sigVecTFDomain,2);
sigNum = size(result.sigVecTFDomain,1);
histo = zeros(blockNum,histReso);
disp('before ICA:')
eopen(sprintf('/erk/tmp/feher/histogram_before.eps'));
for sigCnt=1:sigNum
	sig = transp(squeeze(abs(result.sigVecTFDomain(sigCnt,:,:))));
	disp(sprintf('min: %f, max: %f, mean: %f, variance: %f, skewness %f, kurtosis %f',...
			mean(min(sig(:,:))),mean(max(sig(:,:))),mean(mean(sig(:,:))),mean(var(sig(:,:))),...
			mean(skewness(sig(:,:))),mean(kurtosis(sig(:,:)))));
	for blockCnt=1:blockNum
		histo(blockCnt,:) = histc(sig(:,blockCnt),linspace(0,histMax,histReso));
		if(blockCnt<100)
			eplot(linspace(0,histMax,histReso),histo(blockCnt,:));
		end
	end
	keyboard
	%eplot(linspace(0,histMax,histReso),mean(histo));
end
eclose;

disp('after ICA:')
eopen(sprintf('/erk/tmp/feher/histogram_after.eps'));
for sigCnt=1:sigNum
	sigICA = transp(squeeze(abs(result.ica.ica.sigVec(sigCnt,:,:))));
	disp(sprintf('min: %f, max: %f, mean: %f, variance: %f, skewness %f, kurtosis %f',...
			mean(min(sigICA(:,:))),mean(max(sigICA(:,:))),mean(mean(sigICA(:,:))),mean(var(sigICA(:,:))),...
			mean(skewness(sigICA(:,:))),mean(kurtosis(sigICA(:,:)))));
	for blockCnt=1:blockNum
		histo(blockCnt,:) = histc(sigICA(:,blockCnt),linspace(0,histMax,histReso));
	end
	eplot(linspace(0,histMax,histReso),mean(histo));
end
eclose;
