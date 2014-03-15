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

lhCoeff = options.lhCoeff; % for convenience

if(isfield(params,'previous'))
	if(isempty(params.previous))
		params.previous.angles = options.angle;
		params.previous.ampFront = [1 1];
		isFirst = true;
	else
		isFirst = false;
	end

	% calculate weight matrix
	W = twinAngleToMixMat(params.previous.angles);
	W = bsxfun(@times,W,params.previous.ampFront.');

	% ica with new signal
	blockPremix = W * block;
	WNew = FastICA(blockPremix,options.iterations);
	WNew = WNew * W;

	% estimate angles and amplifications
	angles = twinIcaToAngle(WNew,false);
	[~,ampFront] = twinIcaToAmp(WNew);

	% use old data if any nan occurs
	if(any(isnan(angles))|any(isnan(ampFront)))
		angles = params.previous.angles;
		ampFront = params.previous.ampFront;
	end

	% sort according to angles
	[angles sortIdx] = sort(angles,'descend');
	ampFront = ampFront(sortIdx);

	% update angles and amplifications
	if(~isFirst)
		angles = options.updateAngle*angles ...
		       + (1-options.updateAngle)*params.previous.angles;
		ampFront = options.updateAmp*ampFront ...
				 + (1-options.updateAmp)*params.previous.ampFront;
	end

	% calculate ampSrc from updated values
	ampSrc = twinIcaToAmp(bsxfun(@times,twinAngleToMixMat(angles),ampFront.'));

	% calculate nullsteering weights
	WNs = twinAngleToMixMat(angles);

	% apply nullsteering to frequency domain signal
	sigVecNs = WNs * sigVec;

	% calculate mask by MAP-estimator
	sigVecNsAbs = abs(sigVecNs);
	sigVecNsAbs = sigVecNsAbs./max(max(sigVecNsAbs));
	% likelyhood chan 1
	lh1 = (lhCoeff * ((sigVecNsAbs(1,:)-sigVecNsAbs(2,:)) ));
	% likelyhood chan 2
	lh2 = (lhCoeff * ((sigVecNsAbs(2,:)-sigVecNsAbs(1,:)) ));
	% aposteriori probability
	if(options.doAposteriori)
		ap1 = lh1 * (ampSrc(2) / ampSrc(1)); % aposteriori chan 1
		ap2 = lh2 * (ampSrc(1) / ampSrc(2)); % aposteriori chan 2
	else
		ap1 = lh1;
		ap2 = lh2;
	end
	mask = [ap1>ap2;ap2>ap1]; % get maximum

	% update mask
	if(~isFirst)
		mask = options.updateMask*mask ...
		     + (1-options.updateMask)*params.previous.mask;
	end

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
