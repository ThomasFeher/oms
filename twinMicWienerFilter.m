%wiener filter for twin microfone. Front cardioid is signal+noise, back cardioid
%is only noise.
function [sigVecNew newCoeff] = twinMicWienerFilter(options,sigVec,coeff)
sigPlusNoiseSwitch = options.twinMic.wienerFilter.signalPlusNoiseEstimate;
sigToFilterSwitch = options.twinMic.wienerFilter.signalToFilter;

if(nargin<3||isfield(coeff,'previous')) %calculate new coefficients
	%get signal-plus-noise signal
	if(strcmpi(sigPlusNoiseSwitch,'cardioid'))
		sigPlusNoise = sigVec(1,:);
	elseif(strcmpi(sigPlusNoiseSwitch,'sphere'))
		sigPlusNoise = sum(sigVec);
	else
		error(['undefined value for "signalPlusNoiseEstimate": '...
				sigPlusNoiseSwitch]);
	end
	%calculate filter coefficients
	newCoeff = 1-(abs(sigVec(2,:)).^2)./(abs(sigPlusNoise).^2);
	%check for out of range coefficients
	newCoeff(newCoeff<0) = 0;
	newCoeff(newCoeff>1) = 1;
	newCoeff(isnan(newCoeff)) = 0;
	%recursive smoothing
	if(isfield(coeff,'previous'))
		if(~isempty(coeff.previous))
			u = options.twinMic.wienerFilter.update;
			newCoeff = (1-u)*coeff.previous + u*newCoeff;
		end
	end
else%coeff is a vector, so this vector is used as filter coefficients
	newCoeff = coeff;
end

%apply filter coefficients
sigVecNew = zeros(size(sigVec));
sigVecNew(2,:) = sigVec(1,:);
if(strcmpi(sigToFilterSwitch,'cardioid'))
	sigVecNew(1,:) = sigVec(1,:) .* newCoeff;
elseif(strcmpi(sigToFilterSwitch,'sphere'))
	sigVecNew(1,:) = sum(sigVec) .* newCoeff;
end
