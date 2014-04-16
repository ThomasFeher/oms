function wVec = waveVec(geometry,freqs,targets,speedOfSound)
% This function calculates the wave vector containing the complex amplitude of
% an incoming wave from target positions specified in <targets> at the
% microphone positions specified in <geometry> and the frequencies specified in
% <freqs>
% input:
%   geometry: microphone positions [x1 x2 …;y1 y2 …;z1 z2 …]
%   freqs: vector of frequencies in Hz
%   targets: target positions [x1 x2 …;y1 y2 …;z1 z2 …]
%   speedOfSound: scaler giving the speed of sound in m/s
% output:
%   wVec: complex amplitudes [mic,freq,target]

if(iscolumn(freqs))
	freqs = freqs.';
end

micNum = numel(geometry(1,:));
targets = permute(targets,[1 3 2]); % [coord,[],target]
refPos = geometry(:,1); % first mic is reference mic
amplitudes = vecDist(targets,refPos)./vecDist(targets,geometry); % [[],mic,target]
% this differs from the Brandstein book! but makes algo independent of chosen
% reference microphone
amplitudes = amplitudes ./ sum(amplitudes) * micNum;
delays = (vecDist(targets,refPos)-vecDist(targets,geometry))./ speedOfSound; % [[],mic,target]
amplitudes = permute(amplitudes,[2,1,3]); % [mic,[],target]
delays = permute(delays,[2,1,3]); % [mic,[],target]
wVec = amplitudes .* e.^(-i*2*pi*delays.*freqs); % [mic,freq,target]

function ret = vecDist(vec1,vec2)
% distance between two vector given as column vectors
ret = sqrt(sum((vec1-vec2).^2));

%!shared micNum,geometry,freqNum,freqs,targetNum,targets
%! micNum = 2;
%! geometry = [linspace(-1,1,micNum);0 0;0 0];
%! freqNum = 10;
%! freqs = linspace(1,1000,freqNum);
%! targetNum = 5;
%! targets = [linspace(-2,2,targetNum);ones(2,targetNum)];

%!test # output size
%! result = waveVec(geometry,freqs,targets,340);
%! assert(size(result),[micNum,freqNum,targetNum]);

%!test # wave from front should give equal amplitudes at all microphones
%! targetNum = 1;
%! targets = zeros(3,targetNum);
%! result = waveVec(geometry,freqs,targets,340);
%! assert(result==result(1,:,:));

%!test # freqs in column vector
%! freqs = linspace(1,1000,freqNum).';
%! result = waveVec(geometry,freqs,targets,340);

%!test # negative coordinates
%! targetNum = 2;
%! targets = [0 0;-2 2;0 0];
%! result = waveVec(geometry,freqs,targets,340);
%! assert(result(:,:,1),conj(result(:,:,2)),eps);

%!test # sum of elements is equal to number of microphones
%! result = waveVec(geometry,freqs,targets,340);
%! for cnt=1:targetNum
%!   assert((sum(abs(result(:,:,cnt)))),ones(1,freqNum)*micNum,eps);
%! end
