% takes the demixing matrix of the ICA and returns the zero angles
% first angle is limited to (90,180) and second angle to (0,90)
% input
% @W: ICA demixing matrix
% output
% @angles: estimated angles of the pattern zero [angle1,angle2]
% @beta: corresponding beta (amplification of back cardioid)

function [angles beta] = twinIcaToAngle(W,forceFrontBack)
if(size(W)~=[2,2])
	error('input must be a matrix of size 2x2');
end
if(nargin<2)
	forceFrontBack = false;
end

% normalize to maximum per vector and remove phase inversion
[maxVals maxIdx] = max(abs(W),[],2); % find maximum
maxVals = maxVals .* sign(W(sub2ind([2;2],[1;2],maxIdx))); % retrieve signs,
                                                       %to see phase inversion
W = bsxfun(@rdivide,W,maxVals); % normalize and remove phase inversion

% estimate look direction
betaIdx = mod(maxIdx,2)+1;%index of the not maximum values
backCardIdx = find(betaIdx==1);
betaIdxS = sub2ind([2,2],1:2,betaIdx.');

% set positive betas to zero
beta = W(betaIdxS);
beta(beta>0) = 0;
W(betaIdxS) = beta;

% correct betas to form (x - beta)
beta = beta .* -1;

% calculate angles
angles = acos((-W(betaIdxS)-1)./(-W(betaIdxS)+1))/pi*180;

% correct angles of backwards looking cardioids
angles(backCardIdx) = 180 - angles(backCardIdx);

% force one angle to front half and one angle to back half
if(forceFrontBack) % force one zero in front half and one zero in back half
	[anglesSort sortIdx] = sort(angles);
	if(anglesSort(2)<90)
		anglesSort(2) = 90;
		beta(sortIdx(2)) = 1;
	end
	if(anglesSort(1)>90)
		anglesSort(1) = 90;
		beta(sortIdx(1)) = 1;
	end
	angles = anglesSort(sortIdx); % revert sorting
end

% limit
angles(find(angles<0)) = 0;
angles(find(angles>180)) = 180;

%!test
%! [angles,beta] = twinIcaToAngle([1,0;0,1]);
%! assert(angles,[180,0],eps);
%! assert(beta,[0,0],eps);
%!test
%! [angles,beta] = twinIcaToAngle([0,1;1,0]);
%! assert(angles,[0,180],eps);
%! assert(beta,[0,0],eps);
%!test
%! [angles,beta] = twinIcaToAngle([0.5,-0.5;10,0]);
%! assert(angles,[90,180],eps);
%! assert(beta,[1,0],eps);
%!test
%! [angles,beta] = twinIcaToAngle([0.6,0.5;10,0],true);
%! assert(angles,[90,180],eps);
%! assert(beta,[1,0],eps);
%!test
%! [angles,beta] = twinIcaToAngle([0,1;0,1],true);
%! assert(angles,[0,90],eps);
%! assert(beta,[0,1],eps);
%!test
%! [angles,beta] = twinIcaToAngle([0,1;0,1],false);
%! assert(angles,[0,0],eps);
%! assert(beta,[0,0],eps);
