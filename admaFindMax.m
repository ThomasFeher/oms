%-----------------------------------------------------------------------
%| Function: admaFindMax
%-----------------------------------------------------------------------
%| Find angle with maximum power of signal
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
%| TODO: merge with admaFindMin()
%----------------------------------------------------------------------

function [ angle power] = admaFindMax(sigVec, search_range, weights)
  %pre-allocate arrays
  T = zeros(size(sigVec));
  power = zeros(1,numel(search_range));
  %pattern(searchCnt) = zeros(numel(search_range),size(sigVec));
  
  %loop angle range
  for (searchCnt = 1:numel(search_range)) 
    w = squeeze(weights(:,searchCnt));   
    T = w' * sigVec;
    power(searchCnt) = sum(abs(T));      % eigentlich Quadrat statt abs
    %pattern(searchCnt,:,:) = P;
  end   %end angle loop
  
  
  %look for minimum
  [noi idx] = max(power);
  angle = search_range(idx);
end
