%takes the demixing matrix of the ICA and returns the zero angles
%first angle is limited to (90,180) and second angle to (0,90)
%@input W: ICA demixing matrix
%@output angles: estimated angles of the pattern zero [angle1,angle2]
function angles = twinIcaToAngle(W)
if(size(W)~=[2,2])
	error('input must be a matrix of size 2x2');
end

angles = [180,0]; % initialize with back to back cardioids

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
betaIdx = sub2ind([2,2],1:rows(W),betaIdx.');

% calculate angles
angles = acos((W(betaIdx)-1)./(W(betaIdx)+1))/pi*180;

% correct angles of backwards looking cardioids
angles(backCardIdx) = 180 - angles(backCardIdx);

% sort
if(angles(1)<90&&angles(2)<90)
	[~,maxIdx] = max(angles);
	angles(maxIdx) = 90;
elseif(angles(1)>90&&angles(2)>90)
	[~,minIdx] = min(angles);
	angles(minIdx) = 90;
end
if(angles(1)<angles(2))
	angles = angles([2;1]);
end

% limit
angles(find(angles<0)) = 0;
angles(find(angles>180)) = 180;

%!assert(twinIcaToAngle([1,0;0,1]),[180,0],eps);
%!assert(twinIcaToAngle([0,1;1,0]),[180,0],eps);
%!assert(twinIcaToAngle([0.5,0.5;10,0]),[180,90],eps);
