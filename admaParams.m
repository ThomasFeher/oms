%-----------------------------------------------------------------------
%| Function: admaParams
%-----------------------------------------------------------------------
%| Calculate weights to generate first order microphone pattern  for
%| 3 channel differential microphone array. 
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    14.09.2012 
%|
%|
%|
%| @param (int)      angle1 - angle of maximum of pattern
%| @param (int)      angle2 - angle of minimum of pattern
%|
%| @return (dbl)matrix results - [3 x numel(freq)] weights to generate
%|                               desired pattern
%|                      
%----------------------------------------------------------------------
function [x] = admaParams(angle1, angle2, steeringMethod)
if(nargin<3)
	steeringMethod = 'michelson';
end

if(strcmpi(steeringMethod,'michelson'))
	denom = 2*((sin(((angle1-angle2)*pi/180)/2)).^2);

	a = 1/3 * ((2*cos((angle1- 30)*pi/180)-1)./denom +1);       
	b = 1/3 * ((2*cos((angle1-150)*pi/180)-1)./denom +1);
	c = 1/3 * ((2*cos((angle1-270)*pi/180)-1)./denom +1);
	x = [a; b; c];
elseif(strcmpi(steeringMethod,'eights'))
else
	error(['unknown steering method: ' steeringMethod]);
end

x=squeeze(x);
