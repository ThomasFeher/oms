function result = beampattern(options)
disp('calculating beampattern ...');
frequNum = options.frequNum;
geometry = options.geometry;
frequency = options.frequency;
W = options.beamforming.weights;
phi = options.beamforming.beampattern.phi;
teta = options.beamforming.beampattern.teta;
micNum = numel(geometry(1,:));

if(~isnumeric(phi))
	error('phi must be numeric');
end
if(~isvector(phi))
	if(~isscalar(phi))
		error('phi must be a vector or a scalar');
	end
end
if(~isnumeric(teta))
	error('teta must be numeric');
end
if(~isvector(teta))
	if(~isscalar(teta))
		error('teta must be a vector or a scalar');
	end
end
if(isfield(options.beamforming,'beampatternResolution'))
	warning(['deprecated configuration key'...
			'options.beamforming.beampatternResolution will be ignored']);
end

%phi = [-90:beampatternResolution:90]/180*pi;
phi = phi/180*pi;
result.phi = phi/pi*180;
%teta = [-90:beampatternResolution:90]/180*pi;
teta = teta/180*pi;
result.teta = teta/pi*180;
phiLength = numel(phi);
tetaLength = numel(teta);
pattern = zeros(frequNum,phiLength,tetaLength);
%d = ones(numel(geometry(1,:)),1);
c = options.c;
%rMax = sqrt(max(abs(geometry(1,:))).^2 ...
	%+max(abs(geometry(2,:))).^2 ...
	%+max(abs(geometry(3,:))).^2);
xMin = min(geometry(1,:));
yMin = min(geometry(2,:));
zMin = min(geometry(3,:));
%if xMin<0
	%geometry(1,:) = geometry(1,:) - xMin;
%end
%if yMin<0
	%geometry(2,:) = geometry(2,:) - yMin;
%end
%if zMin<0
	%geometry(3,:) = geometry(3,:) - zMin;
%end

for tetaCnt=0:tetaLength-1
	for phiCnt=0:phiLength-1
		x = geometry(1,:)*sin(teta(tetaCnt+1))*cos(phi(phiCnt+1));
		xMod = x - min(x);
		y = geometry(2,:)*sin(phi(phiCnt+1))*sin(teta(tetaCnt+1));
		yMod = y - min(y);
		z = geometry(3,:)*cos(teta(tetaCnt+1));
		zMod = z - min(z);
		r = exp(i*2*pi*frequency'*(x+y+z)/c);
		pattern(:,phiCnt+1,tetaCnt+1) = abs(diag(W(:,:).'*r.')).^2;
	end
end
result.pattern = pattern;
