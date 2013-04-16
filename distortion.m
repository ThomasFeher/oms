%calculates distortion as described in 'Optimierung frequencvarianter
%Nullbeamformer für akustische Signale mittels Statistik höherer Ordnung -
%Anwendung im KFZ und in Büroräumen'
ü
%D = distortion(O, P, B)
%O and P are the original and the processed signals in time domain, respectively. B is the blocksize (Default = 128). 
function Dist = distortion(O,P,B)
	if(nargin<3)
		B = 128;
	end
	if(nargin<2|nargin>3)
		error('usage: D = distortion(O,P[,B])');
	end
	if((~isvector(O))|(~isvector(P)))
		error('first two arguments must be vectors');
	end
	if(length(O)<=B|length(P)<=B)
		error('signals must be longer than block length');
	end
	if(size(O,2)==1)
		O = O.';
	end
	if(size(P,2)==1)
		P = P.';
	end

	%init
	if(length(O)<length(P))
		sigLength = length(O);
	else
		sigLength = length(P);
	end
	blockNum = floor(sigLength / B);
	OFFT = zeros(B,blockNum);
	PFFT = zeros(size(OFFT));
	timeShift = ceil(B/2);

	% normalize to standard deviation
	ONorm = O/norm(O);
	PNorm = P/norm(P);

	% short time fft
	for blockCnt=1:blockNum
		blockIndex = (blockCnt-1)*timeShift +1;
		block = ONorm(:,blockIndex:blockIndex+B-1);
		block = block .* hann(B,'periodic')';
		OFFT(:,blockCnt) = abs(fft(block)).^2;
		block = PNorm(:,blockIndex:blockIndex+B-1);
		block = block .* hann(B,'periodic')';
		PFFT(:,blockCnt) = abs(fft(block)).^2;
	end

	% compare averaged spectra
	Dist = mean(10*log10(mean(PFFT,2)./mean(OFFT,2)));
end
