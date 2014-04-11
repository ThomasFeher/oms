function result = beampatternNearfield(options)
% This function calcualates the beampattern of a given mikrophone array and for
% given target points. It uses the exact calculation of the time delay.
% input:
%   options: OMS options struct
% output:
%   pattern: squared response of the array for each target position
%            [freqency,target]

W = options.beamforming.weights;

% vector of incoming wave from wanted direction
signalVec = waveVec(options.geometry...
                   ,options.frequency...
                   ,options.beamforming.beampattern.targets...
                   ,options.c);

% calculate pattern
% TODO this is for plane waves, the denominator changes for other noise fields
%   see Brandstein page 22 (2.13)
patternNoSquare = squeeze(sum(conj(W) .* signalVec));
pattern = abs(patternNoSquare).^2;

result.pattern = pattern;
result.patternNoSquare = patternNoSquare;

%!demo # compare with farfield method
%! options.frequNum = 10;
%! options.geometry = [-1 -0.5 0 0.5 1;zeros(2,5)];
%! options.frequency = linspace(100,1000,10);
%! options.beamforming.weights = ones(5,10)./5;
%! options.c = 340;
%! targets = [-90:90];
%! targets = targets/180*pi;
%! targetNum = numel(targets);
%! options.beamforming.beampattern.targets = 1e3*[sin(targets);zeros(1,targetNum);cos(targets)];
%! startTime = cputime;
%! for i=1:100
%! result = beampatternNearfield(options);
%! end
%! endTime = cputime;
%! subplot(3,1,1);
%! plot(targets/pi*180,result.pattern);
%! title(['nearfield with 1km distance, cpu time:' num2str((endTime-startTime)/100)]);
%! options.beamforming.beampattern.phi = 0;
%! theta = [-90:90];
%! options.beamforming.beampattern.teta = theta;
%! startTime = cputime;
%! for i=1:100
%! result = beampattern(options);
%! end
%! endTime = cputime;
%! subplot(3,1,2);
%! plot(theta,result.pattern);
%! title(['farfield approximation, cpu time:' num2str((endTime-startTime)/100)]);
%! options.beamforming.beampattern.targets = 2*[sin(targets);zeros(1,targetNum);cos(targets)];
%! result = beampatternNearfield(options);
%! subplot(3,1,3);
%! plot(targets/pi*180,result.pattern);
%! title('nearfield with 2m distance');

%!shared options,targetNum,freqNum
%! freqNum = 10;
%! options.frequNum = freqNum;
%! options.geometry = [-1 -0.5 0 0.5 1;zeros(2,5)];
%! options.frequency = linspace(100,1000,freqNum);
%! options.beamforming.weights = ones(5,freqNum)./5;
%! options.c = 340;
%! targets = [-90:90];
%! targets = targets/180*pi;
%! targetNum = numel(targets);
%! options.beamforming.beampattern.targets = 1e3*[sin(targets);zeros(1,targetNum);cos(targets)];

%!test # compare with farfield method
%! resultNear = beampatternNearfield(options);
%! options.beamforming.beampattern.phi = 0;
%! theta = [-90:90];
%! options.beamforming.beampattern.teta = theta;
%! result = beampattern(options);
%! assert(resultNear.pattern,squeeze(result.pattern),1e-4);

%!test # output size
%! result = beampatternNearfield(options);
%! assert(size(result.pattern),[freqNum,targetNum]);

%!test # symmetric array should give symmetric pattern (tests for error in Brandstein book)
%! targets = [-90:10:90];
%! targets = targets/180*pi;
%! targetNum = numel(targets);
%! options.beamforming.beampattern.targets = 2e0*[sin(targets);zeros(1,targetNum);cos(targets)];
%! result = beampatternNearfield(options);
%! pattern = result.pattern;
%! assert(pattern,pattern(:,end:-1:1),1e-12);
