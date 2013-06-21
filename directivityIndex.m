%@pattern: beampattern(phi,theta,freq) or beampattern(phi,freq)
%@frontIdx: angle index of front direction, is 1 if not given
%TODO give frequency index in order to allow calculation for data with no
     %frequency dimension
function di =  directivityIndex(pattern,frontIdx)
patternDims = numel(size(pattern));
if(patternDims<2||patternDims>3)
	error('pattern must have two or three dimensions, but has %d'...
	      ,patternDims);
end
if(nargin<2)
	frontIdx = ones(patternDims-1,1);
end
if(patternDims-1~=numel(frontIdx))
	disp('numel(frontIdx):');
	disp(numel(frontIdx));
	disp('pattern dimensions - 1:');
	disp(patternDims-1);
	error('front index must be same size as angles in beampattern');
end

%get squared sensitivities
pattern = (abs(pattern)).^2;
if(patternDims==2)
	di = pattern(frontIdx,:)./mean(pattern,1);
elseif(patternDims==3)
	di = pattern(frontIdx(1),frontIdx(2),:) ./ mean(mean(pattern,1),2);
end
%make output a column vector
di = squeeze(di);
if(isrow(di))
	di = di.';
end
%keyboard

%one angle dimension and frequency dimension
%!test
%! assert(directivityIndex([1 1;0.5 0.5],1),[8/5;8/5],eps);

%wrong front index
%!test
%! pattern(:,:,1) = [1 1;0.5 0.5];
%! pattern(:,:,2) = pattern(:,:,1)/2;
%! fail('directivityIndex(pattern,1)','front index must be same size as angles in beampattern');

%two angle dimensions and frequency dimension
%!test
%! values = [1 1/3;1/2 1/6;1/4 1/5];
%! pattern(:,:,1) = values;
%! pattern(:,:,2) = pattern(:,:,1)/2;
%! result = 1/mean(abs(values(:)).^2);
%! assert(directivityIndex(pattern,[1 1]),[result;result],eps);
