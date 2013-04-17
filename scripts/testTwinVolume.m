%test the level of the microphone outputs to determain overall level difference
%between both capsules (knowing that the room influences the experiment)
%result: globalMean is 2.66dB, which means that in average the back cardioid is
%2.66dB quieter than the front cardioid 
clear
addpath('~/sim/framework');

%%%%%%%%%%+options%%%%%%%%%%
resultDir = '/erk/tmp/feher/dbTest/';
audio = '/erk/daten1/uasr-data-feher/audio/nachrichten_10s.wav';
distances = [0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];
angles = [0:15:90];
%%%%%%%%%%-options%%%%%%%%%%

if(~exist(resultDir,'dir'))
	mkdir(resultDir);
end
angleNum = numel(angles);
distNum = numel(distances);
all = [];
for angleCnt=1:angleNum
	for distCnt=1:distNum
		distance = distances(distCnt);
		options.doConvolution = true;
		options.inputSignals = audio;
		options.irDatabaseName = 'twoChanMicHiRes';
		options.irDatabaseSampleRate = 16000;

		%front input (0-90)deg
		angle = angles(angleCnt);
		options.impulseResponses =...
			struct('angle',angle,'distance',distance,'room','studio');
		[result opt] = start(options);
		sig = result.input.signal(1,:);
		level(1) = 10*log10(sig*sig.'/numel(sig));

		%rear input (180-90)deg
		angle = 180 - angle;
		options.impulseResponses =...
			struct('angle',angle,'distance',distance,'room','studio');
		[result opt] = start(options);
		sig = result.input.signal(2,:);
		level(2) = 10*log10(sig*sig.'/numel(sig));
		%difference
		diff(1) = level(1)-level(2);%calculate difference

		if(angles(angleCnt)~=0)
			%front input (360-270)deg
			angle = 360 - angles(angleCnt);
			options.impulseResponses =...
				struct('angle',angle,'distance',distance,'room','studio');
			[result opt] = start(options);
			sig = result.input.signal(1,:);
			level(3) = 10*log10(sig*sig.'/numel(sig));

			%rear input (180-270)deg
			angle = 180 + angles(angleCnt);
			options.impulseResponses =...
				struct('angle',angle,'distance',distance,'room','studio');
			[result opt] = start(options);
			sig = result.input.signal(2,:);
			level(4) = 10*log10(sig*sig.'/numel(sig));
			%difference
			diff(2) = level(3)-level(4);%calculate difference
		end

		all = [all diff];%append difference value
		dlmwrite(fullfile(resultDir,'result.csv'),...
			[angles(angleCnt) distance level diff],'-append');
		clear diff,level;
	end
end
globalMean = mean(all);
dlmwrite(fullfile(resultDir,'result.csv'),globalMean,'-append');
