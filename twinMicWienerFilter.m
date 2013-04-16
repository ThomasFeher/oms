%wiener filter for twin microfone. Front cardioid is signal+noise, back cardioid
%is only noise.
function [sigVecNew newCoeff] = twinMicWienerFilter(options,sigVec,coeff)
if(nargin<3||isfield(coeff,'previous')) %calculate new coefficients
	newCoeff = 1-(abs(sigVec(2,:)).^2)./(abs(sigVec(1,:)).^2);
	newCoeff(newCoeff<0) = 0;
	newCoeff(newCoeff>1) = 1;
	newCoeff(isnan(newCoeff)) = 0;
	if(isfield(coeff,'previous'))
		if(~isempty(coeff.previous))
			u = options.twinMic.wienerFilter.update;
			newCoeff = (1-u)*coeff.previous + u*newCoeff;
		end
	end
	%if(any(isnan(newCoeff)))
		%keyboard
	%end
else%coeff is a vector, so this vector is used as filter coefficients
	newCoeff = coeff;
end
sigVecNew = zeros(size(sigVec));
sigVecNew(2,:) = sigVec(1,:);
sigVecNew(1,:) = sigVec(1,:) .* newCoeff;
