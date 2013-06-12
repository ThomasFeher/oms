%generate pattern out of a cardioid coeff
%pattern is generated via: coeff*frontCardioid - (1-coeff)*backCardioid
%@input:
	%@coeff: 0 <= coeff <= 1
	%@resolution: in degree
%@output:
	%@pattern: pattern
	%@phi: angles in degree
function [pattern phiDeg] = admaCardioidCoeffToPattern(coeff,resolution)
if(nargin<2)
	resolution = 1;
end
if(isrow(coeff))
	coeff = coeff.';
end

%calc angles
phiDeg = [0:resolution:360];
phi = phiDeg/180*pi;

%calc cardioids
cardioid1 = (1+cos(phi))/2;%front cardioid
cardioid2 = (1-cos(phi))/2;%back cardioid

%calc pattern out of cardioids and the coefficient
pattern = (coeff*cardioid1 - (1-coeff)*cardioid2)./(0.5+abs(coeff-0.5));

%low resolution back cardioid
%!test
%! assert(admaCardioidCoeffToPattern(0,10),-(1-cos([0:10:360]/180*pi))/2,eps)

%automatic resolution back cardioid
%!test
%! assert(admaCardioidCoeffToPattern(0),-(1-cos([0:360]/180*pi))/2,eps)

%back cardioid
%!test
%! assert(admaCardioidCoeffToPattern(0,1),-(1-cos([0:360]/180*pi))/2,eps)

%eight
%!test
%! assert(admaCardioidCoeffToPattern(0.5,1),(cos([0:360]/180*pi)),eps)

%front cardioid
%!test
%! assert(admaCardioidCoeffToPattern(1,1),(1+cos([0:360]/180*pi))/2,eps)

%vectorized coeffs
%!test
%! coeff = [0 0.5 1];
%! pattern = admaCardioidCoeffToPattern(coeff);
%! assert(size(pattern),[3,361])

%angle outpuh
%!test
%! [noi phi] = admaCardioidCoeffToPattern(0,10);
%! assert(phi,[0:10:360]);
