function W = beamSteeringNearfield(target,geometry,freqs,speedOfSound)
%calculates weights in frequency domain to get a main lobe in certain direction
%input:
% 	target: target position as coordinate [x;y;z]
% 	geometry: geometry of microphones, [x1 x2 …;y1 y2 …;z1 z2 …]
% 	freqs: vector of frequencies to calculate weights for
% 	speedOfSound: speed of sound in m/s
%output:
% 	W: weight matrix [frequency,mic]

if(~iscolumn(target) || ~(numel(target)==3))
	error('First argument must be a column vector of size 3.');
end
if(size(geometry,1)~=3)
	error('Second input argument must have 3 rows.');
end
if(~isvector(freqs))
	error('Third input argument must be a vector.');
end
if(iscolumn(freqs))
	freqs = freqs.';
end

W = squeeze(permute(conj(waveVec(geometry,freqs,target,speedOfSound)),[2,1,3]));
%angle = angle/180*pi;%transform in radians
%directionVector = geometry * sin(angle);
%W = exp(-i*2*pi*directionVector.'*frequencies.'/c)/numel(geometry);

%!shared micNum,geometry,freqNum,freqs,target,speedOfSound
%! micNum = 2;
%! geometry = [linspace(-1,1,micNum);0 0;0 0];
%! freqNum = 10;
%! freqs = linspace(1,1000,freqNum);
%! target = [1;0;0];
%! speedOfSound = 340;

%!test # output size
%! result = beamSteeringNearfield(target,geometry,freqs,speedOfSound);
%! assert(size(result),[freqNum,micNum]);
