%calculates the weight for weighted addition of sphere and eight pattern to gain
%a resulting pattern with a specific null angle
%input:
	%angle: angle of the pattern null in degree
%output:
	%weight: weight a to calculate the resulting pattern as follows:
	% 		a*Sphere + (1-a)*Eight = result
function weight = admaNullToSphereAndEight(angle)
angle = angle/180*pi;
weight = cos(angle)/(cos(angle)-1);
