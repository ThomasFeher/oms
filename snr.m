%calculate signal to noise ratio
%usage: snr(signal,noise[,mode])
%mode: 1: standard mode 2: noise signal contains signal+noise
function retval = snr(signal, noise,mode)
if(~iscolumn(signal))
	if(~isrow(signal))
		error('signal must be a vector');
	else
		signal = signal.';
		transpSig1 = 1;
	end
end
if(~iscolumn(noise))
	if(~isrow(noise))
		error('noise must be a vector');
	else
		noise = noise.';
	end
end
if(size(signal,2)~=1)
	error('Signal must be column vector');
end
if(size(noise,2)~=1)
	error('Noise must be column vector');
end
if(nargin<2)
	error('usage: snr(signal,noise[,mode])');
end
if(nargin<3)
	mode=1;
end
if(mode<1|mode>2)
	error('mode must be 1 or 2');
end

signalSize = size(signal,1);
noiseSize = size(noise,1);

signalPower = (signal'*signal)/signalSize;
noisePower = (noise'*noise)/noiseSize;

if(mode==1)
	retval = 10 * log10(signalPower/noisePower);
end
if(mode==2)
	retval = 10 * log10(signalPower/(noisePower-signalPower));
end

function retval = iscolumn(input)
if((size(input,2)==1)&&(size(input,1)>=0))
	retval = 1;
else
	retval = 0;
end
function retval = isrow(input)
if((size(input,1)==1)&&(size(input,2)>=0))
	retval = 1;
else
	retval = 0;
end
