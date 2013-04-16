function signalICA = toTimeDomain(sigVec,sigNum,blockSize,timeShift,...
	zeroPads,blockNum);
disp('Reconstructing Signals...');
blockSizeZeroPads = 2*zeroPads + blockSize;
sigVecAll = zeros(sigNum,blockNum,blockSizeZeroPads);
sigVecAll(:,:,1:blockSizeZeroPads/2+1) = sigVec;
for frequCnt = 2:blockSizeZeroPads/2
	sigVecAll(:,:,blockSizeZeroPads-frequCnt+2) = ...
			conj(sigVec(:,:,frequCnt));
end
signalICA = zeros(sigNum,(blockNum-1)*timeShift+blockSizeZeroPads);
for cnt=1:blockNum
	blockIndex = (cnt-1)*timeShift +1;
	sigVecBlock = (squeeze(sigVecAll(:,cnt,:))).';
	signalICA(:,blockIndex:blockIndex+blockSizeZeroPads-1) = signalICA(:,...
		blockIndex:blockIndex+blockSizeZeroPads-1) + ...
		ifft(sigVecBlock)';
end
