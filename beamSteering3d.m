%calculates weights in frequency domain to get a main lobe in certain direction
%input:
% 	phi: angle of main lobe in degree
% 	teta: angle of main lobe in degree
% 	geometry: geometry of microphones, [coords,mics]
% 	frequencies: vector of frequencies to calculate weights for
% 	c: speed of sound in m/s
%output:
% 	W: weight matrix [mic,frequency]

function W = beamSteering3d(phi,teta,geometry,frequencies,c)
if(size(geometry,1)~=3)
	%is already checked in framework?
	error('geometry must contain three dimensions');
end
if(~isvector(frequencies))
	error('frequencies must be a vector');
end
if(isrow(frequencies))
	frequencies = frequencies.';
end

%angle = angle/180*pi;%transform in radians
phi = phi/180*pi;%transform in radians
teta = teta/180*pi;%transform in radians
dirVec = [sin(teta)*cos(phi),sin(teta)*sin(phi),cos(teta)];
distVec = dirVec * geometry
W = exp(i*2*pi*distVec.'*frequencies.'/c)/numel(geometry);
