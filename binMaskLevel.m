function result = binMaskLevel(options,sigVec)
sigNum= options.sigNum;
[maxChan maxInd] = max(sigVec,[],1);
%keyboard
maxChanMulti = zeros(size(sigVec));
for sigCnt=1:sigNum
	maxChanMulti(sigCnt,:,:) = maxChan;
end
maxInd = sigVec == maxChanMulti;
sigVecNew = zeros(size(sigVec));
sigVecNew(maxInd) = sigVec(maxInd);
result.sigVec = sigVecNew;
