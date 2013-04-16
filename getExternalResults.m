%gathers results of speechRecogReference.pl script stored in the file <fileName>
%returns results in the struct <result>
function result = getExternalResults(fileName)
fid = fopen([fileName],'r');
lines = [];
while ~feof(fid)
	line = fgets(fid);
	lines = [lines line];
end
fclose(fid);
n = regexp(lines,'n: (\d+)','tokens');
result.n = sscanf(n{1}{1},'%f');%store as number
wrr = regexp(lines,'wrr: (\d+\.?\d*)','tokens');
result.wrr = sscanf(wrr{1}{1},'%f');%store as number
acr = regexp(lines,'acr: (-?\d+\.?\d*)','tokens');
result.acr = sscanf(acr{1}{1},'%f');%store as number
acrconf = regexp(lines,'acrconf: (\d+\.?\d*)','tokens');
result.acrconf = sscanf(acrconf{1}{1},'%f');%store as number
cor = regexp(lines,'cor: (-?\d+\.?\d*)','tokens');
result.cor = sscanf(cor{1}{1},'%f');%store as number
corconf = regexp(lines,'corconf: (\d+\.?\d*)','tokens');
result.corconf = sscanf(corconf{1}{1},'%f');%store as number
lat = regexp(lines,'lat: (-?\d+\.?\d*)','tokens');
result.lat = sscanf(lat{1}{1},'%f');%store as number
latconf = regexp(lines,'latconf: (\d+\.?\d*)','tokens');
result.latconf = sscanf(latconf{1}{1},'%f');%store as number
