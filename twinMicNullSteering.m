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
	disp(WNew);
	%normalize to first value to get form x-beta*y
	WNorm = [WNew(1,:)/WNew(1,1);WNew(2,:)/WNew(2,1)];
	%test first vector for ill condition
	if(~(any(isnan(WNew(1,:)))||... %NaN?
			(~isreal(WNew(1,:)))||... %complex?
			(all(~WNew(1,:)))||... %zero vector?
			(~(WNorm(1,2)>=-1&&WNorm(1,2)<=0)))) %second entry between 0 and -1?
		%first is ok, so we take it as result
		disp("nsIca vector 1");
	elseif(~(any(isnan(WNew(2,:)))||...
			(~isreal(WNew(2,:)))||...
			(all(~WNew(2,:)))||...
			(~(WNorm(2,2)>=-1&&WNorm(2,2)<=0))))
		%second vector is ok, so we use this one
		WNew = [WNew(2,:);-1 1];%take second vector
		disp("nsIca vector 2");
	else %no good results -> use old W
		WNew = W;
		disp("nsIca vector bad");
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
	disp('start ica2');
	u = options.twinMic.nullSteering.update;
	iterations = options.twinMic.nullSteering.iterations;
	if(isnumeric(coeffNS))% no calculation, just apply W (for eval. signals)
		WNew = coeffNS;
	else % calculate new W
		if(isempty(coeffNS.previous))% no start value, use that from option key
			angle = options.twinMic.nullSteering.angle;
			W = angle2W(angle);
			disp('previous from option key:');
			disp(W);
			disp('options key:');
			disp(angle);
			block = W * block;% demix with previous value
		else % use the previous value as starting point
			W = coeffNS.previous;
			block = W * block;% demix with previous value
		end
		WNew = FastICA(block,iterations); % do FastICA
		disp('result from this iteration alone:');
		disp(WNew);
		%prevent complex valued results
		WNewComplex = iscomplex(WNew);
		if(any(WNewComplex))
			WNew = W;% keep old value
			disp('skipping result, because it contains complex numbers');
		end
		disp('complete result:')
		WNew = WNew * W; % include the "pre-demixing" based on previous run
		disp(WNew);
		%prevent phase inversion
		[noi,index] = max(abs(WNew.'));% find main look direction
		% invert if necessary
		if(WNew(1,index(1)) < 0)
			WNew(1,:) = -WNew(1,:);
			disp('inverting vector 1');
		end
		if(WNew(2,index(2)) < 0)
			WNew(2,:) = -WNew(2,:);
			disp('inverting vector 2');
		end
		%prevent "flipping"
		diffWNotFlipped = vecAngle(W(1,:),WNew(1,:)) + vecAngle(W(1,:),WNew(1,:));
		disp('diffWNotFlipped:');
		disp(diffWNotFlipped);
		diffWFlipped = vecAngle(W(1,:),WNew(2,:)) + vecAngle(W(2,:),WNew(1,:));
		disp('diffWFlipped:');
		disp(diffWFlipped);
		if(diffWFlipped>diffWNotFlipped)
			WNew = WNew([2 1],:);
			disp('flipping vectors');
		end
		% limit amplification
		maxVal = max(abs(WNew));
		if(maxVal>1e+6)
			WNew = WNew ./ (maxVal/1e+6);
			disp('limiting');
		end
	end

	angleNew = u*WNew + (1-u)*W;
	WNorm = [angleNew(1,:)./max(abs(angleNew(1,:)));angleNew(2,:)./max(abs(angleNew(2,:)))];
	disp('normalized result:');
	disp(WNorm);
	sigVecNew = WNorm * sigVec;

otherwise
	error(sprintf('Unknown Twin Microphone Null Steering Algorithm: %s',...
			options.twinMic.nullSteering.algorithm));
end %switch

function beta = angle2beta(angle)
angleRad = angle/180*pi;
beta = (-cos(angleRad)-1)./(cos(angleRad)-1);

function W = angle2W(angle)
beta = angle2beta(angle);
W = [1 -beta;-beta 1];
%W(1,:) = W(1,:)/norm(W(1,:));
%W(2,1) = sqrt(1/(1+(W(1,1)/W(1,2))^2));
%W(2,2) = -W(1,1)*W(2,1)/W(1,2);

function angle = beta2angle(beta)
angle = acos((beta-1)./(beta+1))/pi*180;

%!shared options, sigVec, coeffNS
%! sigVec = [rand(1,10);zeros(1,10)];
%! options.twinMic.nullSteering.algorithm = 'ica';
%! options.twinMic.nullSteering.update = 1;
%! options.twinMic.nullSteering.iterations = 10;
%! options.twinMic.nullSteering.angle = 90;
%! coeffNS.previous = [];
%!test #NS-ICA with 1 source at front
%! block = [rand(1,10);zeros(1,10)];
%! [sigNew,angle] = twinMicNullSteering(options,sigVec,block,coeffNS);
%! assert(angle,180,eps);
%!test #NS-ICA with 1 source at front and 1 at 90°
%! sig1 = rand(1,10);
%! sig2 = rand(1,10);
%! block = [sig1+0.5*sig2;0.5*sig2];
%! [sigNew,angle] = twinMicNullSteering(options,sigVec,block,coeffNS);
%! assert(angle,90,eps);
%!test #NS-ICA2 with 1 source at front, 1 source at 180°
%! options.twinMic.nullSteering.algorithm = 'ica2';
%! block = [sin(linspace(0,4*pi,1000));rand(1,1000)-0.5];
%! [sigNew,W] = twinMicNullSteering(options,sigVec,block,coeffNS);
%! WNorm = [W(1,:)./max(abs(W(1,:)));W(2,:)./max(abs(W(2,:)))];
%! assert(min(WNorm(1,:))<0.1);
%! assert(min(WNorm(2,:))<0.1);
