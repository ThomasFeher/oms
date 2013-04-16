%cuts 'signal' into 'blockNum' overlapping blocks depending on 'timeShift' with
%a size of 'blockSize'plus two times 'zeroPads' (at beginning and end).
%returns the time domain blocks in 'blockMat' and the frequecy domain blocks in
%'sigVec'
function [sigVec blockMat blockNum blockTime] =...
		toFrequDomain(signal,blockSize,timeShift,zeroPads,fs)
blockNum = floor((size(signal,2)-blockSize)/timeShift);
sigNum = size(signal,1);
frequNum = floor((2*zeroPads+blockSize)/2+1);
sigVec= zeros(sigNum,blockNum,frequNum);
sigFFT = zeros(2*zeroPads+blockSize,blockNum*sigNum);
blockMat = zeros(sigNum,blockNum,blockSize);
blockIndex = zeros(1,blockNum);
windowLengthHalf = blockSize-timeShift+1;
%window = hann(windowLengthHalf*2+1)';%TODO use hanning, hann is Signal Processing Toolbox!
window = windowFctn(2*windowLengthHalf+1);
window = window(1:windowLengthHalf);
%window = window(2:windowLengthHalf);
for cnt=1:blockNum
	blockIndex(cnt) = (cnt-1)*timeShift +1; %starting index of the current block
	block = signal(:,blockIndex(cnt):blockIndex(cnt)+blockSize-1);
	blockMat(:,cnt,:) = block;
	block(:,1:windowLengthHalf-1) = block(:,1:windowLengthHalf-1) .* ...
		kron(ones(sigNum,1),window);
	block(:,end-windowLengthHalf+2:end) = block(:,end-windowLengthHalf+2:end)...
   		.* kron(ones(sigNum,1),window(end:-1:1));
	block = [zeros(sigNum,zeroPads) block zeros(sigNum,zeroPads)];
	%signals -> columns; frequencies -> rows
	sigFFT(:,((cnt-1)*sigNum)+1:cnt*sigNum) = fft(block');
end
%reorganize matrix [signal,block,frequency] (in case of rpm estimation there
%is always only one signal
for frequCnt=1:frequNum
	for sigCnt=1:sigNum
		sigVec(sigCnt,:,frequCnt) = sigFFT(frequCnt,sigCnt:sigNum:end);
	end
end	
%calculate blockTime (time stamp for each block)
blockTime = (blockIndex + blockSize/2)/fs;

function retval = windowFctn(sampleNum)
retval = 0.5 * (1-cos(2*pi*(1:sampleNum-1)'/sampleNum));
