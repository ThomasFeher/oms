%fitness function for compatibility with GODLIKE optimization tool
%params contains all parameters that will be optimized:
%1: options.twinMic.beamformer.angle
%2: options.blockSize
%3: time shift coefficient = options.timeShift / options.blockSize
function fitness = gaTwinBfFnct(params)

options.doTdRestore = true;
options.doConvolution = true;
options.inputSignals =...
		{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		'~/AudioDaten/nachrichten_10s.wav'};
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
resultDir = '/erk/tmp/feher/gaTwinBf/';
options.resultDir = resultDir;
options.doTwinMicBeamforming = true;
sourceDist = 1;

%parameters
options.twinMic.beamformer.angle = params(1);
options.blockSize = round(params(2));
options.timeShift = round(params(3)*params(2));
%if(options.timeShift<1)
	%options.timeShift = 1;
%elseif(options.timeShift>options.blockSize/2)
	%options.timeShift = floor(options.blockSize/2);
%end

%use random angle and distance
distances = [0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1];
angles = [90:15:180];
distance = distances(randi(numel(distances),1));
angle = angles(randi(numel(angles),1));

%calculate amplification of second signal due to increased distance
level = 20*log10(distance/sourceDist);
options.impulseResponses = struct('angle',{0 angle},...
		'distance',{sourceDist distance},'room','studio',...
		'level',{0 level});

%call framework to run algorithm
[result opt] = start(options);
fitness = evalTwinMic(opt,result);
fitness = 1/fitness;
