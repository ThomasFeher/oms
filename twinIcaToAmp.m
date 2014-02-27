% takes the demixing matrix of the ICA and returns the signal amplifications by
% taking into account the estimated source directions (which is the zero angle
% of the opposite channel)
% input:
% @W: ICA dmeixing matrix
% output:
% @ampSource: estimated amplification for each signal s on each channel c
%             [s1-c1,s2-c1;s1-c2,s2-c2]
function [ampSource ampFront] = twinIcaToAmp(W)
if(size(W)~=[2,2])
	error('input must be a matrix of size 2x2');
end

% calculate angle of zeros
[zeroAngle beta] = twinIcaToAngle(W,false);

% find backwards looking patterns
zeroAngle(zeroAngle>90) = 180-zeroAngle(zeroAngle>90);

% calculate pattern in direction of opposite zero angle
ampPattern = twinPattern(beta,zeroAngle([2,1]));

% calculate amplification in look direction of the both channels (either 0° or
% 180°)
[ampFront maxIdx] = max(abs(W),[],2);
ampFront = ampFront.';

% calculate resulting amplification
ampSource = ampFront .* ampPattern;

%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 0;0 1]);
%! assert(ampSource,[1 1],eps);
%! assert(ampFront,[1 1],eps);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 0;0 1]*10);
%! assert(ampSource,[1 1]*10,eps*10);
%! assert(ampFront,[1 1]*10,eps*10);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 0;1 0]);
%! assert(ampSource,[1 1],eps);
%! assert(ampFront,[1 1],eps);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 0;1 0]*10);
%! assert(ampSource,[1 1]*10,eps*10);
%! assert(ampFront,[1 1]*10,eps*10);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 -1;0.5 -0.5]);
%! assert(ampSource,[0 0],eps);
%! assert(ampFront,[1 0.5],eps);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 -1;0.5 -0.5]*10);
%! assert(ampSource,[0 0]*10,eps*10);
%! assert(ampFront,[1 0.5]*10,eps*10);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 0;1 -1]);
%! assert(ampSource,[0.5 1],eps);
%! assert(ampFront,[1 1],eps);
%!test
%! [ampSource,ampFront] = twinIcaToAmp([1 0;1 -1]*10);
%! assert(ampSource,[0.5 1]*10,eps*10);
%! assert(ampFront,[1 1]*10,eps*10);
