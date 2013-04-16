function [W,WICA,z,p,Wdiff,Gdiff,negent] = FastICA (x,maxIteration,Wold,...
	sourceNum)
	%center and whiten
	[z,V,eigVal]=whitening(x);
	%disp('z*zH');
	%disp((z*conj(z'))./size(z,2));
	%disp(z(:,1:10));
	%disp(conj(z(:,1:10)));
	%FastICA

	sigNum = size(x,1); % number of ICs to estimate
	if(nargin<4)
		sourceNum = sigNum;
	else
		[noi eigValSortIndex] = sort(diag(eigVal));
		z = z(eigValSortIndex(1:sourceNum),:);
		V = V(eigValSortIndex(1:sourceNum),:);
	end
	if(nargin<3)
		WICA=eye(sourceNum);
	else
		WICA=Wold;
	end
	Gdiff=[0 zeros(1,maxIteration-1)]; %initialise Gdiff
	Wdiff=[0 zeros(1,maxIteration-1)]; %initialise Wdiff
	negent = zeros(1,maxIteration);
	G = mean(log(0.1+abs(WICA'*z).^2),2);
	p=0; %count loops until convergence
	while p<maxIteration
		p=p+1;
		Wold=WICA;
		GOld = G;
		for i=1:sourceNum
			%wh=mean(z.*kron(ones(2,1),tanh(WICA(:,i)'*z)),2)-...
				%mean(1-(tanh(WICA(:,i)'*z)).^2,2)*WICA(:,i);
			f = WICA(:,i)'*z; %w'z
			%fS = f.*conj(f); %abs(f)^2
			fS = abs(f).^2; %abs(f)^2
			g = 1./(0.1 + fS); %g(fS)
			g_ = -1./((0.1 + fS).^2); %g'(fS)
			%disp(size(f));disp(size(fS));disp(size(g));disp(size(g_));
			wh=mean(z.*conj(kron(ones(sourceNum,1),f)).*...
				kron(ones(sourceNum,1),g),2)-mean(g+(fS.*g_),2)*WICA(:,i);
			WICA(:,i)=wh;%./norm(wh);
		end
		try
			WICA=(inv(sqrtm(WICA*WICA')))*WICA;  %orthogonalization
		catch err
			WICA = eye(sourceNum);
			disp('ICA aborted, unable to orthogonalize demixing matrix');
			break
		end
		%WICA = WICA * sqrtm(inv(WICA'*WICA));
		G = mean(log(0.1+abs(WICA'*z).^2),2);
		%disp(G);
		%keyboard
		negent(1,p) = mean(G);
		%G = log(0.1 + abs(WICA'*x).^2);
		%disp('G');
		%disp(G);
		permMat = perms(1:sourceNum);
		permNum = size(permMat,1);
		for permCnt=1:permNum
			GTemp(permCnt) = abs(sum(abs(G(permMat(permCnt,:)))-abs(GOld)));
			WTemp(permCnt) = abs(norm((WICA(permMat(permCnt,:),:))-...
				(Wold)));%-sourceNum;
			%WTemp(permCnt) = abs(sum(abs(diag(WICA(permMat(permCnt,:),:)'...
				%*Wold)))-sourceNum);
		end
		GSort = sort(GTemp);
		WSort = sort(WTemp);
		Gdiff(p) = GSort(1);
		Wdiff(p) = WSort(1);
		%Gdiff(p) = abs(sum(abs(G)-abs(GOld)));
		%Gdiff= max(max(abs(WICA)-abs(Wold)));

		%disp('Wold');
		%disp(abs(Wold));
		%disp('WICA');
		%disp(abs(WICA));
		%disp('Gdiff');
		%disp(Gdiff(p));
		%disp('Wdiff');
		%disp(Wdiff(p));
		%keyboard
		%%{
		if(Gdiff(p)<=0.00005)
			negent(1,p+1:end) = negent(1,p);
			Gdiff(1,p+1:end) = Gdiff(1,p);
			Wdiff(1,p+1:end) = Wdiff(1,p);
			break
		end
		%}
	end
	%figure(1);
	%plot(Gdiff);
	%keyboard
	%drawnow;
	W = WICA' * V;
	%{
	figure(1);
	subplot(2,1,1);
	plot(Gdiff);
	hold all;
	subplot(2,1,2);
	plot(Wdiff);
	hold all;
	drawnow;
	%}
end
