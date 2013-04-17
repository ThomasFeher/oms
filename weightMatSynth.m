function [results] = weightMatSynth(options)
noiseAngle = options.beamforming.noiseAngle;
muMVDR = options.beamforming.muMVDR;
geometry = options.geometry;
frequency = options.frequency;
frequNum = options.frequNum;
%change this if you want to change the direction of the main lobe
if(options.beamforming.weightMatSynthesis.angle==0)
	direction = ones(numel(geometry(1,:)),frequNum);
else
	direction = beamSteering(options.beamforming.weightMatSynthesis.angle...
			,geometry(1,:),frequency,options.c);
	%direction = beamSteering3d(options.beamforming.weightMatSynthesis.angle...
			%,0,geometry,frequency,options.c);
end
W = zeros(numel(geometry(1,:)),frequNum);

for frequCnt=1:frequNum
	warning('');
	%gammaInv = inv(coherenceMat(geometry(1,:),geometry(2,:),...
	gammaInv = inv(coherenceMat(geometry(1,:),zeros(1,numel(geometry(1,:))),...
			frequency(frequCnt), noiseAngle,0,muMVDR));
	if(~strcmp('',lastwarn))
		disp(sprintf('Warning at frequency %d',frequency(frequCnt)));
		warning('');
	end
	W(:,frequCnt) = gammaInv*direction(:,frequCnt)...
			/(direction(:,frequCnt)'*gammaInv*direction(:,frequCnt));
end
W(isnan(W)) = 0;
results.W = W;
