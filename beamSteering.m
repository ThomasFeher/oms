function W = beamSteering(angle,geometry,frequencies,c)
% calculates weights in frequency domain to get a main lobe in certain direction
% input:
% 	angle: angle of main lobe in degree
% 	geometry: geometry of microphones, row vector of coordinates (only one
% 			dimension supported)
% 	frequencies: vector of frequencies to calculate weights for
% 	c: speed of sound in m/s
% output:
% 	W: weight matrix [frequency,mic]

warning(['<beamSteering> is deprecated, use <waveVec> or '...
         '<weightMatSynth_mvdr> instead']);

if(~isvector(geometry))
	error('geometry must be a vector');
end
if(iscolumn(geometry))
	geometry = geometry.';%transpose to row vector
end
if(~isvector(frequencies))
	error('frequencies must be a vector');
end
if(isrow(frequencies))
	frequencies = frequencies.';
end

angle = angle/180*pi;%transform in radians
directionVector = geometry * sin(angle);
W = exp(-i*2*pi*directionVector.'*frequencies.'/c)/numel(geometry);
