%-----------------------------------------------------------------------
%| Function: admaFindMin
%-----------------------------------------------------------------------
%| The function eliminate unwanted noise sounds by variing the minimum of
%| pattern in the <search_range>. Calculating of the weights isn't to in 
%| the function each time for preformence reasons.
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    08.10.2012 
%| Library: ADMA
%|
%|
%|
%| @param <3xN complex> sigVec      - Matrix with 3 cardioid patterns in 
%|                                    freq. domain (N=number of freqencies)
%| @param <1xM double> search_range - Array with angles range to look for
%| @param <3xMxN> double> weights   - Weights to build diffrent patterns
%|
%| @return <int> angle              - angle with smallest signal energy
%| @return <1xM double>             - signal for each angle of <search_range>
%|
%----------------------------------------------------------------------

function [ angle pattern ] = admaFindMin(sigVec, search_range, weights)
  %pre-allocate arrays
  T = zeros(size(sigVec));
  pattern = zeros(1,numel(search_range));
  
  %loop angle range
  for (searchCnt = 1:numel(search_range)) 
    w = squeeze(weights(:,searchCnt));   
    T = w' * sigVec;
    pattern(searchCnt) = sum(abs(T));
  end   %end angle loop
      
  %pattern
  
  %look for minimum
  [noi idx] = min(pattern);
  angle = search_range(idx);
end
