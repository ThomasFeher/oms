%-----------------------------------------------------------------------
%| Function: admaBuildCardioids
%-----------------------------------------------------------------------
%| Generate the 3 cardioid patterns out of the 3 mic signals
%|
%| Author:  Patrick Michelson
%| Version: 0.1 
%| Date:    08.10.2012 
%| Library: ADMA
%|
%|
%| @param <3xN complex> sigVec          - Matrix with freq spec. of 3 mics 
%|                                        (N=number of freqencies)
%| @param <1xN double> freqVec          - Vector with frequencies
%| @param <double> dis                  - Distance between mics
%|
%| @return <3xN complex> sigVecCardioid - Matrix with 3 cardioid patterns                           XX1:
%|
%----------------------------------------------------------------------

function [ sigVecCardioid ] = admaBuildCardioids(sigVec,freqVec,dist...
												,speedOfSound,doEqualization)
if(nargin<5)
	doEqualization = true;
end

%c = 340;    %speed of sound in m/s
j = 1i;
x2 = 0.84;        %level adjustment of mic 2
x3 = 1.08;        %level adjustment of mic 3

%calculate gain for frequencies (low-pass filter)
offset = 1/30;
gain = abs(2*sin(2*pi .* freqVec / speedOfSound * 14.3e-3))+2*offset;

%adjust level of mic signals
sigVec(2,:) = x2 * sigVec(2,:);
sigVec(3,:) = x3 * sigVec(3,:);

%build cardioids
sigVecCardioid(1,:) = (sigVec(1,:) - sigVec(2,:)...
						.* exp((-j*2*pi*dist/speedOfSound) * freqVec));
sigVecCardioid(2,:) = (sigVec(3,:) - sigVec(1,:)...
						.* exp((-j*2*pi*dist/speedOfSound) * freqVec));
sigVecCardioid(3,:) = (sigVec(2,:) - sigVec(3,:)...
						.* exp((-j*2*pi*dist/speedOfSound) * freqVec));

if(doEqualization)%equalize levels
	sigVecCardioid(1,:) =  sigVecCardioid(1,:) ./ gain;
	sigVecCardioid(2,:) =  sigVecCardioid(2,:) ./ gain;
	sigVecCardioid(3,:) =  sigVecCardioid(3,:) ./ gain;
end
