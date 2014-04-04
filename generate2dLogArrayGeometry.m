%TODO parameters: smallest distance, arraySize; and remove branchLength
function geometry = generate2dLogArrayGeometry(branchNum,micNumMax,branchLength
                                              ,type,coeffA,coeffB,coeffC)
switch type
case 'straight'
	if(nargin<5)
		coeffA = 10;
	end
case 'brandstein'
	if(nargin<7)
		error('You have to provide 3 parameters for brandstein algorithm');
	end
	appertSize = coeffA;
	freqLo = coeffB;
	freqHi = coeffC;
case 'spiral'
	if(nargin<5)
		coeffA = 1;
	end
end
if nargin < 4
	disp 'usage: generate2dLogArrayGeometry(branchNum,micNumMax,branchLength,type)';
end

n = 1; % number of full circles to be covert by spiral arm 
speedOfSound = 340; % speed of sound in m/s

%generate rotation matrix
ang = 2*pi/branchNum;
rotMat = [cos(ang),-sin(ang);sin(ang),cos(ang)];

micsPerBranch = floor((micNumMax-1)/branchNum)+1;

%generate first branch
switch type
case 'straight'
	geometry = [(logspace(log10(1)...
	                     ,log10((1+branchLength)*coeffA)...
	                     ,micsPerBranch)-1) / coeffA
	           ;zeros(1,micsPerBranch)];
case 'brandstein'
	innerNum = floor(appertSize/2); % (1.18a) n ≤ Q/2
	if(innerNum>micsPerBranch-1)
		innerNum = micsPerBranch-1;
	end
	geometry = [0:innerNum] .* speedOfSound/(2*freqHi); % (1.18a)
	posMax = (appertSize-1)*speedOfSound/(2*freqLo); % (1.18b) p_n < (Q-1)c/2f_L
	for micCnt=innerNum+2:micsPerBranch % TODO vectorize % n > Q/2
		pos = appertSize/(appertSize-1)*geometry(end); % (1.18b)
		if(pos > posMax)
			break
		end
		geometry = [geometry pos];
	end
	geometry = [geometry;zeros(1,numel(geometry))];
case 'spiral'
	for micCnt=1:micsPerBranch
		geometry(1,micCnt) = coeffA*cos(angleFunc(micCnt,n,micsPerBranch))...
		                           *e^(coeffB*angleFunc(micCnt,n,micsPerBranch));
		geometry(2,micCnt) = coeffA*sin(angleFunc(micCnt,n,micsPerBranch))...
		                           *e^(coeffB*angleFunc(micCnt,n,micsPerBranch));
	end
	geometry([1,2],:) -= geometry([1,2],1);
otherwise
	error('unknown array type: %s',type);
end
branch = geometry(:,2:end);

for branchCnt=2:branchNum
	branch = rotMat*branch; % rotate branch
	geometry = [geometry,branch]; % add rotated branch to geometry
end

function ret = angleFunc(mic,n,micsPerBranch)
ret = (mic-1)*2*pi*n/micsPerBranch;
