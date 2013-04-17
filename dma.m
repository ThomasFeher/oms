%differential microfone array
%from Teutsch and Elko, "First- and Second-Order Adaptive Differential
%Microphone Arrays"
function sigVecNew = dma(options,sigVec)
angle = options.dma.angle/180*pi;
frequencies = options.frequency;
%k = 2*pi*frequencies/options.c;
c = options.c;

%calculate distance of microphones
d = sqrt(sum(options.geometry(:,1).^2) + sum(options.geometry(:,2).^2));
%calculate delay in time domain
T = -d/c*cos(angle);
%calculate delay in frequency domain
%delay = exp(-i*(2*pi*frequencies*T+k*d));
delay = exp(-i*(2*pi*frequencies*T));
%calculate filter
filtCoeff = 1./(2*pi*frequencies);
%calculate output signal
%keyboard
sigVecNew = zeros(size(sigVec));
sigVecNew(2,:) = sigVec(1,:);
sigVecNew(1,:) = filtCoeff .* (sigVec(1,:)-delay.*sigVec(2,:));
