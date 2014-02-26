% Takes one or two angles and calculates the corresponding mixing matrix. This
% matrix can be used to mix two back-to-back cardioids and get two resulting
% patterns with their zeros at the given angles.
% If only one angle is given, a second angle is generated. This angle is equal
% to the first one, but for the opposite looking direction.
% In case that both angles are 90°, the second channel is turned into a back
% cardioid (angle = 180°).
% input:
% @angle: angles in degree
% output:
% @W: mixing matrix [2x2]
function W = twinAngleToMixMat(angle)
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

%!test
%! angle = 0;
%! W = twinAngleToMixMat(angle);
%! result = [0,1;1,0];
%! assert(W,result,eps);

%!test
%! angle = 90;
%! W = twinAngleToMixMat(angle);
%! result = [1,-1;0,1];
%! assert(W,result,eps);

%!test
%! angle = [90,180];
%! W = twinAngleToMixMat(angle);
%! result = [1,-1;1,0];
%! assert(W,result,eps);

%!test
%! angle = [180,90];
%! W = twinAngleToMixMat(angle);
%! result = [1,0;1,-1];
%! assert(W,result,eps);

%!test
%! angle = [0,180];
%! W = twinAngleToMixMat(angle);
%! result = [0,1;1,0];
%! assert(W,result,eps);

%!test
%! angle = [180,0];
%! W = twinAngleToMixMat(angle);
%! result = [1,0;0,1];
%! assert(W,result,eps);

% column vector should also produce row vector as output
%!test
%! angle = [180;0];
%! W = twinAngleToMixMat(angle);
%! result = [1,0;0,1];
%! assert(W,result,eps);

