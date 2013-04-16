clear
addpath '~/Simulationen/bfICA'
options.inputSignals =...
		{'~/AudioDaten/speech1.wav','~/AudioDaten/speech2.wav','~/AudioDaten/music1.wav'};
options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		'room','buero');
%options.inputSignals =...
		%{'~/AudioDaten/speech1.wav','~/AudioDaten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%options.iterICA = 1;
options.doEvalPeass = false;
%options.doEvalPeass = false;
%options.doEvalStd = false;
results = fdICA(options);

addpath '~/epstk/m';
eopen;
eimagesc(results.abpFeher.abpTwoDim);
eclose;
eopen('1.eps');
eimagesc(squeeze(results.abpFeher.abpPattern(1,:,:)));
eclose;
eopen('2.eps');
eimagesc(squeeze(results.abpFeher.abpPattern(2,:,:)));
eclose;
eopen('3.eps');
eimagesc(squeeze(results.abpFeher.abpPattern(3,:,:)));
eclose;

%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [1 2 3];
%fdICA(options);

%options.sourceLocOptions.frequLow = 300;
%options.sourceLocOptions.frequHigh = 3000;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 45},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = 'all';
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 3000;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 45},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = 'all';
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 1;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 45},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = 'all';
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 300;
%options.sourceLocOptions.frequHigh = 3000;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = 'all';
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 3000;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = 'all';
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 1;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = 'all';
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 300;
%options.sourceLocOptions.frequHigh = 3000;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 45},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 3000;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 45},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 1;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav'};
%options.impulseResponses = struct('angle',{0 45},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 300;
%options.sourceLocOptions.frequHigh = 3000;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 3000;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%fdICA(options);
%clear options;

%options.sourceLocOptions.frequLow = 1;
%options.sourceLocOptions.frequHigh = inf;
%options.inputSignals =...
		%{'Daten/speech1.wav','Daten/speech2.wav','Daten/music1.wav'};
%options.impulseResponses = struct('angle',{0 45 90},'distance',0.8,...
		%'room','buero');
%options.irDatabaseChannels = [2 3];
%fdICA(options);
%clear options;
