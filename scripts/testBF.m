clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
options.impulseResponses = struct('angle',{0 45},'distance',1.8,'room','refRaum');
options.doBeamforming = true;
options.beamforming.doWeightMatSynthesis = true;
options.beamforming.muMVDR = -50;
options.beamforming.noiseAngle = -45;
[result opt] = start(options);
wavwrite(result.signal(:,:)',opt.fs,'/erk/tmp/feher/sig.wav');
eopen('/erk/tmp/feher/bf.eps');
eimagesc(abs(squeeze(result.beamforming.beampattern(:,:,1))));
eclose;
