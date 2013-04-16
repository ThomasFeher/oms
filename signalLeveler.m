%adjusts two signals to have a certain level ratio (signal1/signal2)
%only the level of the second signal is changed
%needs function file snr.m to work properly
%@param signal1 vector containing signal one
%@param signal2 vector containing signal two
%@param level of second signal in respect to the first one in dB
%@return vector containing adjusted signal two
%@return level adjustment of the second signal
function [out adjustment] = signalLeveler(signal1,signal2,level)
usage = 'usage: [signal2 adjustment] = signalLeveler(signal1,signal2,level)';
if(nargin~=3)
	error(usage);
end
if(~isscalar(level))
	error('level must be a scalar');
end

sir = snr(signal2,signal1);
adjustment = level - sir;
adjustmentLinear = 10^(adjustment/20);
out = signal2 * adjustmentLinear;
