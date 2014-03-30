%function to calculate fft and vector of frequencies of one or more signals
%input:
	%sig: signal in time domain [channel,sample]
	%fs: sample rate
%output:
	%sigFd: signal in frequency domain [channel,sample]
	%frequ: vector of frequencies corresponding to sigFd
function [sigFd frequ] = fftAndFrequ(sig,fs)
usage = 'usage: fftAndFrequ(signal,fs)';
if(nargin<2)
	error(usage);
end

sigFd = fft(sig.').';
fftSize = size(sigFd,2);
if(mod(fftSize,2))%odd fft size
	frequ = linspace(0,(fftSize+1)/2-1,(fftSize+1)/2) ./ fftSize .* fs;
	frequ = [frequ(1:end) frequ(end:-1:2)];
else%even fft size
	frequ = fs/2 * linspace(0,1,fftSize/2+1);
	frequ = [frequ(1:end) frequ(end-1:-1:2)];
end

%!test # even number of samples
%! sig = [1 2 3 4];
%! [sigFd freq] = fftAndFrequ(sig,8);
%! assert(freq,[0,2,4,2]);
%!test # odd number of samples
%! sig = [1 2 3 4 5];
%! [sigFd freq] = fftAndFrequ(sig,10);
%! assert(freq,[0,2,4,4,2]); # reference matlab: [~,x]=specgram([1,2,3,4,5],[],10);
