% processes a first order DMA consisting of two back-to-back cardioids via
% maximum apostriory estimator based on ICA
% input:
% @options: options struct from OMS framework
% @sigVec: frequency domain signal vector []
% @block: time domain signal vector []
% @params: contains either an array with the binary mask to apply to signal
%          without any estimation, or a field <previous> containing the
%          parameters of the previous run
% @params.previous.mask: binary mask of previous run
% @params.previous.angles: angles of the nullsteering of the previous run
% @params.previous.ampFront: front amplification of previous run
% @params.previous.ampSrc: source amplification of previous run
% output:
% @sigVecProc: processed frequency domain signal vector
% @maskNew: binary mask used to process signal
function [sigVecProc,paramsNew] = twinMicIcaMap(options,sigVec,block,params)

if(isfield(params,'previous'))
	if(isempty(params.previous))
		W =twinAngleToMixMat(options.angle);
	else
		% calculate weight matrix
		W = twinAngleToMixMat(params.previous.angles);
		W = bsxfun(@times,W,params.previous.ampFront.');
	end
	% ica with new signal
	blockPremix = W * block;
	WNew = FastICA(blockPremix,options.iterations);
	WNew = WNew * W;

	% estimate angles and amplifications
	angles = twinIcaToAngle(WNew,false);
	[~,ampFront] = twinIcaToAmp(WNew);

	% sort according to angles
	[angles sortIdx] = sort(angles,'descend');
	ampFront = ampFront(sortIdx);

	% update angles and amplifications
	angles = options.update*angles + (1-options.update)*params.previous.angles;
	ampFront = options.update*ampFront
	         + (1-options.update)*params.previous.ampFront;

	% calculate ampSrc from updated values
	ampSrc = twinIcaToAmp(bsxfun(@times,twinAngleToMixMat(angles),ampFront.'));

	% calculate nullsteering weights
	WNs = twinAngleToMixMat(angles);

	% apply nullsteering to frequency domain signal
	sigVecNs = WNs * sigVec;

	% calculate mask by MAP-estimator
	sigVecNsAbs = abs(sigVecNs);
	denom = (2*(sigVecNsAbs(1,:)+sigVecNsAbs(2,:))); % common denominator
	lh1 = (sigVecNsAbs(1,:)-sigVecNsAbs(2,:)) ./ denom + 0.5; % likelyhood chan 1
	lh2 = (sigVecNsAbs(2,:)-sigVecNsAbs(1,:)) ./ denom + 0.5; % likelyhood chan 2
	ap1 = lh1*ampSrc(2)/ampSrc(1); % aposteriori chan 1
	ap2 = lh2*ampSrc(1)/ampSrc(2); % aposteriori chan 2
	mask = [ap1>ap2;ap2>ap1]; % get maximum

	% update mask
	mask = options.update*mask + (1-options.update)*params.previous.mask;

	%store estimated parameters
	paramsNew.mask = mask;
	paramsNew.angles = angles;
	paramsNew.ampFront = ampFront;
else
	% calculate nullsteering weights
	WNs = twinAngleToMixMat(params.angles);

	% apply nullsteering to frequency domain signal
	sigVecNs = WNs * sigVec;
	
	% get mask
	mask = params.mask;
end

% apply mask
sigVecProc = sigVecNs .* mask;

%!share
%! 
