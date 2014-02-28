function state = saveGeneration(options,state,flag)
fileName = sprintf('generation_%03d',state.Generation);
save fileName state options flag;
end
