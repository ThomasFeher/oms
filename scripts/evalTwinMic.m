%evaluate results of twin mic processing
%input options and result structs that where returned by start function
%output:
	%snrImp: improvement of SNR between cardioid and binary masking 
	%TODO snrImp only for compatibility with old scripts, should be removed in
		%future versions or set to last position
	%snrCardioid: SNR at front cardioid capsule
	%snrAfter: SNR after processing
	%snrSphere: SNR af sphere charateristic

function [snrImp snrCardioid snrAfter snrSphere] = evalTwinMic(options,results)
%snr at front cardioid capsule
signal = results.input.signalEval{1}(1,:);%get wanted signal at input
%get input noise signals
noise = zeros(size(signal));
for srcCnt=2:options.srcNum
	noise = noise + results.input.signalEval{srcCnt}(1,:);
end
snrCardioid = snr(signal,noise);%calculate input snr

%snr at processed signal
signal = results.signalEval{1}(1,:);
noise = zeros(size(signal));
for srcCnt=2:options.srcNum
	noise = noise + results.signalEval{srcCnt}(1,:);
end
snrAfter = snr(signal,noise);
if(options.doFDICA)
	for sigCnt=2:options.sigNum
		signal = results.signalEval{1}(sigCnt,:);
		noise = zeros(size(signal));
		for srcCnt=2:options.srcNum
			noise = noise + results.signalEval{srcCnt}(sigCnt,:);
		end
		snrAfterTest = snr(signal,noise)
		if(snrAfterTest>snrAfter)
			snrAfter = snrAfterTest;
		end
	end
end

snrImp = snrAfter - snrCardioid;

%snr at sphere
signal = sum(results.input.signalEval{1});%get wanted signal at input 
%get input noise signals
noise = zeros(size(signal));
for srcCnt=2:options.srcNum
	noise = noise + sum(results.input.signalEval{srcCnt});
end
snrSphere = snr(signal,noise);%calculate input snr
