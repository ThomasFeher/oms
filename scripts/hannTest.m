signal = rand(1,10000)*2-1;
blockSize = 100;
timeShift = [1:10:101];
result = zeros(1,11000);
for expCnt=1:10
	for cnt=1:100
		
		blockIndex = (cnt-1)*timeShift +1;
		block = signal(:,blockIndex:blockIndex+blockSize-1);
		result(expCnt,blockIndex:blockIndex+blockSize) = block;
	end
	y = floor(expCnt/5);
	x = expCnt-(y-1)*5;
	subplot(x,y,10);
	plot(result(expCnt));
	keyboard
end
