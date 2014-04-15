function di =  directivityIndex(pattern,frontIdx,phi,theta)
% pattern: beampattern(phi,theta,freq) or beampattern(phi,freq)
% frontIdx: angle index of front direction, is 1 if not given
% phi: vector containing start, increment and end value of phi in degree
% 	TODO take vector of phi values for each element of pattern
% theta: vector containing start, increment and end value of theta in degree
% 	TODO take vector of theta values for each element of pattern
% TODO give frequency index in order to allow calculation for data with no
     %frequency dimension
% FIXME values at poles of coordinate system (θ=0° and θ=180°) are ignored for
%   the exact calculation method, what happens accuracy wise if the main lobe
%   points in that direction?
% TODO rename to directivityIndexFromPattern

patternDims = ndims(pattern);
doExact = true;

if(patternDims<2||patternDims>3)
	error('Pattern must have two or three dimensions, but has %d.'...
	      ,patternDims);
end
if(nargin<4)
	doExact = false;
else
	if(numel(phi)~=3)
		error('Third argument must be a vector of three values');
	end
	if(numel(theta)~=3)
		error('Fourth argument must be a vector of three values');
	end
	% convert to radian
	phi = phi/180*pi;
	theta = theta/180*pi;
end
if(nargin<2)
	frontIdx = ones(patternDims-1,1);
end
if(patternDims-1~=numel(frontIdx))
	error('Front index must be same size as angles in beampattern.');
end

% get squared sensitivities
pattern = (abs(pattern)).^2;
% calculate mean
if(doExact)
	% a surface element is r²*sin(θ)*δϑ*δφ
	% on a surface with radius 1 the complete surface area is 4πr²
	phiNum = numel(phi(1):phi(2):phi(3));
	% generate matrix with differential areas sin(θ)δφδϑ
	%% generate vector of δφ
	phiVec = phi(2)*ones(phiNum,1);
	%% generate vector of θ
	%% FIXME the sine is not fully correct, better is taking the average
	%%   between θ-δθ/2 and θ+δθ/2
	%% take absolute just in case coordinates out of the range [0°:180°] are used
	thetaVec = abs(sin([theta(1):theta(2):theta(3)])) .* theta(2);
	%% combine to matrix, all elements should add up the spere surface area 4π
	areaMat = phiVec * thetaVec;
	% calculate weighted mean
	patternWeighted = pattern .* areaMat;
	meanPattern = sum(sum(patternWeighted,1),2)./(sum(areaMat(:)));
else
	meanPattern = mean(mean(pattern,1),2);
end

% calculate directivity index
if(patternDims==2)
	%di = pattern(frontIdx,:)./mean(pattern,1);
	di = pattern(frontIdx,:)./meanPattern;
elseif(patternDims==3)
	%di = pattern(frontIdx(1),frontIdx(2),:) ./ mean(mean(pattern,1),2);
	di = pattern(frontIdx(1),frontIdx(2),:) ./ meanPattern;
end
%make output a column vector
di = squeeze(di);
if(isrow(di))
	di = di.';
end

%!test # one angle dimension and frequency dimension
%! assert(directivityIndex([1 1;0.5 0.5],1),[8/5;8/5],eps);

%!test # wrong front index
%! pattern(:,:,1) = [1 1;0.5 0.5];
%! pattern(:,:,2) = pattern(:,:,1)/2;
%! fail('directivityIndex(pattern,1)');

%!test # two angle dimensions and frequency dimension
%! values = [1 1/3;1/2 1/6;1/4 1/5];
%! pattern(:,:,1) = values;
%! pattern(:,:,2) = pattern(:,:,1)/2;
%! result = 1/mean(abs(values(:)).^2);
%! assert(directivityIndex(pattern,[1 1]),[result;result],eps);

%TODO test exact calculation
