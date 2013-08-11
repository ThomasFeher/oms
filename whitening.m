function [z,V,eigVal]=whitening(signal)

%Center Data

%Whitening
covariance = signal*signal'/size(signal,2);
[eigVec,eigVal] = eig(covariance);
V = sqrt(inv(eigVal))*eigVec';
z = V*signal;

