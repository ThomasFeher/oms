function out = beamformProcessing(options,signal,W)
out = sum(signal.*W);
