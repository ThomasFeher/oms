%histogram in time-frequency-domain
function [tfh centers] = tfHist(data1,data2,d,c,f)
if(nargin~=5)
	error('5 input arguments needed!');
end
if(~isvector(data1))
	error('First input argument must be a vector!');
end
if(~isvector(data2))
	error('Second input argument must be a vector!');
end
phi = angle(data1./data2)*c/(2*pi*f*d);
phi(phi>1) = nan;
phi(phi<-1) = nan;
phi = asin(phi);
%plot(imag(acos(phi)));
centers = (-90:89)/180*pi;
%[tfh ] = histc(asin(phi),centers);
[tfh centers] = hist(phi,centers);
