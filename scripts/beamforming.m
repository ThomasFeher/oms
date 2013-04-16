%script example for beampattern synthesis
clear
addpath(fileparts(fileparts(mfilename('fullpath'))));% add parent folder

%%%%%settings%%%%%
options.doBeamforming = true;
options.beamforming.doNoProcess = true;%no audio signal processing
options.beamforming.doWeightMatSynthesis = true;%calc beamforming weights
options.beamforming.doBeampattern = true;%calculate resulting beampattern
options.beamforming.noiseAngle = 30;
options.beamforming.muMVDR = -inf;%switch between superdirective (-inf)
									%and DSB (inf)
options.geometry = [-0.5 -0.1 0.1 0.5;%...x-coordinates of microphones
					0 0 0 0;%...y-coordinates of microphones
					0 0 0 0];%z-coord is ignored, so don't use!
options.inputSignals = zeros(4,10);%provide dummy input signal to prevent error
options.beamforming.noProcess.frequNum = 50;%number of frequencies to evaluate
options.beamforming.noProcess.frequMin = 20;%lowest frequency
options.beamforming.noProcess.frequMax = 2000;%highest frequency
options.beamforming.beampatternResolution = 2;%resolution in degree
resultDir = '~/tmp/';
%%%%%settings%%%%%

%%%%%run%%%%%
results = start(options);
%%%%%run%%%%%

%%%%%results%%%%%
beampattern = results.beamforming.beampattern;%array [frequ,angle1,angle2]
												%angles go from -90 to 90 degree
beampattern(isnan(beampattern)) = 1;%set all NaN values to zero
coefficients = results.weightMatSynth.W;%coefficients for each microphone in
										%frequency domain, array [mic,frequ]
frequencies = results.frequency;%all freuqencies where pattern and coeffs where
								%calculated
teta = results.beamforming.teta;%all angles where pattern was calculated
%%%%%results%%%%%

%%%%%export 2D%%%%%
frequCnt = 10;
frequency = frequencies(frequCnt);
fileName = sprintf('pattern_%05.0fHz.csv',frequency);
fileName = fullfile(resultDir,fileName);
toWrite = [teta.',squeeze(beampattern(frequCnt,:,:))];
dlmwrite(fileName,toWrite);
%%%%%export 2D%%%%%

%%%%%export surfplot%%%%%
fileName = sprintf('pattern.csv',frequency);
fileName = fullfile(resultDir,fileName);
%f = frequencies.' * ones(1,numel(teta));%f(:)=[frequ1;frequ2;...;frequ1;frequ2;..]
%t = ones(numel(frequencies),1) * teta;%t(:)=[teta1;teta1;...;teta2;teta2;...]
%b = beampattern(:,:,90);
%toWrite = [t(:),f(:),b(:)];
%dlmwrite(fileName,toWrite);
delete(fileName);
for tetaCnt=1:numel(teta)
	t = ones(numel(frequencies),1) * teta(tetaCnt);
	toWrite = [t,frequencies.',20*log10(squeeze(beampattern(:,tetaCnt,90)))];
	dlmwrite(fileName,toWrite,'-append','precision','%2.1f');%,'roffset',(tetaCnt-1)*(numel(frequencies)+1));
	fId = fopen(fileName,'a');
	fprintf(fId,'\n');
	fclose(fId);
end
%%%%%export surfplot%%%%%
