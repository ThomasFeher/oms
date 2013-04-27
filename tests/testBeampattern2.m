function testBeampattern2()
addpath('..');%change to oms path
levelMain = 50;

pattern = simpleArray(2,levelMain);
if(pattern(1)~=0)
	error('testBeampattern2 failed');
end
if(pattern(91)~=levelMain)
	error('testBeampattern2 failed');
end
if(pattern(181)~=0)
	error('testBeampattern2 failed');
end

pattern = simpleArray(3,levelMain);
levelSide = levelMain + 20*log10(1/3);%2 mics phase out the third one brings
										%the complete signal -> 1/3 of main lobe
if(pattern(1)~=levelSide)
	error('testBeampattern2 failed');
end
if(pattern(91)~=levelMain)
	error('testBeampattern2 failed');
end
if(pattern(181)~=levelSide)
	error('testBeampattern2 failed');
end

function pattern = simpleArray(micNum,levelMain)
options.doBeamforming = true;
options.beamforming.doNoProcess = true;
options.beamforming.doBeampattern = true;
options.beamforming.beampattern.phi = 0;
options.beamforming.beampattern.teta = -90:90;
options.beamforming.noProcess.frequNum = 1;
distDividedByLambda = 1/2;
plotMin = -levelMain;

frequency = 1000;
lambda = 340/frequency;
dist = lambda * distDividedByLambda;
options.beamforming.noProcess.frequMax = frequency;
options.geometry = [[dist * [0:micNum-1]];zeros(2,micNum)];
options.inputSignals = ones(micNum,1);

results = start(options);%run oms

%get pattern and convert to dB
pattern = 10*log10(squeeze(results.beamforming.beampattern.pattern));
pattern(pattern<plotMin) = plotMin;%cut very low values
pattern = pattern - plotMin;%make lowest value 0dB
angles = results.beamforming.beampattern.teta;
%polar([0:180]/180*pi,pattern);%plot
plot(angles,pattern);
