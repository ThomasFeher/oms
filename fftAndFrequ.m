%function to calculate fft and vector of frequencies of one or more signals
%input:
	%sig: signal in time domain [channel,sample]
	%fs: sample rate
%output:
	%sigFd: signal in frequency domain [channel,sample]
	%frequ: vector of frequencies corresponding to sigFd
function [sigFd frequ] = fftAndFrequ(sig,fs)
sigFd = fft(sig.').';
fftSize = size(sigFd,2);
frequ = fs/2 * linspace(0,1,fftSize/2+1);
if(mod(fftSize,2))%odd fft size (fs/2 is omitted)
	frequ = [frequ(1:end-1) frequ(end-1:-1:2)];
else%even fft size
	frequ = [frequ(1:end) frequ(end-1:-1:2)];
end
