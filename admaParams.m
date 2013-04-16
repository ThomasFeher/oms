%-----------------------------------------------------------------------
%| Function: admaParams
%-----------------------------------------------------------------------
%| Calculate weights to generate first ordner microphone pattern  for
%| 3 channel differential microphone array. 
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    14.09.2012 
%|
%|
%|
%| @param (int)      angle1 - angle of maximum of pattern
%| @param (int)      angle1 - angle of minimum of pattern
%| @param (int)array freq   - Array with frequencies
%|
%| @return (dbl)matrix results - [3 x numel(freq)] weights to generate
%|                               desired pattern
%|                      
%----------------------------------------------------------------------
function [x] = admaParams(angle1, angle2)    
  c=340;

  nenner = 2*((sin(((angle1-angle2)*pi/180)/2)).^2);
   
  
  a = 1/3 * ((2*cos((angle1- 30)*pi/180)-1)./nenner +1);       
  b = 1/3 * ((2*cos((angle1-150)*pi/180)-1)./nenner +1);
  c = 1/3 * ((2*cos((angle1-270)*pi/180)-1)./nenner +1);
  x = [a; b; c];
  
  x=squeeze(x);
end
