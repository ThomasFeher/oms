% takes the amplification of the back cardioid and the wanted direction as
% input and returns the amplification in that direction
% input:
% @beta: amplification of second cardioid (0:1)
% @angle: angle of wanted direction in degree
% output:
% @amp: apmlification of signals coming from this direction
function amp = twinPattern(beta,angle)
angleRad = angle/180*pi;
amp = ((1+beta).*cos(angleRad) + (1-beta))./2;

%!assert(twinPattern(0,0),1,eps);
%!assert(twinPattern(0,90),0.5,eps);
%!assert(twinPattern(0,180),0,eps);
%!assert(twinPattern(1,0),1,eps);
%!assert(twinPattern(1,90),0,eps);
%!assert(twinPattern(1,180),-1,eps);
%!assert(twinPattern(1/3,120),0,eps);
%!assert(twinPattern(1/3,0),1,eps);
%!assert(twinPattern([1,0],[0,180]),[1,0],eps);
