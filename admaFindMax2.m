%-----------------------------------------------------------------------
%| Function: admaFindMax2
%-----------------------------------------------------------------------
%| Find angle of speaker and noise
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    08.11.2012 
%| Library: ADMA
%|
%|
%|
%| @param <3xN complex> sigVec      - Matrix with 3 cardioid patterns in 
%|                                    freq. domain (N=number of freqencies)
%| @param <1xM double> search_range - Array with angles range to look for
%| @param <3xMxN double> weights    - Weights to build diffrent patterns
%| @param <1x2 int> speaker_range   - Upper and lower bound. of speaker range
%| @param <int> last_theta1         - Speaker pos. of last block
%|
%| @return <1x2 int> angles         - angle of speaker and noise
%| @return <1xM in> power1          - power of signal for each angle of <search_range>
%| @return <bool> no_speaker        - true, if no source is found in speaker_range
%----------------------------------------------------------------------

function [ angles power no_speaker] = admaFindMax2(sigVec, search_range, weights, speaker_range, last_theta1)

  T = zeros(size(sigVec));
  power = zeros(1,numel(search_range));
  
  %loop search range
  for (searchCnt = 1:numel(search_range)) 
    w = squeeze(weights(:,searchCnt));   
    T = w' * sigVec;
    power(searchCnt) = sum(abs(T));      % eigentlich Quadrat statt abs
  end   %end angle loop

  %Find all relative Maxima
  abbr = circshift(power,[0 1])-power;
  abbr = abbr ./ abs(abbr);
  tmp =  circshift(abbr,[0 -1])-abbr;

  
  n=0;
  angles = [NaN NaN];     %init angles

  for (k=1:numel(tmp))
    if (tmp(k) == 2) || (tmp(k) == NaN)
      pos = search_range(k);
      if (limitAngle(pos-speaker_range(1)) < (speaker_range(2)-speaker_range(1))) %Angle in speaker range
        if (isnan(angles(1))) || (sigVec(k) > sigVec(angles(1)))              %Highest power
          angles(1) = k;
        end
      elseif ((isnan(angles(2))) || (sigVec(k) > sigVec(angles(2))))
          angles(2) = k;
      end
    end
  end

  
  
if (isnan(angles(1)))         %no max found in speaker range
  no_speaker = true;
  if (isnan(last_theta1))     %no max found in speaker range before
    if (isnan(angles(2)))     %no max found outside of speaker range either (very unlikely)
      angles(1) = 0;           %return random cardioid
      angles(2) = 180;
    else
      angles(2) = search_range(angles(2));  %convert index to angle;
      angles(1) = angles(2) + 180;   %return cardioid with min to angle2
    end
  else                        %max angle from last block exists
    angles(1) = last_theta1;   %keep last angle1
    if (~isnan(angles(2)))
      angles(2) = search_range(angles(2));
    else
      angles(2) = angles(1) + 180;  %return cardioid with max to theta1
    end;
  end
else                          %max found in speaker range
  no_speaker = false;
  angles(1) = search_range(angles(1));    %convert found index to angle
  if (~isnan(angles(2)))
    angles(2) = search_range(angles(2));
  else
    angles(2) = angles(1) + 180;  %return cardioid with max to theta1
  end;
end
