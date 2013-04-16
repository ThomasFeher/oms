%-----------------------------------------------------------------------
%| Function: limitAngle
%-----------------------------------------------------------------------
%| Limits angle to the range of 1 to 360
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    06.09.2012 
%| Package: Helper
%|
%|
%| @param int - angle
%| 
%| @return int - angle in range of 1 to 360
%----------------------------------------------------------------------
function [ y ] = limitAngle( x, lbound, ubound )
  if (nargin == 3)
    y = mod(x - ubound, ubound-lbound) + lbound;
  else
    y = mod(x-1,360)+1;
  end
end
