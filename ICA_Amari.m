function [W,WICA,z,p,Gdiff] = ICA_Amari(x,maxIteration,Wold,frequCnt)
	%center and whiten
	[z,V]=whitening(x);
	%disp('z*zH');
	%disp((z*conj(z'))./size(z,2));
	%disp(z(:,1:10));
	%disp(conj(z(:,1:10)));
	%FastICA

	sigNum = size(x,1); % number of ICs to estimate
	blockNum = size(x,2);
	if(nargin>2)
		WICA=Wold;
	else
		WICA=eye(sigNum);
	end
	gain = 100;
	eta=0.0001;
	I = eye(sigNum);
	Gdiff=[0 zeros(1,maxIteration-1)]; %initialise Gdiff
	Wdiff=[0 zeros(1,maxIteration-1)]; %initialise Wdiff
	%G = mean(log(0.1+z),2);
	G = sum(2*tanh(gain*real(z))+2i*tanh(gain*imag(z)),2);
	p=0; %count loops until convergence
	while p<maxIteration
		p=p+1;
		Wold=WICA;
		GOld = G;
		%{
		for i=1:sigNum
			%wh=mean(z.*kron(ones(2,1),tanh(WICA(:,i)'*z)),2)-mean(1-(tanh(WICA(:,i)'*z)).^2,2)*WICA(:,i);
			f = conj(WICA(:,i)')*z; %w'z
			fS = f.*conj(f); %abs(f)^2
			g = 1./(0.1 + fS); %g(fS)
			g_ = -1./((0.1 + fS).^2); %g'(fS)
			%disp(size(f));disp(size(fS));disp(size(g));disp(size(g_));
			wh=mean(z.*kron(ones(2,1),f).*kron(ones(2,1),g),2)-mean(g+fS.*g_,2)*WICA(:,i);
			WICA(:,i)=wh;%./norm(wh);
		end
		%}
		f = Wold * z;
		phi = 2*tanh(gain*real(f))+2i*tanh(gain*imag(f));
		WICA = Wold + eta*(I-(phi*conj(f'))/(blockNum^2))*Wold;
		%%{
		%}
		WICA = WICA / (norm(WICA)^sigNum);
		%disp(sprintf('Norm WICA: %e',norm(WICA)));
		WICA=(inv(sqrtm(WICA*conj(WICA'))))*WICA;  %orthogonalization
		%G = mean(log(0.1+conj(WICA')*z),2);
		G = sum(2*tanh(gain*real(WICA*z))+2i*tanh(gain*imag(WICA*z)),2);
		%disp('G');
		%disp(G);
		permMat = perms(1:sigNum);
		permNum = size(permMat,1);
		for permCnt=1:permNum
			GTemp(permCnt) = abs(sum(abs(G(permMat(permCnt,:)))-abs(GOld)));
		%	WTemp(permCnt) = abs(norm((WICA(permMat(permCnt,:),:))-(Wold)))-sigNum;
		end
		GSort = sort(GTemp);
		%WSort = sort(WTemp);
		Gdiff(p) = GSort(1);
		%Wdiff(p) = WSort(1);
		Gdiff(p) = abs(sum(abs(G)-abs(GOld)));
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
		%if(Gdiff(p)<=0.01)
		%	break
		%end
		%}
	end
	figure(1);
	plot(Gdiff);
	hold all;
	%keyboard
	drawnow;
	W = WICA * V;
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
