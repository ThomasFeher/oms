function [sigVecNew newMask] = distanceFilter(options,sigVec,mask)
if(nargin<3||isfield(mask,'previous')) %calculate new mask
	threshold = options.distanceFilter.threshold;
	cutoffH = max(find(options.frequency<options.distanceFilter.cutoffFrequencyHigh));
	if(isempty(cutoffH))
		cutoffH = 1;
	end
	cutoffL = max(find(options.frequency<options.distanceFilter.cutoffFrequencyLow));
	if(isempty(cutoffL))
		cutoffL = 1;
	end
	sphere = sigVec(1,cutoffL:cutoffH) + sigVec(2,cutoffL:cutoffH);
	eight = sigVec(1,cutoffL:cutoffH) - sigVec(2,cutoffL:cutoffH);
	%divided = abs((sphere./eight));
	divided = abs(sphere)./abs(eight);
	newMask = divided<threshold;
	%distance gate
	if(((numel(find(newMask==0))/numel(newMask))>options.distanceGate.threshold)&&...
				options.distanceFilter.withGate)
		%newMask = [zeros(1,cutoffL-1) newMask zeros(1,size(sigVec,2)-cutoffH)];
		newMask = zeros(size(sigVec(1,:)));
	else
		newMask = [ones(1,cutoffL-1) newMask ones(1,size(sigVec,2)-cutoffH)];
	end
	%recursive smoothing
	if(isfield(mask,'previous'))
		if(~isempty(mask.previous))
			update = options.distanceFilter.update;
			newMask = (1-update)*mask.previous + update*newMask;
		end
	end
else%mask is a vector, so this vector is used as mask
	newMask = mask;
end

sigVecNew = zeros(size(sigVec));
sigVecNew(2,:) = sigVec(1,:) + sigVec(2,:);
sigVecNew(1,:) = sigVec(1,:) .* newMask;
%sigVecNew(1,:) = sigVecNew(2,:) .* newMask;
