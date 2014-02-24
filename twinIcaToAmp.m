% takes the demixing matrix of the ICA and returns the signal amplifications by
% taking into account the estimated source directions (which is the zero angle
% of the opposite channel)
%@input W: ICA dmeixing matrix
%@output amp: estimated amplification for each signal s on each channel c
%             [s1-c1,s2-c1;s1-c2,s2-c2]
function amp = twinIcaToAmp(W)
if(size(W)~=[2,2])
	error('input must be a matrix of size 2x2');
end

% calculate angle of zeros
[zeroAngle beta] = twinIcaToAngle(W);

% calculate pattern in direction of opposite zero angle
ampPattern = twinPattern(beta,zeroAngle([2,1])); % TODO implement

% calculate amplification in look direction of the cardioids (0° and 180°)
[ampMax maxIdx] = max(abs(W),[],2); % find maximum

% calculate resulting amplification
amp = ampMax .* ampPattern;

%!assert(twinIcaToAmp([1 0;0 1],[1 1],eps));
%!assert(twinIcaToAmp([1 0;1 0],[1 1],eps));
%!assert(twinIcaToAmp([1 -1;0.5 -0.5],[0 0],eps));
%!assert(twinIcaToAmp([1 0;1 -1],[0.5 1],eps));
