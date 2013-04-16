function sigMixed = mixArtif(signal,irMat);
	irLength = size(irMat,2)/2;
	sigNum = size(signal,1);
	sigLength = size(signal,2);
	if(sigNum~=size(irMat,1))
		error('number of signals does not match size of impulse response matrix');
	end

	for sigCnt1=1:sigNum
		sigTemp = zeros(1,sigLength+irLength-1);
		for sigCnt2=1:sigNum
			irPos = (sigCnt2-1)*irLength+1;
			sigTemp = sigTemp + conv(signal(sigCnt2,:),irMat(sigCnt1,irPos:irPos+irLength-1));
		end
		sigMixed(sigCnt1,:) = sigTemp;
	end
end
