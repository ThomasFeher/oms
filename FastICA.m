function [W,WICA,z,p,Wdiff] = FastICA (x,maxIteration,Wold)

	%center and whiten
	[z,V]=whitening(x);

	%FastICA

	sigNum=size(x,1); % number of ICs to estimate
	if(nargin>2)
		%WICA = transp(Wold);
		WICA=(Wold/V).';
		if(any(any(isnan(WICA))))
			WICA = eye(sigNum);
		end
	else
		WICA=eye(sigNum);
	end

	Wdiff=[0 zeros(1,maxIteration-1)]; %initialise Wdiff
	a=1; %initialise a
	p=0; %count loops until convergence
	while p<maxIteration	
		p=p+1;
		Wold=WICA;
		for i=1:sigNum
			wh = mean(z.*kron(ones(sigNum,1),tanh(WICA(:,i)'*z)),2)-...
					mean(1-(tanh(WICA(:,i)'*z)).^2,2)*WICA(:,i);
			WICA(:,i) = wh;
		end
		if(any(any(isnan(WICA))))
			WICA = eye(sigNum);
		end
		%disp(Wold);
		%disp(WICA);
		WICA=(inv(sqrtm(WICA*WICA')))*WICA;  %orthogonalization
		%Wdiff(p) = max(max(abs(WICA)-abs(Wold)));
		permMat = perms(1:sigNum);
		permNum = size(permMat,1);
		for permCnt=1:permNum
			%GTemp(permCnt) = abs(sum(abs(G(permMat(permCnt,:)))-abs(GOld)));
			%WTemp(permCnt) = abs(norm((WICA(permMat(permCnt,:),:))-(Wold)))-...
					sigNum;
			WTemp(permCnt) = abs(sum(abs(diag(WICA(permMat(permCnt,:),:)'*...
					Wold)))-sigNum);
		end
		%GSort = sort(GTemp);
		WSort = sort(WTemp);
		%Gdiff(p) = GSort(1);
		Wdiff(p) = WSort(1);
		if(Wdiff(p)<0.00001)
			break
		end
	end
	W = (WICA.') * V;
end

