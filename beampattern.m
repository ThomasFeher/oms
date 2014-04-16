function result = beampattern(options)
frequNum = options.frequNum;
geometry = options.geometry;
frequency = options.frequency;
W = options.beamforming.weights;
phi = options.beamforming.beampattern.phi;
theta = options.beamforming.beampattern.teta;
micNum = numel(geometry(1,:));

if(~isnumeric(phi))
	error('phi must be numeric');
end
if(~isvector(phi))
	if(~isscalar(phi))
		error('phi must be a vector or a scalar');
	end
end
if(~isnumeric(theta))
	error('theta must be numeric');
end
if(~isvector(theta))
	if(~isscalar(theta))
		error('theta must be a vector or a scalar');
	end
end
if(isfield(options.beamforming,'beampatternResolution'))
	warning(['deprecated configuration key'...
			'options.beamforming.beampatternResolution will be ignored']);
end

phi = phi/180*pi;
result.phi = phi/pi*180;
theta = theta/180*pi;
result.teta = theta/pi*180;
phiNum = numel(phi);
thetaNum = numel(theta);
%pattern = zeros(micNum,frequNum,phiNum,thetaNum);
c = options.c;
[thetaMesh phiMesh] = meshgrid(theta,phi);
% target positions, use nearfield equation with very distant points
targets = 1e10*[sin(thetaMesh(:)).*cos(phiMesh(:))...
               ,sin(thetaMesh(:)).*sin(phiMesh(:))...
               ,cos(thetaMesh(:))].';
% vector of incoming wave from wanted direction, size: [mic,freq,targets]
wVec = waveVec(geometry,frequency,targets,c);
patternNoSquare = squeeze(sum(conj(W) .* wVec)); % size: [freq,targets]
pattern = abs(patternNoSquare).^2; % size: [freq,targets]

result.pattern = pattern;
result.patternNoSquare = patternNoSquare;
result.patternOrig = patternNoSquare.';
result.patternSingle = patternNoSquare;

%for thetaCnt=1:thetaNum
	%x = (geometry(1,:).'*sin(theta(thetaCnt))*cos(phi)).';
	%y = (geometry(2,:).'*sin(phi)*sin(theta(thetaCnt))).';
	%z = geometry(3,:)*cos(theta(thetaCnt));
	%for phiCnt=1:phiNum
		%r = exp(i*2*pi*frequency'*(x(phiCnt,:)+y(phiCnt,:)+z)/c);
		%pattern(:,:,phiCnt,thetaCnt) = W(:,:).*r.';
	%end
%end
%patternSquare = shiftdim(abs(sum(pattern)).^2);
%result.pattern = patternSquare;
%result.patternOrig = shiftdim(sum(pattern));
%result.patternSingle = pattern;

%!test # output format
%! freqNum = 4
%! options.frequNum = freqNum;
%! options.geometry = [0 1715e-4;0 0;0 0];
%! options.frequency = linspace(10,1000,freqNum);
%! options.beamforming.weights = [1;1];
%! phiNum = 5;
%! thetaNum = 6;
%! options.beamforming.beampattern.phi = linspace(-90,90,phiNum);
%! options.beamforming.beampattern.teta = linspace(-90,90,thetaNum);
%! options.c = 343;
%! result = beampattern(options);
%! assert(size(result.pattern),[freqNum,thetaNum*phiNum]);

%test 2 mics 0.1715m distance -> 0.5ms delay (17e-2/340) -> makes phase shift
%of pi/10 (test here: http://www.sengpielaudio.com/Rechner-LaufzeitPhase.htm)
%-> both signals added gives half phase shift -> pi/10/2
%!test
%! options.frequNum = 1;
%! options.geometry = [0 1715e-4;0 0;0 0];
%! options.frequency = 100;
%! options.beamforming.weights = [1;1];
%! options.beamforming.beampattern.phi = 0;
%! options.beamforming.beampattern.teta = 90;
%! options.c = 343;
%! result = beampattern(options);
%! assert(angle(result.patternOrig),-pi/10/2,1e-5);

%!test # test with more frequencies
%! options.frequNum = 3;
%! options.geometry = [0 1715e-4;0 0;0 0];
%! options.frequency = [100 200 500];
%! options.beamforming.weights = ones(2,3);
%! options.beamforming.beampattern.phi = 0;
%! options.beamforming.beampattern.teta = 90;
%! options.c = 343;
%! result = beampattern(options);
%! assert(angle(result.patternOrig),-1*[pi/10/2;pi/10;pi/2/2],1e-5);

%!#test # test with more phi angles
%! options.frequNum = 3;
%! options.geometry = [0 1715e-4;0 0;0 0];
%! options.frequency = [100 200 500];
%! options.beamforming.weights = ones(2,3);
%! options.beamforming.beampattern.phi = [0 90];
%! options.beamforming.beampattern.teta = 90;
%! options.c = 343;
%! result = beampattern(options);
%! assert(angle(result.patternOrig),[pi/10/2 0;pi/10 0;pi/2/2 0],eps);

