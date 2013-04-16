%TODO write more tests :)
clear
addpath(fileparts(fileparts(mfilename('fullpath'))));

%test beamforming
options.doEval = true;
options.iterICA = 10;
options.beamforming.doWeightMatSynthesis = true;
options.beamforming.doBeampattern = true;
options.beamforming.beampatternResolution = 10;
results = start(options);
clear options;

options.doConvolution = true;
options.iterICA = 10;
[results opt] = start(options);
clear options;

options.doICA = true;
options.iterICA = 10;
options.ica.beampatternResolution = 10;
options.doConvolution = true;
res1 = start(options);
clear options;

options.doBeamforming = true;
options.beamforming.beampatternResolution = 10;
res2 = start(options);
clear options;
