function result = binMaskCorrBlock(options,sigVec)
corrThreshold = options.sortCorrBlock.corrThreshold;
sigNumOrig = options.sigNum;
sigNum = sigNumOrig;
sigVecSort = zeros(size(sigVec));
frequNum = options.frequNum;
%blockSize should correspond to about 0.3 seconds in time domain
blockSizeInSeconds = options.sortCorrBlock.blockSize;
blockSize = floor(blockSizeInSeconds*options.fs/options.timeShift);
timeShift = floor(blockSize/2);
blockNum = floor((size(sigVec,2)-blockSize)/timeShift);
disp(blockSize);

for blockCnt=1:blockNum
	sigNum = sigNumOrig;
	blockIndex = (blockCnt-1)*timeShift+1;
	sigVecBlock = sigVec(:,blockIndex:blockIndex+blockSize-1,:);
	sigVecAbsBlock = abs(sigVecBlock);
	sigVecSortBlock = zeros(size(sigVecBlock));
	sigVecAbsSortBlock = zeros(size(sigVecBlock));
	sigVecSortBlock(:,:,1) = sigVecBlock(:,:,1);%first frequency
	sigVecAbsSortBlock(:,:,1) = sigVecAbsBlock(:,:,1);%first frequency

	%find loudest signal)
	energies = squeeze(sum(sigVecAbsBlock(:,:,:),2));
	[maxSig maxFrequ] = find(energies==max(energies(:)));
	cntArray = [2:frequNum];
	cntArray = circshift(cntArray,[0 1-maxFrequ]);

	%start at loudest frequency
	for frequCnt=cntArray
		sigAddCnt = 0;
		%corrlation matrix (only off axis elements)
		for sigCnt1=1:sigNum
			for sigCnt2=sigCnt1+1:sigNumOrig
				corrCoeff(sigCnt1,sigCnt2) = abs(corrcoeff(sigVecAbsBlock(sigCnt1,:,frequCnt),sigVecAbsBlock(sigCnt2,:,frequCnt)));
				if(corrCoeff(sigCnt1,sigCnt2)>corrThreshold)
					sigVecSortBlock(sigCnt1,:,frequCnt) = 0;
					sigVecSortBlock(sigCnt2,:,frequCnt) = 0;
				else
					sigVecSortBlock(sigCnt1,:,frequCnt) =...
							sigVecBlock(sigCnt1,:,frequCnt);
					sigVecSortBlock(sigCnt2,:,frequCnt) =...
							sigVecBlock(sigCnt2,:,frequCnt);
				end
			end
		end
		disp(corrCoeff);

		%figure(1);
		%for sigCnt=1:sigNum
			%subplot(sigNum+sigAddCnt,2,sigCnt*2-1);
			%plot(sum(sigVecAbsSortBlock(sigCnt1,:,1:frequCnt-1),3));
		%end
		%for sigCnt=1:sigNum+sigAddCnt
			%subplot(sigNum+sigAddCnt,2,sigCnt*2);
			%plot(sigVecAbsBlock(sigCnt,:,frequCnt));
		%end
		%for sigCnt=1:sigNum
			%spectrogram = transp(abs(squeeze(sigVecAbsSortBlock(sigCnt,:,1:frequCnt))));
			%spectrogram = spectrogram(end:-1:1,:);
			%figure();
			%imagesc(spectrogram);
		%end
		%keyboard
		sigNum = sigNum + sigAddCnt;
	end
	sigNumBefore = size(sigVecSort,1);
	sigNumAfter = size(sigVecSortBlock,1);
	sigDiff = sigNumAfter - sigNumBefore;
	if(sigDiff>0)%more signals than before
		sigVecSort = addSignal(sigVecSort,sigDiff);
	elseif(sigDiff<0)%less signals than before
		sigVecSortBlock = addSignal(sigVecSortBlock,-sigDiff);
	end
	%sort signals so they fit best to signals of previous blocks
	startOverlap = floor(blockIndex+blockSize/2);
	endOverlap = blockSize - timeShift;
	blockSortVec = sortBlocks(sigVecSort(:,...
			startOverlap:blockIndex+blockSize-1,:),...
			sigVecSortBlock(:,1:endOverlap,:));
			%disp(blockSortVec);
	%add block to whole signal
	sigVecSort(:,blockIndex:blockIndex+blockSize-1,:) =...
			sigVecSort(blockSortVec,blockIndex:blockIndex+blockSize-1,:) +...
			sigVecSortBlock;
			%for sigCnt=1:sigNum
				%spectrogram = transp(abs(squeeze(sigVecSortBlock(sigCnt,:,:))));
				%spectrogram = spectrogram(end:-1:1,:);
				%figure();
				%imagesc(spectrogram);
			%end
			%keyboard
			%for sigCnt=1:sigNum
				%spectrogram = transp(abs(squeeze(sigVecBlock(sigCnt,:,:))));
				%spectrogram = spectrogram(end:-1:1,:);
				%figure();
				%imagesc(spectrogram);
			%end
end
result.sigVec = sigVecSort;

function sigVecNew = addSignal(sigVec,addNum)
if(nargin<2)
	addNum = 1;
end
sigNum = size(sigVec,1);
blockSize = size(sigVec,2);
frequNum = size(sigVec,3);
sigVecNew = zeros(sigNum+addNum,blockSize,frequNum);
sigVecNew(1:sigNum,:,:) = sigVec;

function sortVec = sortBlocks(block1,block2)
sigNum = size(block1,1);
corrCoeff = zeros(sigNum,sigNum);
for frequCnt=1:size(block1,3)
	for sigCnt1=1:sigNum
		for sigCnt2=1:sigNum
			corrCoeff(sigCnt1,sigCnt2) = corrCoeff(sigCnt1,sigCnt2) +...
					abs(corrcoeff(block1(sigCnt1,:,frequCnt),...
							block2(sigCnt2,:,frequCnt)));
		end
	end
end
for sigCnt=1:sigNum
	[best row column] = matMax(corrCoeff);
	sortVec(row) = column;
	corrCoeff(row,:) = -inf;
	corrCoeff(:,column) = -inf;
end

function [best row column] = matMax(mat)
best = max(mat(:));
best = best(1); %just in case more than one max was found
[row column] = find(mat==best);
row = row(1);
column = column(1);
