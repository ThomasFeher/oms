function W = weightMatSynth_mvdr(options)
% input:
%   options: OMS options struct
% output:
%   W: microphone weights, size: [mic,freq]

muMVDR = options.beamforming.muMVDR;
geometry = options.geometry;
freqs = options.frequency;
freqNum = options.frequNum;
speedOfSound = options.c;
sigma = 10^(muMVDR/10);

if(options.beamforming.weightMatSynthesis.doNearfield)
	% generate steering vector
	noisePos = options.beamforming.weightMatSynthesis.noisePos;
	target = options.beamforming.weightMatSynthesis.target;
	wVec = waveVec(geometry,freqs,target,speedOfSound); % [mic,freq,1]
	wVec = permute(wVec,[1,3,2]);
	cohMat = coherenceMatNearfield(geometry,freqs,noisePos,speedOfSound);
	cohMat = cohMat ./ (1+sigma); % apply MVDR
	% set main diagonal to one, because sigma is only applied to off diagonal
	cohMat(repmat(logical(eye(size(cohMat(:,:,1)))),[1,1,freqNum])) = 1; 
	for freqCnt=1:freqNum % is it possible to vectorize?
		cohMatInv(:,:,freqCnt) = inv(cohMat(:,:,freqCnt));
	end
	W = mult3dArray(cohMatInv,wVec)...
	 ./ mult3dArray(mult3dArray(conj(permute(wVec,[2,1,3])),cohMatInv),wVec);
	W = squeeze(W);
else
	noiseAngle = options.beamforming.noiseAngle;
	if(options.beamforming.weightMatSynthesis.angle==0)
		direction = ones(numel(geometry(1,:)),freqNum);
	else
		direction = beamSteering(options.beamforming.weightMatSynthesis.angle...
				,geometry(1,:),freqs,options.c);
		%direction = beamSteering3d(options.beamforming.weightMatSynthesis.angle...
				%,0,geometry,freqs,options.c);
	end
	W = zeros(numel(geometry(1,:)),freqNum); % preallocate matrix

	for freqCnt=1:freqNum
		%warning('');
		gammaInv = inv(coherenceMat(geometry(1,:),geometry(2,:),...
		%gammaInv = inv(coherenceMat(geometry(1,:),zeros(1,numel(geometry(1,:))),...
				freqs(freqCnt), noiseAngle,0,muMVDR));
		%if(~strcmp('',lastwarn))
			%disp(sprintf('Warning at frequency %d',freqs(freqCnt)));
			%warning('');
		%end
		W(:,freqCnt) = gammaInv*direction(:,freqCnt)...
				/(direction(:,freqCnt)'*gammaInv*direction(:,freqCnt));
	end
end
W(isnan(W)) = 0;

%!shared options,freqNum,micNum,target,speedOfSound
%! options.beamforming.muMVDR = inf;
%! freqNum = 10;
%! options.frequNum = freqNum;
%! options.frequency = linspace(100,1000,freqNum);
%! micNum = 3;
%! options.geometry = [-1 0 1;zeros(2,micNum)];
%! options.c = 340;
%! options.beamforming.weightMatSynthesis.target = [1;1;1];
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! options.beamforming.weightMatSynthesis.noisePos = 'diffuse';
%! options.beamforming.weightMatSynthesis.angle = 0;
%! options.beamforming.noiseAngle = 0;
%! target = [2,2,2];
%! speedOfSound = 340;

%!test # output size
%! result = weightMatSynth_mvdr(options);
%! assert(size(result),[micNum,freqNum]);
%! assert(iscomplex(result));

%!test # compare nearfield and farfield
%! targetAngle = 0/180*pi;
%! options.beamforming.weightMatSynthesis.target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! noiseAngle = 45;
%!#options.beamforming.weightMatSynthesis.noisePos = 1e5*[sin(noiseAngle/180*pi);sin(noiseAngle/180*pi);cos(noiseAngle/180*pi)];
%! resultNear = weightMatSynth_mvdr(options);
%! options.beamforming.weightMatSynthesis.doNearfield = false;
%! options.beamforming.noiseAngle = noiseAngle;
%! resultFar = weightMatSynth_mvdr(options);
%! assert(resultNear,resultFar,1e-4);

%!test # response is 1, farfield, DSB
%! options.beamforming.weightMatSynthesis.doNearfield = false;
%! noiseAngle = 45/180*pi;
%! targetAngle = 0;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.muMVDR = inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(abs(weights(:,freqCnt)'*wVec(:,freqCnt)),1,1e-9);
%! end

%!test # response is 1, farfield with nearfield approach, DSB
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! targetAngle = 0;
%! noiseAngle = 45/180*pi;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.muMVDR = inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(weights(:,freqCnt)'*wVec(:,freqCnt),1,1e-9);
%! end

%!test # response is 1, nearfield, DSB
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! targetAngle = 0;
%! noiseAngle = 45/180*pi;
%! target = 1*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%! options.beamforming.muMVDR = inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(weights(:,freqCnt)'*wVec(:,freqCnt),1,1e-15);
%! end

%!test # response is 1, farfield, MVDR, diffuse
%! options.beamforming.weightMatSynthesis.doNearfield = false;
%! noiseAngle = 45/180*pi;
%! targetAngle = 0;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%!#options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.noiseAngle = 'diffuse';
%! options.beamforming.muMVDR = -inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(abs(weights(:,freqCnt)'*wVec(:,freqCnt)),1,1e-9);
%! end

%!test # response is 1, farfield with nearfield approach, MVDR, diffuse
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! targetAngle = 0;
%! noiseAngle = 45/180*pi;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%! options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.noiseAngle = 'diffuse';
%! options.beamforming.muMVDR = -inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(weights(:,freqCnt)'*wVec(:,freqCnt),1,1e-9);
%! end

%!test # response is 1, nearfield, MVDR, diffuse
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! targetAngle = 0;
%! noiseAngle = 45/180*pi;
%! target = 1*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%! options.beamforming.muMVDR = -inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(weights(:,freqCnt)'*wVec(:,freqCnt),1,1e-15);
%! end

%!test # response is 1, farfield, MVDR, diffuse
%! options.beamforming.weightMatSynthesis.doNearfield = false;
%! noiseAngle = 45/180*pi;
%! targetAngle = 0;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%!#options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.noiseAngle = 'diffuse';
%! options.beamforming.muMVDR = -inf;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(abs(weights(:,freqCnt)'*wVec(:,freqCnt)),1,1e-9);
%! end

%!test # response is 1, farfield, MVDR, nullsteering
%! options.beamforming.weightMatSynthesis.doNearfield = false;
%! noiseAngle = 45/180*pi;
%! targetAngle = 0;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%! options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.muMVDR = -30;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(abs(weights(:,freqCnt)'*wVec(:,freqCnt)),1,1e-9);
%! end

%!test # response is 1, farfield with nearfield approach, MVDR, nullsteering
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! targetAngle = 0;
%! noiseAngle = 45/180*pi;
%! target = 1e5*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%! options.beamforming.weightMatSynthesis.noisePos = 1e5*[sin(noiseAngle);sin(noiseAngle);cos(noiseAngle)];
%! options.beamforming.noiseAngle = noiseAngle/pi*180;
%! options.beamforming.noiseAngle = 'diffuse';
%! options.beamforming.muMVDR = -30;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(weights(:,freqCnt)'*wVec(:,freqCnt),1,1e-9);
%! end

%!test # response is 1, nearfield, MVDR, nullsteering
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! targetAngle = 0;
%! noiseAngle = 45/180*pi;
%! target = 1*[sin(targetAngle);sin(targetAngle);cos(targetAngle)];
%! options.beamforming.weightMatSynthesis.target = target;
%! options.beamforming.weightMatSynthesis.noisePos = 1*[sin(noiseAngle);sin(noiseAngle);cos(noiseAngle)];
%! options.beamforming.muMVDR = -30;
%! wVec = squeeze(waveVec(options.geometry,options.frequency,target,speedOfSound));
%! weights = weightMatSynth_mvdr(options);
%! for freqCnt=1:freqNum
%!   assert(weights(:,freqCnt)'*wVec(:,freqCnt),1,1e-9);
%! end
