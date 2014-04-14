function retval = coherenceMatNearfield(geometry, freqs, noisePos,speedOfSound)
% calculate exact coherence matrix of determined noise fields
% input:
%   geometry: microphone positions [x1 x2 …;y1 y2 …;z1 z2 …] in m
%   freqs: vector of frequencies in Hz
%   noisePos: position of the noise source (acoustic monopol) or character
%             array containing 'diffuse' for diffuse noise field [x;y;z]
%   speedOfSound: speed of sound in m/s
% output:
%   cMat: coherence matrix, size: [mic,mic,freq]

if(strcmpi(noisePos,'diffuse'))
	if(isrow(freqs))
		freqs = permute(freqs,[1,3,2]);
	else
		freqs = permute(freqs,[2,3,1]);
	end
	distancesX = geometry(1,:).'-geometry(1,:);
	distancesY = geometry(2,:).'-geometry(2,:);
	distancesZ = geometry(3,:).'-geometry(3,:);
	distances = sqrt(distancesX.^2 + distancesY.^2 + distancesZ.^2);
	retval = sinc(2*freqs.*distances/speedOfSound); % pi is multiplied by sinc
else
	% wave vector
	wVec = squeeze(waveVec(geometry,freqs,noisePos,speedOfSound)); % size: [mic,freq]
	wVec = permute(wVec,[1,3,2]); % [mic,[],freq]

	nominator = mult3dArray(conj(wVec),permute(wVec,[2,1,3])); % size: [mic,mic,freq]
	denom = abs(wVec) .* abs(permute(wVec,[2,1,3])); % size: [mic,mic,freq]

	retval = nominator ./ denom;
end

%!test # compare with farfield function
%! geometry = [-1 0 1;zeros(2,3)];
%! freqNum = 10;
%! freqs = linspace(1,1000,freqNum);
%! noiseAnglePhi = 45;
%! noiseAnglePhiRad = noiseAnglePhi/180*pi;
%! noiseAngleTheta = 45;
%! noiseAngleThetaRad = noiseAngleTheta/180*pi;
%! noiseDist = 1e5;
%! noisePos = noiseDist.*[sin(noiseAngleThetaRad)*cos(noiseAnglePhiRad);sin(noiseAngleThetaRad)*sin(noiseAnglePhiRad);cos(noiseAngleThetaRad)];
%! cMatNear = coherenceMatNearfield(geometry,freqs,noisePos,340);
%! for freqCnt=1:freqNum
%!   cMatFar(:,:,freqCnt) = coherenceMat(geometry(1,:),geometry(2,:),freqs(freqCnt),noiseAngleTheta,noiseAnglePhi,-inf);
%! end
%! assert(cMatNear,cMatFar,1e-4);

%!test # diffuse noise field
%! geometry = [-1 0 1;zeros(2,3)];
%! freqNum = 10;
%! freqs = linspace(1,1000,freqNum);
%! noisePos = 'diffuse';
%! cMatNear = coherenceMatNearfield(geometry,freqs,noisePos,340);
%! for freqCnt=1:freqNum
%!   cMatFar(:,:,freqCnt) = coherenceMat(geometry(1,:),geometry(2,:),freqs(freqCnt),noisePos);
%! end
%! assert(cMatNear,cMatFar,eps);
