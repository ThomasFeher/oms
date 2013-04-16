%-----------------------------------------------------------------------
%| Function: admaMask
%-----------------------------------------------------------------------
%| Calculate the binary time-frequency-mask
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    15.10.2012 
%| Library: ADMA
%|
%----------------------------------------------------------------------

function [newMask] = admaMask(window,sigVec,weights,freqVec)
  
  %Parameter
  c=340;
  dist = 24.8e-3;

  %build cardioid patterns of normalized mic spectrum
  sigVec(1,:) = sigVec(1,:) ./ (abs(sigVec(1,:)));
  sigVec(2,:) = sigVec(2,:) ./ (abs(sigVec(2,:)));
  sigVec(3,:) = sigVec(3,:) ./ (abs(sigVec(3,:)));
  
  sigVecCardioid(1,:) = (sigVec(1,:) - sigVec(2,:) .* exp((-j*2*pi*dist/c) * freqVec));
  sigVecCardioid(2,:) = (sigVec(3,:) - sigVec(1,:) .* exp((-j*2*pi*dist/c) * freqVec));
  sigVecCardioid(3,:) = (sigVec(2,:) - sigVec(3,:) .* exp((-j*2*pi*dist/c) * freqVec));

  
  sphere = abs(1/3*sum((sigVecCardioid)));
  threshold = window * sphere;
  
  ref =  abs(weights' * (sigVecCardioid));
  
  newMask = ref>threshold;
 
end
