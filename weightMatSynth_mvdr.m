function W = weightMatSynth_mvdr(options)
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
	steerVec = beamSteeringNearfield(target,geometry,freqs,speedOfSound).';%[mic,freq]
	steerVec = permute(steerVec,[1,3,2]);
	cohMat = coherenceMatNearfield(geometry,freqs,noisePos,speedOfSound);
	cohMat = cohMat ./ (1+sigma); % apply MVDR
	% set main diagonal to one, because sigma is only applied to off diagonal
	cohMat(repmat(logical(eye(size(cohMat(:,:,1)))),[1,1,freqNum])) = 1; 
	for freqCnt=1:freqNum % is it possible to vectorize?
		cohMatInv(:,:,freqCnt) = inv(cohMat(:,:,freqCnt));
	end
	W = mult3dArray(cohMatInv,steerVec)...
	 ./ mult3dArray(mult3dArray(conj(permute(steerVec,[2,1,3])),cohMatInv)...
	               ,steerVec);
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
		warning('');
		gammaInv = inv(coherenceMat(geometry(1,:),geometry(2,:),...
		%gammaInv = inv(coherenceMat(geometry(1,:),zeros(1,numel(geometry(1,:))),...
				freqs(freqCnt), noiseAngle,0,muMVDR));
		if(~strcmp('',lastwarn))
			disp(sprintf('Warning at frequency %d',freqs(freqCnt)));
			warning('');
		end
		W(:,freqCnt) = gammaInv*direction(:,freqCnt)...
				/(direction(:,freqCnt)'*gammaInv*direction(:,freqCnt));
	end
	W(isnan(W)) = 0;
end

%!test # output size
%! options.beamforming.muMVDR = inf;
%! freqNum = 10;
%! options.frequNum = freqNum;
%! options.frequency = linspace(100,1000,freqNum);
%! micNum = 3;
%! options.geometry = [-1 0 -1;zeros(2,micNum)];
%! options.c = 340;
%! options.beamforming.weightMatSynthesis.target = [1;1;1];
%! options.beamforming.weightMatSynthesis.doNearfield = true;
%! options.beamforming.weightMatSynthesis.noisePos = [0;1;0];
%! result = weightMatSynth_mvdr(options);
%! assert(size(result),[micNum,freqNum]);
%! assert(iscomplex(result));

%!test # constant weights for DSB BF (magnitude should be constant)
%! fail();
