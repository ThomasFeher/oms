%calculates the extrema of a the values in x
%returns their number 'num'
%their position 'pos' in x
%and a vector extrVec containing a 1 at the corresponding position of a
%maximum in x or a -1 at the corresponding position of a minimum in x
%or a 0 otherwise, respectively
function [num pos extrVec] = extrema(x);
%first derivative (differenze between adjacent values
xDiff = conv(x,[1 -1]);
%second derivative
xDiffDiff = conv(xDiff,[1 -1],'valid');
%sign of first derivative
xDiffSign = sign(xDiff);
%change of signum (zero crossing)
crossings = conv(xDiffSign,[1 -1],'valid');
%zero crossings mark an extremum
%minimum if second derivative is positive
%maximum if second derivative is negative
extrVec = abs(crossings).*(-sign(xDiffDiff))/2;
%set other values to zero
extrVec = (abs(extrVec)==1).*extrVec;
%extract position indeces
pos = find(extrVec);
%count number of found positions (number of extremas)
num = numel(pos);
end
