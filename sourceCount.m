%calculates the number of sources found by ICA
%usage: [sourceNum sourcePosAngle] = sourceCount(geometry,W,frequency,c,[options])
% sourceNum is the number of found sources
% sourcePosAngle is a vector containing the according angles in radian (0 is direction with no delays)
% geometry is a row vector containing the microphone positions (only 1-D arrays possible!)
% W contains the weights (size: chanels x chanels x frequencies)
% frequency is the vector of center frequencies of all frequency bins in Hz
% c is the speed of sound in m/s
function [sourceNum sourcePosAngle] = sourceCount(W,frequency,geometry,options)
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
geometry = geometry(1,:);
frequLow = options.frequLow;
if(frequLow<1) frequLow = 1; end
frequHigh = options.frequHigh;
c = options.c;

sourceNum = 0;
sourcePosAngle = 0;
sigNum = size(W,1);
frequNum = numel(frequency);
phiSort = [-90:1:90]/180*pi;
phiSortLength = numel(phiSort);
for phiSortCnt=0:phiSortLength-1
	r = exp(i*2*pi*frequency'*geometry*sin(phiSort(phiSortCnt+1))/c);
	for sigCnt=1:sigNum
		pattern(sigCnt,phiSortCnt+1,:) =...
				abs(diag(squeeze(W(sigCnt,:,:))'*r')).^2;
	end
end
%subplot(2,1,1);
%plot(squeeze(sum(sum(pattern),3)));
%title('not normalized');
%for frequCnt=1:frequNum
	%for sigCnt=1:sigNum
		%pattern(sigCnt,:,frequCnt) = pattern(sigCnt,:,frequCnt)/...
				%max(abs(pattern(sigCnt,:,frequCnt)));
	%end
%end
%subplot(2,1,2);
%plot(squeeze(sum(sum(pattern),3)));
%title('normalized');

frequLowIndex = find(frequency<frequLow);
frequLowIndex = frequLowIndex(end);
frequHighIndex = find(frequency>frequHigh);
if(numel(frequHighIndex)<1)
	frequHighIndex = frequNum;
else
	frequHighIndex = frequHighIndex(1);
end
patternSum = squeeze(sum(sum(pattern(:,:,frequLowIndex:frequHighIndex)),3));
patternSum = patternSum - (min(patternSum)-0.01);
patternSum = patternSum / max(patternSum);
%figure(3); clf;
%subplot(5,1,1);
%plot(patternSum);
[noi noi patternSumExtrema] = extrema(patternSum);%get extrema
%subplot(5,1,2);
%plot(patternSumExtrema);
patternSumMinima = zeros(1,phiSortLength);%create minima vector
patternSumMinima(find(patternSumExtrema==-1)) = 1;%get minima
sourcePos = find(patternSumMinima);
%subplot(5,1,3);
%plot(patternSumMinima);
patternSumMinimaWeighted = patternSumMinima .* patternSum;%get size of minima
%subplot(5,1,4);
%plot(patternSumMinimaWeighted);
%clustering
%disp(sourcePos);
if(numel(sourcePos)<1)
	%disp('no source found');
	[noi sourcePos] = min(patternSum);
elseif(numel(sourcePos)>1)
	[sourceCluster clusterValue] = kmeans(patternSumMinimaWeighted(sourcePos),...
			2,'Start',[1 0]','EmptyAction','drop');
	[noi rightCluster] = min(clusterValue);
	sourcePos = sourcePos(find(sourceCluster==rightCluster));
end
%subplot(5,1,5);
%plot(patternSumMinima);
sourceNum = numel(sourcePos);
if(sourceNum>sigNum)
	sourceDifference = sourceNum - sigNum;
	[noi sortIndex] = sort(patternSumMinimaWeighted(find(...
			patternSumMinimaWeighted)),'descend');
	sourcePos(sortIndex(1:sourceDifference)) = [];
	sourceNum = numel(sourcePos);
end
sourcePosAngle = phiSort(sourcePos);
