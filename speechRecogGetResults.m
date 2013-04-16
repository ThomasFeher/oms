function results = speechRecogGetResults(out,db)
%this is in case of remote speech recognition
%the rest of the calling script can go on with these values
%they will be overwritten in the next call with
%options.speechRecognition.doGetRemoteResults = true
if(nargin<2)
	results.n = NaN;
	results.wrr = NaN;
	results.wrrConf = NaN;
	results.acr = NaN;
	results.acrConf = NaN;
	results.cor = NaN;
	results.corConf = NaN;
	results.lat = NaN;
	results.latConf = NaN;
	results.far = NaN;
	results.frr = NaN;
	results.tp = NaN;
	results.fp = NaN;
	results.fn = NaN;
	results.tn = NaN;
	results.n = NaN;
	return
end

if(strcmp(db,'apollo'))
	n = regexp(out,'N=(\d+),','tokens');
	results.n = sscanf(n{1}{1},'%f');%store as number
	wrr = regexp(out,'WRR: (\d+\.?\d*) %','tokens');
	results.wrr = sscanf(wrr{1}{1},'%f');%store as number
	results.cor = NaN;
	results.corConf = NaN;%store confidence as number
	results.lat = NaN;
	results.latConf = NaN;%store confidence as number
	acr = regexp(out,'ACR: (\d+\.?\d*) %','tokens');
	results.acrConf = NaN;%store confidence as number
	results.acr = sscanf(acr{1}{1},'%f');%store as number
	far = regexp(out,'FAR: (\d+\.?\d*) %','tokens');
	results.far = sscanf(far{1}{1},'%f');%store as number
	frr = regexp(out,'FRR: (\d+\.?\d*) %','tokens');
	results.frr = sscanf(frr{1}{1},'%f');%store as number
	tp = regexp(out,'TP=(\d+),','tokens');
	results.tp = sscanf(tp{1}{1},'%f');%store as number
	fp = regexp(out,'FP=(\d+),','tokens');
	results.fp = sscanf(fp{1}{1},'%f');%store as number
	fn = regexp(out,'FN=(\d+),','tokens');
	results.fn = sscanf(fn{1}{1},'%f');%store as number
	tn = regexp(out,'TN=(\d+)','tokens');
	results.tn = sscanf(tn{1}{1},'%f');%store as number
elseif(strcmp(db,'samurai'))
	err = regexp(out,'error - FATAL');
	if(~isempty(err))
		error(['speech recognition failed, output was: ' out]);
	end
	n = regexp(out,'Word sequences[ ]*: (\d+)/\d+ samples','tokens');
	results.n = sscanf(n{1}{1},'%f');%store as number
	wrr = numel(regexp(out,'A=1,'))/results.n*100;
	results.wrr = wrr;
	cor = regexp(out,'Correctness[ ]*: (-?\d+\.?\d*) %[ ]*\+-(\d+\.?\d*)'...
		,'tokens');
	results.cor = sscanf(cor{1}{1},'%f');%store as number
	results.corConf = sscanf(cor{1}{2},'%f');%store confidence as number
	acr = regexp(out,'Accuracy[ ]*: (-?\d+\.?\d*) %[ ]*\+-(\d+\.?\d*)','tokens');
	results.acr = sscanf(acr{1}{1},'%f');%store as number
	results.acrConf = sscanf(acr{1}{2},'%f');%store confidence as number
	lat = regexp(out,'Lattice density[ ]*: (-?\d+\.?\d*)[ ]*\+-(\d+\.?\d*)'...
		,'tokens');
	results.lat = sscanf(lat{1}{1},'%f');%store as number
	results.latConf = sscanf(lat{1}{2},'%f');%store confidence as number
	results.far = NaN;
	results.frr = NaN;
	results.tp = NaN;
	results.fp = NaN;
	results.fn = NaN;
	results.tn = NaN;
else
	error ([db ' is not a valid corpus name']);
end

results.wrrConf = confidence(results.wrr/100*results.n,results.n) * 100;
