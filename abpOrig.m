%calculates the averaged beampattern acording to Lombard et al.
%"Exploiting the self-steering capability of blind source separation to
%localize two or more sound sources in adverse environments" (2008)
function abp = abpOrig(geometry,W,frequency,options)
usage = 'usage: abpOrig(geomtry,W,frequency.[options])';
if(nargin<3)
	error(['Too few arguments\n' usage])
elseif(nargin>4)
	error(['Too many arguments\n' usage])
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
    %names = fieldnames(defaultOptions);
    %for k=1:length(names)
        %if ~isfield(options,names{k}) || isempty(options.(names{k}))
            %options.(names{k}) = defaultOptions.(names{k});
        %end
    %end
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
%skip pattern with maximum amplitude for each frequency bin and direction
patternSort = sort(patternUnsort);
patternSort = patternSort(1:end-1,:,:);
%use only frequencies in the specified frequency range
frequLowIndex = find(frequency<frequLow);
frequLowIndex = frequLowIndex(end);
frequHighIndex = find(frequency>frequHigh);
if(numel(frequHighIndex)<1)
	frequHighIndex = frequNum;
else
	frequHighIndex = frequHighIndex(1);
end
%averaging
abp = squeeze(sum(sum(patternSort(:,:,frequLowIndex:frequHighIndex),1),3));
%normalize
abp = abp - min(abp);
abp = abp / max(abp);
%figure(2); clf;
%patternUnsort = sum(patternUnsort,3);
%plot([patternUnsort;abp]');
%legend('1','2','3','4','sum');
