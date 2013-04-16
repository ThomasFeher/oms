clear;

taps=256;
%%%%%%%%%%%%%%mixing matrix%%%%%%%%%%%%%
%example in book:
% ir(1,1)=1; ir(250,1)=-0.4; ir(450,1)=0.2;
% ir(200,3)=0.4; ir(280,3)=-0.2; ir(360,3)=0.1;
% ir(100,4)=0.5; ir(220,4)=0.3; ir(340,4)=0.1;
% ir(1,2)=1; ir(200,2)=-0.3; ir(380,2)=0.2;
ir(1,1)=1; ir(25,1)=-0.4; ir(45,1)=0.2;
ir(20,3)=0.4; ir(28,3)=-0.2; ir(36,3)=0.1;
ir(10,4)=0.5; ir(22,4)=0.3; ir(34,4)=0.1;
ir(1,2)=1; ir(20,2)=-0.3; ir(38,2)=0.2;
%%%%%%%%%%%%%%mixing matrix%%%%%%%%%%%%%

%%%%%%%%%%%%%%demixing matrix%%%%%%%%%%%%%
g=conv(ir(:,1),ir(:,2))-conv(ir(:,3),ir(:,4));
irTheo=zeros(taps,4);
irTheo(:,1)=filter(ir(:,2),g,[1;zeros(taps-1,1)]);
irTheo(:,2)=filter(ir(:,1),g,[1;zeros(taps-1,1)]);
irTheo(:,3)=-1*filter(ir(:,3),g,[1;zeros(taps-1,1)]);
irTheo(:,4)=-1*filter(ir(:,4),g,[1;zeros(taps-1,1)]);
%%%%%%%%%%%%%%demixing matrix%%%%%%%%%%%%%

%%%%%%%%%%%%%%testsignal%%%%%%%%%%%%%
signal(:,1)=0.5*rand (140000,1);
signal(:,2)=0.5*rand (140000,1);
testsignal=zeros(10000,2);
testsignal(1:5000,1)=signal(1:5000,1);
testsignal(5001:10000,2)=signal(5001:10000,2);
%%%%%%%%%%%%%%testsignal%%%%%%%%%%%%%

%%%%%%%%%%%%%%conv with mixing system%%%%%%%%%%%%%
testsignalMix(:,1)=[filter(ir(:,1),1,signal(1:5000,1));filter(ir(:,3),1,signal(5001:10000,2))];
testsignalMix(:,2)=[filter(ir(:,4),1,signal(1:5000,1));filter(ir(:,2),1,signal(5001:10000,2))];
%%%%%%%%%%%%%%conv with mixing system%%%%%%%%%%%%%

%%%%%%%%%%%%%%conv with demixing system%%%%%%%%%%%%%
testsignalDemix(:,1)=filter(irTheo(:,1),1,testsignalMix(:,1)) + filter(irTheo(:,3),1,testsignalMix(:,2));
testsignalDemix(:,2)=filter(irTheo(:,2),1,testsignalMix(:,2)) + filter(irTheo(:,4),1,testsignalMix(:,1));
%%%%%%%%%%%%%%conv with demixing system%%%%%%%%%%%%%

%%%%%%%%%%%%%%zeros-poles%%%%%%%%%%%%%
fprintf('number of poles and roots not inside / outside unit circle of mixing filter:\n');
rootsIr1=roots(ir(:,1));
fprintf('A11: %d/%d\n', length(find(abs(rootsIr1)>=1)),length(find(abs(rootsIr1)>1)));
if(any(abs(rootsIr1)>=1))
	[rootCol rootRow]=find(abs(rootsIr1)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIr1(rootCol(cnt))),real(rootsIr1(rootCol(cnt))),imag(rootsIr1(rootCol(cnt))));
	end
end
rootsIr3=abs(roots(ir(:,3)));
fprintf('A12: %d/%d\n', length(find(rootsIr3>=1)),length(find(rootsIr3>1)));
if(any(abs(rootsIr3)>=1))
	[rootCol rootRow]=find(abs(rootsIr3)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIr3(rootCol(cnt))),real(rootsIr3(rootCol(cnt))),imag(rootsIr3(rootCol(cnt))));
	end
end
rootsIr4=abs(roots(ir(:,4)));
fprintf('A21: %d/%d\n', length(find(rootsIr4>=1)),length(find(rootsIr4>1)));
if(any(abs(rootsIr4)>=1))
	[rootCol rootRow]=find(abs(rootsIr4)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIr4(rootCol(cnt))),real(rootsIr4(rootCol(cnt))),imag(rootsIr4(rootCol(cnt))));
	end
end
rootsIr2=abs(roots(ir(:,2)));
fprintf('A22: %d/%d\n', length(find(rootsIr2>=1)),length(find(rootsIr2>1)));
if(any(abs(rootsIr2)>=1))
	[rootCol rootRow]=find(abs(rootsIr2)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIr2(rootCol(cnt))),real(rootsIr2(rootCol(cnt))),imag(rootsIr2(rootCol(cnt))));
	end
end
fprintf('\nnumber of poles and roots not inside / outside unit circle of demixing filter:\n');
fprintf('Zeros:\n');
rootsIrTheo1=roots(ir(:,2));
polesIrTheo1=roots(g);
fprintf('W11: %d/%d\n', length(find(abs(rootsIrTheo1)>=1)),length(find(abs(rootsIrTheo1)>1)));
if(any(abs(rootsIrTheo1)>=1))
	[rootCol rootRow]=find(abs(rootsIrTheo1)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIrTheo1(rootCol(cnt))),real(rootsIrTheo1(rootCol(cnt))),imag(rootsIrTheo1(rootCol(cnt))));
	end
end
rootsIrTheo3=abs(roots(ir(:,3)));
fprintf('W12: %d/%d\n', length(find(rootsIrTheo3>=1)),length(find(rootsIrTheo3>1)));
if(any(abs(rootsIrTheo3)>=1))
	[rootCol rootRow]=find(abs(rootsIrTheo3)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIrTheo3(rootCol(cnt))),real(rootsIrTheo3(rootCol(cnt))),imag(rootsIrTheo3(rootCol(cnt))));
	end
end
rootsIrTheo4=abs(roots(ir(:,4)));
fprintf('W21: %d/%d\n', length(find(rootsIrTheo4>=1)),length(find(rootsIrTheo4>1)));
if(any(abs(rootsIrTheo4)>=1))
	[rootCol rootRow]=find(abs(rootsIrTheo4)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIrTheo4(rootCol(cnt))),real(rootsIrTheo4(rootCol(cnt))),imag(rootsIrTheo4(rootCol(cnt))));
	end
end
rootsIrTheo2=abs(roots(ir(:,1)));
fprintf('W22: %d/%d\n', length(find(rootsIrTheo2>=1)),length(find(rootsIrTheo2>1)));
if(any(abs(rootsIrTheo4)>=1))
	[rootCol rootRow]=find(abs(rootsIrTheo4)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(rootsIrTheo4(rootCol(cnt))),real(rootsIrTheo4(rootCol(cnt))),imag(rootsIrTheo4(rootCol(cnt))));
	end
end

fprintf('Poles: %d/%d\n', length(find(abs(polesIrTheo1)>=1)),length(find(abs(polesIrTheo1)>1)));
if(any(abs(polesIrTheo1)>=1))
	[rootCol rootRow]=find(abs(polesIrTheo1)>=1);
	for cnt=1:length(rootCol)
		fprintf('Abs: %f Root: %f + %fi\n',abs(polesIrTheo1(rootCol(cnt))),real(polesIrTheo1(rootCol(cnt))),imag(polesIrTheo1(rootCol(cnt))));
	end
end
%%%%%%%%%%%%%%zeros-poles%%%%%%%%%%%%%

%%%%%%%%%%%%%%plot%%%%%%%%%%%%%
figure(1);
subplot(3,2,1);
plot(testsignal(:,1));

subplot(3,2,2);
plot(testsignal(:,2));

subplot(3,2,3);
plot(testsignalMix(:,1));

subplot(3,2,4);
plot(testsignalMix(:,2));

subplot(3,2,5);
plot(testsignalDemix(:,1));

subplot(3,2,6);
plot(testsignalDemix(:,2));

figure(2);
subplot(2,2,1);
zplane(ir(:,1)');

subplot(2,2,2);
zplane(ir(:,3)');

subplot(2,2,3);
zplane(ir(:,4)');

subplot(2,2,4);
zplane(ir(:,2)');

figure(3);
subplot(2,2,1);
zplane(irTheo(:,1)');

subplot(2,2,2);
zplane(irTheo(:,3)');

subplot(2,2,3);
zplane(irTheo(:,4)');

subplot(2,2,4);
zplane(irTheo(:,2)');

figure(3);
subplot(2,2,1);
plot(irTheo(:,1));
set(gca,'ylim',[-1,1]);
subplot(2,2,2);
plot(irTheo(:,2));
set(gca,'ylim',[-1,1]);
subplot(2,2,3);
plot(irTheo(:,3));
set(gca,'ylim',[-1,1]);
subplot(2,2,4);
plot(irTheo(:,4));
set(gca,'ylim',[-1,1]);
%%%%%%%%%%%%%%plot%%%%%%%%%%%%%
