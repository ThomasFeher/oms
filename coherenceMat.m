%calculate coherence matrix of determined noise fields
%@ param angle1 angle of noise in degree
%@ param angle2 angle of noise in degree
function retval = coherenceMat(geometryX, geometryY, frequency, angle1, angle2, mu)
usage = [['Usage: C = coherenceMat(geometryX, geometryY, frequency,']...
		['angle1[, angle2, mu])']];
if(nargin~=4&nargin~=5&nargin~=6)
	error(sprintf('Invalid call to coherenceMat. %s',usage));
end
if(nargin<6)
	mu = -inf;%set to spherically isotropic noise field
end
if(nargin<5)
	angle2 = 0;
end
micNum = length(geometryX);
if(micNum<2)
	error('Length of geometryX must be at least 2.')
end
if(numel(geometryX)~=numel(geometryY))
	error('Length of geometryX and geometryY must be equal!');
end

%%%%%init%%%%%
c = 340;
sigma = 10^(mu/10);
%initialize coherence matrix (main diagonale values stay 1)
retval = ones(micNum, micNum); 
%%%%%init%%%%%

if(strcmp(angle1,'diffuse'))
	for j = 1:micNum-1
		for k = (j+1):micNum
			retval(j,k) = sinc(2 * frequency * sqrt((geometryX(j) -...
				geometryX(k))^2+(geometryY(j)-geometryY(k))^2) / c)/(1+sigma);
			retval(k,j) = retval(j,k);
		end
	end
else
	angle1 = angle1/180*pi;
	angle2 = angle2/180*pi;
	for j = 1:micNum-1
		for k = (j+1):micNum
			if(angle2==0)
				%realPart = cos((2 * pi * frequency * cos(angle1) * sqrt((geometryX(j) - geometryX(k))^2+(geometryY(j)-geometryY(k))^2))/c);
				%imagPart = -sin((2 * pi * frequency * cos(angle1) * sqrt((geometryX(j) - geometryX(k))^2+(geometryY(j)-geometryY(k))^2))/c);
				%retval(j,k) = realPart + imagPart * i;
				%retval(k,j) = retval(j,k);
				retval(j,k) = exp(i*2*pi*frequency*abs(geometryX(j)-...
						geometryX(k))*sin(angle1)/c)/(1+sigma);
				%retval(k,j) = (retval(j,k));
				retval(k,j) = conj(retval(j,k));
			else
				%retval(j,k) = exp(i*2*pi*frequency*(abs(geometryX(j)-geometryX(k))*sin(angle1)*cos(angle2) + abs(geometryY(j)-geometryY(k))*sin(angle1)*sin(angle2)));
				%retval(k,j) = conj(retval(j,k));
				retval(j,k) = exp(i*2*pi*frequency*((geometryX(j)-...
						geometryX(k))*sin(angle1)*cos(angle2) +...
						(geometryY(j)-geometryY(k))*sin(angle1)*sin(angle2))/c);
				retval(k,j) = exp(i*2*pi*frequency*((geometryX(k)-...
						geometryX(j))*sin(angle1)*cos(angle2) +...
						(geometryY(k)-geometryY(j))*sin(angle1)*sin(angle2))/c);
			end
		end
	end
end
