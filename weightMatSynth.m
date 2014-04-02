function [results] = weightMatSynth(options)
if(options.beamforming.weightMatSynthesis.doCustom)
	weights = options.beamforming.weightMatSynthesis.custom.handle(options);
else
	weights = weightMatSynth_mvdr(options);
end

results.W = weights;
