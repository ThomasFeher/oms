clear
addpath('~/sim/framework/');

%%%%%parameters%%%%%
%options.doTdRestore = true;
options.doConvolution = true;
options.inputSignals = 1;%workaround to load plain impuls responses
options.irDatabasName = 'twoChanMicHiRes';
options.impulseResponses.angle = angle(angleCnt);
options.impulseResponses.distance = 0.4;
options.impulseResponses.room = 'studio';
options.doBeamforming = true;
options.beamforming.doNoProcess = true;
options.beamforming.doBeampattern = true
angles = [0:15:345];
%%%%%parameters%%%%%

angleNum = numel(angles);

for angleCnt=1:angleNum
	results = start(options);
end
