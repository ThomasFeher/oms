%TODO parameters: smallest distance, arraySize; and remove branchLength
function geometry = generate2dLogArrayGeometry(branchNum,micNumMax,branchLength
                                              ,type,coeffA,coeffB)
if(nargin<6)
	coeffB = 1;
end
if(nargin<5)
	switch type
case 'straight'
	coeffA = 10;
case 'spiral'
	coeffA = 1;
end
end
if nargin < 4
	disp 'usage: generate2dLogArrayGeometry(branchNum,micNumMax,branchLength,type)';
end

n = 1; % number of full circles to be covert by spiral arm 

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
case 'spiral'
	for micCnt=1:micsPerBranch
		geometry(1,micCnt) = coeffA*cos(angleFunc(micCnt,n,micsPerBranch))...
		                           *e^(coeffB*angleFunc(micCnt,n,micsPerBranch));
		geometry(2,micCnt) = coeffA*sin(angleFunc(micCnt,n,micsPerBranch))...
		                           *e^(coeffB*angleFunc(micCnt,n,micsPerBranch));
	end
	geometry(1,:) -= 1;
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
