%calculates my own averaged beampattern
function results = abpFeher(geometry,W,frequency,options)
usage = 'usage: abpFeher(geomtry,W,frequency.[options])';
if(nargin<3)
	error(['Too few arguments\n' usage]);
elseif(nargin>4)
	error(['Too many arguments\n' usage]);
end
if(size(geometry,1)>3)
	error('geometry coordinates have more than 3 dimensions');
end
if(~isvector(frequency))
	error('frequency must be a vector');
end
if(size(W,1)~=size(W,2))
	error('first 2 dimensions of W must be of equal size');
end
if(size(geometry,2)~=size(W,1))
	error('geometry and W do not fit');
end
if(size(W,3)~=numel(frequency))
	error('W and frequency do not fit');
end

%lower frequency bound for source position and source number estimation
defaultOptions.frequLow = 1;
%upper frequency bound for source position and source number estimation
defaultOptions.frequHigh = inf;
defaultOptions.c = 340; %speed of sound in m/s
if(nargin<4)
	options = defaultOptions;
else
	options = default2options(defaultOptions,options);
end

sigNum = size(geometry,2);
frequNum = numel(frequency);
frequLow =  options.frequLow;
if(frequLow<1) frequLow = 1; end
frequHigh =  options.frequHigh;
c = options.c;

phiSort = [-90:1:90]/180*pi;
phiSortLength = numel(phiSort);
patternUnsort = zeros(sigNum,phiSortLength,frequNum);
%calculate beampattern
for phiSortCnt=0:phiSortLength-1
	r = exp(i*2*pi*frequency'*geometry*sin(phiSort(phiSortCnt+1))/c);
	for sigCnt=1:sigNum
		patternUnsort(sigCnt,phiSortCnt+1,:) =...
			abs(diag(squeeze(W(sigCnt,:,:))'*r')).^2;
	end
end
%normalize beampattern
for frequCnt=1:frequNum
	for sigCnt=1:sigNum
		patternUnsort(sigCnt,:,frequCnt) = patternUnsort(sigCnt,:,frequCnt)-...
			min(abs(patternUnsort(sigCnt,:,frequCnt)));
		patternMax = max(abs(patternUnsort(sigCnt,:,frequCnt)));
		if(patternMax~=0)
			patternUnsort(sigCnt,:,frequCnt) =...
					patternUnsort(sigCnt,:,frequCnt) / patternMax;
		end
	end
end
frequLowIndex = find(frequency<frequLow);
frequLowIndex = frequLowIndex(end);
frequHighIndex = find(frequency>frequHigh);
if(numel(frequHighIndex)<1)
	frequHighIndex = frequNum;
else
	frequHighIndex = frequHighIndex(1);
end
%averaging
results.abpPattern = patternUnsort;
results.abpTwoDim = squeeze(sum(patternUnsort,1));
abp = squeeze(sum(sum(patternUnsort(:,:,frequLowIndex:frequHighIndex),1),3));
%normalize
abp = abp - min(abp);
results.abp = abp / max(abp);
