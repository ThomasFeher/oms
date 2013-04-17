clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
%options.irDatabaseChannels = [2 3];
%options.inputSignals =...
		%{'~/AudioDaten/DLF_Gespraech_48kHz_10s.wav',...
		%'~/AudioDaten/nachrichten_10s_48kHz.wav'};
options.inputSignals =...
		{'~/AudioDaten/DLF_Gespraech_10s.wav',...
		'~/AudioDaten/nachrichten_10s.wav'};
options.irDatabaseSampleRate = 16000;
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 1024;
options.doDistanceFiltering = true;
options.distanceFilter.withGate = true;
resultDir = '/erk/tmp/feher/';
mkdir(resultDir);

options.impulseResponses = struct('angle',0,...
'distance',{dist1 dist2},'room','refRaum',...
'level',{1 30});
options.distanceFilter.threshold = thCnt;
options.distanceFilter.update = updateCnt;
options.distanceFilter.cutoffFrequencyHigh = frequCnt;
options.distanceGate.threshold = dGateThCnt;
options.timeShift = shiftCnt;
options.doICA = true;

[result opt] = start(options);
[snrImp snrBefore] = evalTwinMic(opt,result)
expString = sprintf(['refRaum_snr:%2.1f_cutoff:%d_threshold:%1.1f_'...
'update:%0.2f_timeShift:%03d_dGateTh:%1.2f_-_%02.1f']...
,snrBefore,frequCnt,thCnt,updateCnt,shiftCnt,dGateThCnt,snrImp);

