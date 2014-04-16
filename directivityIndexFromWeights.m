function di = directivityIndexFromWeights(weights,freqs,geometry,target,speedOfSound)
% Calculates the directivty index from given microphone positions and weights
% and a look direction. It uses the approach given in Brandstein "Microphone
% Arrays - Signal Processing Techniques and Applications" equation 2.18.
%
% input:
%   weights: microphone weights, size: [mic,freq]
%   freqs: vector containing the frequencies in Hz
%   geometry: microphone positions, [x1,x2,…;y1,y2,…;z1,z2,…]
%   target: reference position to calculate directivity at, given as column
%              vector of coordinates
%   speedOfSound: speed of sound in m/s
% output:
%  di: directivity index in dB, size [1,freq]

% wave vector for target direction
wVec = squeeze(waveVec(geometry,freqs,target,speedOfSound)); % size: [mic,freq]

% coherence of wave vector, should also work
%cohMat = mult3dArray(permute(wVec,[1,3,2]),permute(wVec,[3,1,2]));
%cohMat = coherenceMatNearfield(geometry,freqs,target,speedOfSound);
%nominator = sum(squeeze(mult3dArray(permute(conj(weights),[3,1,2]),cohMat)) .* weights);

nominator = abs(sum(conj(weights) .* wVec)).^2;

% coherence matrix
cohMat = coherenceMatNearfield(geometry,freqs,'diffuse',speedOfSound);

denom = sum(squeeze(mult3dArray(permute(conj(weights),[3,1,2]),cohMat)) .* weights);

di = 10*log10(abs(nominator ./ denom));

%!test # size of output
%! micNum = 3;
%! freqNum = 10;
%! weights = rand(micNum,freqNum);
%! freqs = linspace(100,1000,freqNum);
%! geometry = rand(3,micNum);
%! target = rand(3,1);
%! speedOfSound = 340;
%! x = directivityIndexFromWeights(weights,freqs,geometry,target,speedOfSound);
%! assert(size(x),[1,freqNum]);
