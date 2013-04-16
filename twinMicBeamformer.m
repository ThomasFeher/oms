function [sigVecNew newMask] = twinMicBeamformer(options,sigVec,mask)
if(nargin<3||isfield(mask,'previous')) %calculate new mask
	%beamformer angle in radians
	angle = options.twinMic.beamformer.angle/180*pi;
	%calc threshold from angle
	threshold = (1+cos(angle/2))/2;
	sphere = sigVec(1,:) + sigVec(2,:);%sphere signal
	eight = sigVec(1,:) - sigVec(2,:);%eight signal
	cardio = sigVec(1,:);%cardioid signal
	divided = abs(cardio)./abs(sphere);%ratio between cardioid and sphere
	newMask = divided>threshold;%calc mask
	if(isfield(mask,'previous'))%is there a previous mask?
		if(~isempty(mask.previous))%is previous mask not empty?
			u = options.twinMic.beamformer.update;%get update coefficient
			newMask = (1-u)*mask.previous + u*newMask;%apply update coefficient
		end
	end
else%mask is a vector, so this vector is used as mask
	newMask = mask;
end

sigVecNew = zeros(size(sigVec));%new empty vector
sigVecNew(2,:) = sigVec(1,:);%second channel is unmasked front cardioid
sigVecNew(1,:) = sigVec(1,:) .* newMask;%first channel is processed cardioid
