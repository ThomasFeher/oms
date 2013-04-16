clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
%options.inputSignals =...
		%{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		%'~/AudioDaten/nachrichten_10s.wav'};
options.blockSize = 1024;
options.timeShift = 512;
options.doDistanceFiltering = true;
options.distanceFilter.withGate = true;
options.doTwinMicBeamforming = true;
resultDir = '/erk/tmp/feher/';
mkdir(resultDir);

updateList = [1];
thresholdList = [1.1];
dist1 = 0.05;
dist2 = 1;
%inSigList = {{'~/AudioDaten/DLF_Gespraech_48kHz_10s.wav',...
			%'~/AudioDaten/nachrichten_10s_48kHz.wav'},...
			%{'~/AudioDaten/nachrichten_10s_48kHz.wav'},
			%{'~/AudioDaten/DLF_Gespraech_48kHz_10s.wav'};
%irList{1} = struct('angle',0,'distance',{dist1 dist2},'room','refRaum',...
			%'level',{1 30});
%irList{2} = struct('angle',0,'distance',{dist1},'room','refRaum');
%irList{3} = struct('angle',0,'distance',{dist2},'room','refRaum');

for updateCnt=updateList
	for thCnt=thresholdList
			%options.inputSignals = {'~/AudioDaten/DLF_Gespraech_48kHz_10s.wav',...
					%'~/AudioDaten/nachrichten_10s_48kHz.wav'}
			options.impulseResponses = struct('angle',0,...
					'distance',{dist1 dist2},'room','studio',...
					'level',{0 30});
			options.distanceFilter.threshold = thCnt;
			options.distanceFilter.update = updateCnt;
			[result opt] = start(options);
			snrImp = evalTwinMic(opt,result)
			expString = sprintf(['refRaum_threshold:%1.1f_update:%0.2f'...
					'_dist1:%01.2f_dist2:%01.2f_-_%02.1f']...
					,thCnt,updateCnt,dist1,dist2,snrImp);

			%%%%%output signal%%%%%
			signal = transp(result.signal(:,:));
			signal = signal(:,1)/max(abs(signal(:)));
			wavName = sprintf('%s/sig_%s.wav',resultDir,expString);
			wavwrite(signal,opt.fs,wavName);

			%%%%%evaluation signal%%%%%
			%1
			signalBefore = transp(result.input.signalEval{1}(1,:));
			signalAfter = transp(result.signalEval{1}(1,:));
			%signal = [signalBefore(:,1) signalAfter(:,1)];
			%signal = signal/max(abs(signal(:)));
			wavName = sprintf('%s/sigEval1Before_%s.wav',resultDir,expString);
			wavwrite(signalBefore,opt.fs,wavName);
			wavName = sprintf('%s/sigEval1After_%s.wav',resultDir,expString);
			wavwrite(signalAfter,opt.fs,wavName);

			%2
			signalBefore = transp(result.input.signalEval{2}(1,:));
			signalAfter = transp(result.signalEval{2}(1,:));
			%signal = [signalBefore(:,1) signalAfter(:,1)];
			%signal = signal/max(abs(signal(:)));
			wavName = sprintf('%s/sigEval2Before_%s.wav',resultDir,expString);
			wavwrite(signalBefore,opt.fs,wavName);
			wavName = sprintf('%s/sigEval2After_%s.wav',resultDir,expString);
			wavwrite(signalAfter,opt.fs,wavName);
	end
end
signal = transp(result.input.signal(:,:));
signal = signal/max(abs(signal(:)));
wavwrite(signal,opt.fs,[resultDir 'sigInput.wav']);
