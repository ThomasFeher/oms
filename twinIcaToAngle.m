%takes the demixing matrix of the ICA and returns the zero angles
%first angle is limited to (90,180) and second angle to (0,90)
%@input W: ICA demixing matrix
%@output angles: estimated angles of the pattern zero [angle1,angle2]
function angles = twinIcaToAngle(W,forceFrontBack)
if(size(W)~=[2,2])
	error('input must be a matrix of size 2x2');
end
if(nargin<2)
	forceFrontBack = true;
end

% prevent phase inversion
[~,index] = max(abs(W.'));% find main look direction
if(W(1,index(1)) < 0)% invert if necessary
	W(1,:) = -W(1,:);
end
if(W(2,index(2)) < 0)% invert if necessary
	W(2,:) = -W(2,:);
end

% normalize to maximum per vector
[maxVals maxIdx] = max(abs(W),[],2); % find maximum
maxVals = maxVals .* sign(W(sub2ind([2;2],[1;2],maxIdx))); % retrieve signs,
                                                       %to see phase inversion
W = bsxfun('rdivide',W,maxVals); % normalize and remove phase inversion

% estimate look direction
betaIdx = mod(maxIdx,2)+1;%index of the not maximum values
backCardIdx = find(betaIdx==1);
betaIdxS = sub2ind([2,2],1:rows(W),betaIdx.');

% set positive betas to zero
WSub = W(betaIdxS);
WSub(WSub>0) = 0;
W(betaIdxS) = WSub;

% calculate angles
angles = acos((-W(betaIdxS)-1)./(-W(betaIdxS)+1))/pi*180;

% correct angles of backwards looking cardioids
angles(backCardIdx) = 180 - angles(backCardIdx);

% force one angle to front half and one angle to back half
if(forceFrontBack) % force one zero in front half and one zero in back half
	[anglesSort sortIdx] = sort(angles);
	if(anglesSort(2)<90)
		anglesSort(2) = 90;
	end
	if(anglesSort(1)>90)
		anglesSort(1) = 90;
	end
	angles = anglesSort(sortIdx); % revert sorting
end

% limit
angles(find(angles<0)) = 0;
angles(find(angles>180)) = 180;

%!assert(twinIcaToAngle([1,0;0,1]),[180,0],eps);
%!assert(twinIcaToAngle([0,1;1,0]),[0,180],eps);
%!assert(twinIcaToAngle([0.5,-0.5;10,0]),[90,180],eps);
%!assert(twinIcaToAngle([0.6,0.5;10,0]),[90,180],eps);
%!assert(twinIcaToAngle([0,1;0,1],true),[0,90],eps);
%!assert(twinIcaToAngle([0,1;0,1],false),[0,0],eps);
