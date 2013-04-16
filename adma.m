%-----------------------------------------------------------------------
%| Function: adma
%-----------------------------------------------------------------------
%| Process the signal of the 3 channel differential 
%| microphone array. 
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    06.09.2012 
%| Library: ADMA
%|
%-----------------------------------------------------------------------

function [ out  options sigVecCard ] = adma(sigVecProc,freqVec,fs,options...
											,speedOfSound)
%% PARAMETER %%
d = options.d;    %distance between microphones

%Build cardioid signals
sigVecCard = admaBuildCardioids(sigVecProc,freqVec,d,speedOfSound);

no_speaker = false;
%% Locate Speaker %%
if (options.findMax)%use adaptive alogrithm to find speaker
	search_range = options.search_range;
	weights = admaParams(search_range, search_range+180);  %weights
	if (isfield(options,'speaker_range'))     %use function with speaker_range
		[theta power1 no_speaker] = admaFindMax2(sigVecSearch, ...
			search_range, ...
			weights, ...
			options.speaker_range, ...
			options.last_theta);
		theta1 = theta(1);
		if (options.findMin)        
			if (isnan(theta(2)))
				theta2 = theta1+180;
			else
				theta2 = theta(2);
			end
		else
			theta2 = options.theta2;
		end
	else%use function wiouth speaker_range
		[theta1 power1] = admaFindMax(sigVecSearch, search_range, weights);
		if (options.findMin)
			search_range = (theta1+90):15:(theta1+270);
			weights = admaParams(theta1*ones(size(search_range)),search_range);
			[theta2] = admaFindMin(sigVecCard, search_range,weights);
		else
			theta2 = options.theta2;
		end
	end
%diff between theta1 & theta2 < 90deg?
%if (real(exp(j*(theta2-theta1)/180*pi))>0)
%  theta1 = theta2 + 90;
%end
else%do not use adaptive algo to find speaker
	theta1 = options.theta1;
	if (options.findMin)
		search_range = (theta1+90):15:(theta1+270);
		weights = admaParams(theta1*ones(size(search_range)),search_range);
		[theta2] = admaFindMin(sigVecCard, search_range,weights)
	else
		theta2 = options.theta2;
	end
end%findMax

%Cancel audio if no speaker is found
if (no_speaker && options.zero_noise)
	out = zeros(size(sigVecProc));
	out(3,:) = 1/3*sum(sigVecCard); 
	options.newMask = -1;
	options.theta2 = NaN;
else  
	%% Build Pattern
	if (strcmpi(options.pattern, 'cardioid'))
		theta2 = theta1+180;
	end
	if(limitAngle(theta1) == limitAngle(theta2))
		theta1 = theta2+180;
	end
	%calculate weights
	weights1 = admaParams(theta1, theta2);        %best pattern
	%claculate output signals  
	out(1,:) = weights1' * sigVecCard;       %best pattern 1
	out(2,:) = weights1' * sigVecCard;       %best pattern 2
	out(3,:) = 1/3*sum(sigVecCard);          %omni directional
	%% Apply binary mask to best pattern 1
	if (options.Mask)
		newMask = admaMask(options.mask_angle,sigVecProc,weights1,freqVec);

		if (options.oldMask ~= -1)
			newMask = options.mask_update * newMask...
				+ (1-options.mask_update) * options.oldMask;
		end
		out(1,:) = newMask .* out(1,:);
		options.newMask = newMask;
	else 
		options.newMask = -1;
	end
	options.theta1 = theta1;
	options.theta2 = theta2;
end
end   %end of function

%-----------------------------------------------------------------------
%| Function: bandpass
%-----------------------------------------------------------------------
%| Limits the freqVec and sigVec to a frequency band.
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    08.10.2012 
%| Library: Helper
%|
%----------------------------------------------------------------------

function [ freqVec sigVec ] = bandpass(lbound, ubound, Fs, freqVec, sigVec)
%calculate indices of boundries
lidx = floor(lbound/Fs*2*(size(freqVec,2)-1)+1);      %index of lower bound
uidx = ceil( ubound/Fs*2*(size(freqVec,2)-1)+1);       %index of upper bound

if (lidx == 1)
	lidx=2;                           %delete freq=0 in any case
end


if (ndims(sigVec)==2)
	sigVec(:,1:lidx-1) = zeros(size(sigVec(:,1:lidx-1)));
	sigVec(:,uidx:size(sigVec,2))...
		= zeros(size(sigVec(:,uidx:size(sigVec,2))));
elseif (ndims(sigVec)==3)
	sigVec(:,:,1:lidx-1) = zeros(size(sigVec(:,:,1:lidx-1)));
	sigVec(:,:,uidx:size(sigVec,3))...
		= zeros(size(sigVec(:,:,uidx:size(sigVec,3))));
end
end
%% End of file 'adma.m'  
