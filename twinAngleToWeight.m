% Takes an angle and returns the weight of the back cardioid of a back-to-back
% cardioid DMA.
% To produce the wanted pattern use <s_front - w * s_back>. Note the minus!
% input:
% @angle: angle in degree between 90° and 180°
% output:
% @w: weight of the back cardioid between 0 and 1
function w = twinAngleToWeight(angle)
angleRad = angle/180*pi;
w = (-cos(angleRad)-1)./(cos(angleRad)-1);

%!assert(twinAngleToWeight(90),1,eps);
%!assert(twinAngleToWeight(180),0,eps);
