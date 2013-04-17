function [W,WICA,z,cnt,Wdiff] = FastICAHyv (x,maxIteration,Wold)
	sigNum = size(x,1); % number of ICs to estimate
	[z,V]=whitening(x);
	C = cov(z');
	cnt = 0;
	WICA = randn(sigNum,sigNum) + i*randn(sigNum,sigNum);
	while cnt < maxIteration;
		for j = 1:sigNum
			gWx(j,:) = 1./(eps + abs(WICA(:,j)'*z).^2);
			dgWx(j,:) = -1./(eps + abs(WICA(:,j)'*z).^2).^2;
			WICA(:,j) = mean(z .* (ones(sigNum,1)*conj(WICA(:,j)'*z)) .* (ones(sigNum,1)*gWx(j,:)),2) - mean(gWx(j,:) + abs(WICA(:,j)'*z).^2 .* dgWx(j,:)) * WICA(:,j);
		end;
		% Symmetric decorrelation:
		%WICA = WICA * sqrtm(inv(WICA'*WICA));
		[E,D] = eig(WICA'*C*WICA);
		WICA = WICA * E * inv(sqrt(D)) * E';
		cnt = cnt + 1;
		GWx = log(eps + abs(WICA'*z).^2);
		EG(:,cnt) = mean(GWx,2);
		permMat = perms(1:sigNum);
		permNum = size(permMat,1);
		for permCnt=1:permNum
			WTemp(permCnt) = abs(sum(abs(diag(WICA(permMat(permCnt,:),:)'*Wold)))-sigNum);
		end
		WSort = sort(WTemp);
		Wdiff(cnt) = WSort(1);
		%%{
		for j = 1:sigNum-1
			figure(3), subplot(floor(sigNum/2),2,j), plot(EG(j,:));
			% Shows the convergence of G to a minimum or a maximum
		end;
		subplot(floor(sigNum/2),2,1), title('Convergence of G');
		%}
	end
	W = WICA' * V;
end
