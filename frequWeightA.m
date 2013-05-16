%does A-weighting in frequency domain
%@input signal matrix of signals in rows [sigNum,sampleNum]
function [signal weightVec] = frequWeightA(signal,frequencies)
if(~isvector(frequencies))
	error('frequencies must be a vector');
elseif(size(frequencies,2)==1)
	frequencies = frequencies.';
end
if(size(signal,2)~=size(frequencies,2))
	error('signal and frequencies must have same length');
end

weightVec = (12200^2 * frequencies.^4) ./ ((frequencies.^2 + 20.6^2) ...
		.* sqrt((frequencies.^2 + 107.7^2) .* (frequencies.^2 + 737.9^2))...
		.* (frequencies.^2 + 12200^2));
%weightVec = weightVec + 0.20565;
signal = bsxfun(@times,signal,weightVec);

%!test
%! [noi result] = frequWeightA(1,1000)
%! assert(1,result)
