%Algorithm 'fix' und 'NLMS' describend in: Teutsch and Elko: "First- and
	%Second-Order adaptive Differential Microphone Arrays"

%TODO allow slidely less than 90 degree for zero in beampattern
function [sigVecNew angleNew] = twinMicNullSteering(options,sigVec,block,coeffNS)
switch options.twinMic.nullSteering.algorithm
case {'fix','FIX','Fix'}
	%betaNew = angle2beta(options.twinMic.nullSteering.angle);
	%sigVecNew = [sigVec(1,:)-betaNew*sigVec(2,:);sigVec(1,:)];
	%angleNew = options.twinMic.nullSteering.angle;
	weight = admaNullAngleToCardioidCoeffs(options.twinMic.nullSteering.angle);
	sigVecNew(1,:) = weight * sigVec(1,:) - (1-weight) * sigVec(2,:);
	sigVecNew(2,:) = sum(sigVec);%sphere signal to second channel
	angleNew = options.twinMic.nullSteering.angle;%angle stays always the same

case {'NLMS','nlms'}
	mu = options.twinMic.nullSteering.mu;%*options.blockSize;
	alpha = options.twinMic.nullSteering.alpha;%/options.blockSize;
	if(isnumeric(coeffNS))%no calculation, just apply beta (for eval. signals)
		betaNew = angle2beta(coeffNS);
	else %calculate new beta
		if(nargin<4) %use angle set in options as previous value
			beta = angle2beta(options.twinMic.nullSteering.angle);
		% use value from previous iteration to calculate a new value
		elseif(isfield(coeffNS,'previous')) 
			if(isempty(coeffNS.previous))
				beta = angle2beta(options.twinMic.nullSteering.angle);
			else
				beta = angle2beta(coeffNS.previous);
			end
		end
		yBlock = block(1,:) - beta*block(2,:);
		betaNew = beta + mu/(alpha+mean(block(2,:).^2)) *...
				mean(block(2,:).*yBlock);
	end
	if(betaNew>1||isnan(betaNew))%algorithm works only from 90 to 180 degree
		betaNew = 1;
	end
	sigVecNew = [sigVec(1,:)-betaNew*sigVec(2,:);sigVec(1,:)];
	angleNew = beta2angle(betaNew);

case {'ICA','ica'}
	u = options.twinMic.nullSteering.update;
	iterations = options.twinMic.nullSteering.iterations;
	if(isnumeric(coeffNS))%no calculation, just apply beta (for eval. signals)
		angle = coeffNS;
		W = angle2W(angle);
		WNew = W;
	else %calculate new beta
		if(nargin<4) %use angle set in options as previous value TODO will never happen, because if statement before will through an error in this case
			angle = options.twinMic.nullSteering.angle;
			W = angle2W(angle);
		% use value from previous iteration to calculate a new value
		elseif(isfield(coeffNS,'previous')) 
			if(isempty(coeffNS.previous))
				angle = options.twinMic.nullSteering.angle;
				W = angle2W(angle);
			else
				angle = coeffNS.previous;
				W = angle2W(angle);
			end
		end
		WNew = FastICA(block,iterations);
	end
	%normalize to first value to get form x-beta*y
	WNorm = [WNew(1,:)/WNew(1,1);WNew(2,:)/WNew(2,1)];
	%test first vector for ill condition
	if(~(any(isnan(WNew(1,:)))||... %NaN?
			(~isreal(WNew(1,:)))||... %complex?
			(all(~WNew(1,:)))||... %zero vector?
			(~(WNorm(1,2)>=-1&&WNorm(1,2)<=0)))) %second entry between 0 and -1?
		%first is ok, so we take it as result
	elseif(~(any(isnan(WNew(2,:)))||...
			(~isreal(WNew(2,:)))||...
			(all(~WNew(2,:)))||...
			(~(WNorm(2,2)>=-1&&WNorm(2,2)<=0))))
		%second vector is ok, so we use this one
		WNew = [WNew(2,:);-1 1];%take second vector
	else %no good results -> use old W
		WNew = W;
	end

	angleNew = beta2angle(-WNew(1,2)/WNew(1,1));%calculate new angle
	%keep angle in range
	if(angleNew>180)
		angleNew = 180;
	elseif(angleNew<90)
		angleNew = 90;
	end
	angleNew = u*angleNew + (1-u)*angle;%update new angle
	WNew = angle2W(angleNew);
	sigVecNew = [WNew(1,:) * sigVec;sigVec(1,:)];%calculate resulting signal
	if(~isreal(angleNew))
		keyboard
	end

case {'ICA2','ica2'}
	u = options.twinMic.nullSteering.update;
	iterations = options.twinMic.nullSteering.iterations;
	doForceFrontBack = options.twinMic.nullSteering.doForceFrontBack;
	if(isnumeric(coeffNS))% no calculation, just apply W (for eval. signals)
		WNew = angle2W(coeffNS);
	else % calculate new W
		if(isempty(coeffNS.previous))% no start value, use that from option key
			angle = options.twinMic.nullSteering.angle;
			W = angle2W(angle);
			angle = twinIcaToAngle(W); % calculate second angle
			angle = sort(angle,'descend');
			block = W * block;% demix with previous value
		else % use the previous value as starting point
			angle = coeffNS.previous;
			W = angle2W(angle);
			block = W * block;% demix with previous value
		end
		WNew = FastICA(block,iterations); % do FastICA
		%prevent complex valued results
		WNewComplex = iscomplex(WNew);
		if(any(WNewComplex))
			WNew = W;% keep old value
			angleNew = angle;
		else
			WNew = WNew * W; % include the "pre-demixing" based on previous run
			angleNew = twinIcaToAngle(WNew,doForceFrontBack);
			angleNew = sort(angleNew,'descend');
			angleNew = u*angleNew + (1-u)*angle;
		end
	end

	WNorm = angle2W(angleNew);
	sigVecNew = WNorm * sigVec;

otherwise
	error(sprintf('Unknown Twin Microphone Null Steering Algorithm: %s',...
			options.twinMic.nullSteering.algorithm));
end %switch

function beta = angle2beta(angle)
angleRad = angle/180*pi;
beta = (-cos(angleRad)-1)./(cos(angleRad)-1);

function W = angle2W(angle)
if(numel(angle)<2) % create opposite pattern
	if(angle(1)>=90)
		angle(2) = 0;
	else
		angle(2) = 180;
	end
end
for cnt=1:numel(angle)
	if(angle(cnt)<90)
		angle(cnt) = 180-angle(cnt);
		beta(cnt) = angle2beta(angle(cnt));
		W(cnt,:) = [-beta(cnt),1];
	else
		beta(cnt) = angle2beta(angle(cnt));
		W(cnt,:) = [1,-beta(cnt)];
	end
end
if(angle(1)==90&&angle(2)==90)
	W(2,:) = [0,1];
end

function angle = beta2angle(beta)
angle = acos((beta-1)./(beta+1))/pi*180;

%!shared options, sigVec, coeffNS
%! sigVec = [rand(1,10);zeros(1,10)];
%! options.twinMic.nullSteering.algorithm = 'ica';
%! options.twinMic.nullSteering.update = 1;
%! options.twinMic.nullSteering.iterations = 5;
%! options.twinMic.nullSteering.angle = 90;
%! options.twinMic.nullSteering.doForceFrontBack = false;
%! coeffNS.previous = [];
%!test #NS-ICA with 1 source at front
%! block = [rand(1,100);zeros(1,100)];
%! [sigNew,angle] = twinMicNullSteering(options,sigVec,block,coeffNS);
%! assert(angle,180,eps);
%!test #NS-ICA with 1 source at front and 1 at 90°
%! sig1 = rand(1,100);
%! sig2 = rand(1,100);
%! block = [sig1+0.5*sig2;0.5*sig2];
%! [sigNew,angle] = twinMicNullSteering(options,sigVec,block,coeffNS);
%! assert(angle,90,eps);
%!test #NS-ICA2 with 1 source at front, 1 source at 180°
%! options.twinMic.nullSteering.algorithm = 'ica2';
%! block = [sin(linspace(0,4*pi,1000));cos(linspace(0,10*pi,1000))-0.5];
%! [sigNew,angles] = twinMicNullSteering(options,sigVec,block,coeffNS);
%! assert(angles(1),180,10);
%! assert(angles(2),0,10);
