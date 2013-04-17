function writeAudio(signal,signalICA,sortName,options)
disp('Writing audio files...');
fs = options.fs;
audioFileLength = length(signal);
signalWrite = signal./(max(max(abs(signal)))*1.1);
signalICAWrite = signalICA./(max(max(abs(signalICA)))*1.1);
for cnt=1:options.sigNum
	wavName = [options.resultDir 'signal' int2str(cnt) '.wav'];
	mixedFiles{cnt} = wavName;
	wavwrite(signalWrite(cnt,1:audioFileLength)',fs,16,wavName);
	wavName = [options.resultDir 'signalICA_' sortName '_' int2str(cnt) '.wav'];
	%estimateFiles{cnt} = wavName;
	wavwrite(signalICAWrite(cnt,1:audioFileLength)',fs,16,wavName);
	wavName = [options.tmpDirExp 'signalEstimate' int2str(cnt) '.wav'];
	wavwrite(signalICAWrite(cnt,1:audioFileLength)',fs,16,wavName);
end
