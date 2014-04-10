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
pattern = zeros(micNum,frequNum,phiNum,thetaNum);
c = options.c;

for thetaCnt=1:thetaNum
	x = (geometry(1,:).'*sin(theta(thetaCnt))*cos(phi)).';
	y = (geometry(2,:).'*sin(phi)*sin(theta(thetaCnt))).';
	z = geometry(3,:)*cos(theta(thetaCnt));
	for phiCnt=1:phiNum
		r = exp(i*2*pi*frequency'*(x(phiCnt,:)+y(phiCnt,:)+z)/c);
		pattern(:,:,phiCnt,thetaCnt) = W(:,:).*r.';
	end
end
patternSquare = shiftdim(abs(sum(pattern)).^2);
result.pattern = patternSquare;
result.patternOrig = shiftdim(sum(pattern));
result.patternSingle = pattern;

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
%! assert(angle(result.patternOrig),pi/10/2,eps);

%test with more frequencies
%!test
%! options.frequNum = 3;
%! options.geometry = [0 1715e-4;0 0;0 0];
%! options.frequency = [100 200 500];
%! options.beamforming.weights = ones(2,3);
%! options.beamforming.beampattern.phi = 0;
%! options.beamforming.beampattern.teta = 90;
%! options.c = 343;
%! result = beampattern(options);
%! assert(angle(result.patternOrig),[pi/10/2;pi/10;pi/2/2],eps);

%test with more phi angles
%!test
%! options.frequNum = 3;
%! options.geometry = [0 1715e-4;0 0;0 0];
%! options.frequency = [100 200 500];
%! options.beamforming.weights = ones(2,3);
%! options.beamforming.beampattern.phi = [0 90];
%! options.beamforming.beampattern.teta = 90;
%! options.c = 343;
%! result = beampattern(options);
%! assert(angle(result.patternOrig),[pi/10/2 0;pi/10 0;pi/2/2 0],eps);

