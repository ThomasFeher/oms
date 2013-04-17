function [num pos posMat] = zeroCross(x);
%disp(x);
%num = 0;
%pos = 0;
xDiff = conv(x,[1 -1],'same');
%disp(xDiff);
xDiffSign = sign(xDiff);
%disp(xDiffSign);
crossings = conv(xDiffSign,[1 -1],'same');
%disp(crossings);
%disp(conv(xDiffSign,[1 -1]));
%disp(abs(crossings(1:end-1))==2);
%pos = find(abs(crossings(1:end-1))==2);
posMat = abs(crossings)==2;
pos = find(posMat);
num = numel(pos);
end
