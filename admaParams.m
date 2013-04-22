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
function [weightMat] = admaParams(angle1, angle2, steeringMethod)
if(nargin<3)
	steeringMethod = 'cardioids';
end

if(strcmpi(steeringMethod,'cardioids'))
	denom = 2*((sin(((angle1-angle2)*pi/180)/2)).^2);

	a = 1/3 * ((2*cos((angle1- 30)*pi/180)-1)./denom +1);       
	b = 1/3 * ((2*cos((angle1-150)*pi/180)-1)./denom +1);
	c = 1/3 * ((2*cos((angle1-270)*pi/180)-1)./denom +1);
	weightMat = [a; b; c];
elseif(strcmpi(steeringMethod,'eights'))
	%calculate components in x and y direction
	%this solution uses dma 1 and 3, in general each combination of 2 signals
	%can be used
	a1 = 30/180*pi;%angle of dma 1 is 30°
	a2 = 150/180*pi;%angle of dma 2 is 150°
	a3 = 270/180*pi;%angle of dma 3 is 270°
	denomY = sin(a3-a1);
	denomX = sin(a1-a3);
	angle1 = angle1/180*pi;
	angle2 = angle2/180*pi;
	eY = [-cos(a3);0;cos(a1)]./denomY(ones(3,1),:);
	eX = [-sin(a3);0;sin(a1)]./denomX(ones(3,1),:);
	%alternatively signal two could be used instead of signal 3
	%but be shure to change the denominators (denomX and denomY) accordingly
	%eX = [-sin(a2);0;sin(a1)]./denomX(ones(3,1),:);
	eK = [eX,eY];%matrix to convert from oblique-angled microphones to cartesian
	disp(eK);

	%calculate components in given direction by angle1
	eT = [cos(angle1);sin(angle1)];%matrix to convert from kartesian to target
																		%angle
	disp(eT);
	weightMat = eK * eT;%weightMat.'*sig gives the signal in target direction

	%TODO implement angle2 (angle of null), through weighted addition with sum
	%of all cardioids
else
	error(['unknown steering method: ' steeringMethod]);
end

weightMat=squeeze(weightMat);
