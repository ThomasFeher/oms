function sigVecICAsort = applyICA(WAllSort,sigVec,blockSizeZeroPads,blockNum);
sigNum = size(sigVec,1);
sigVecICAsort = zeros(size(sigVec));
sigFFTICA = zeros(blockSizeZeroPads,blockNum*sigNum);
disp('applying ICA...');
for frequCnt=1:blockSizeZeroPads/2+1
	for sigCnt=1:sigNum
		sigVecICATemp = WAllSort(sigCnt,:,frequCnt) *...
				squeeze(sigVec(:,:,frequCnt));
		sigVecICAsort(sigCnt,:,frequCnt) = sigVecICATemp;
		%sigFFTICA(frequCnt,sigCnt:sigNum:end) =...
				%sigVecICAsort(sigCnt,:,frequCnt);
	end
	%if(~((frequCnt==1)|(frequCnt==blockSizeZeroPads/2+1)))
		%WAllSort(:,:,blockSizeZeroPads-frequCnt+2) =...
				%conj(WAllSort(:,:,frequCnt));
		%for sigCnt=1:sigNum
			%sigVecICAsort(sigCnt,:,blockSizeZeroPads-frequCnt+2) =...
					%conj(sigVecICAsort(sigCnt,:,frequCnt));
			%%sigFFTICA(blockSizeZeroPads-frequCnt+2,sigCnt:sigNum:end) =...
					%%conj(sigVecICAsort(sigCnt,:,frequCnt));
		%end
	end
end
