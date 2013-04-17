%test beam steering with superdirective approach
%result should be two beampattern plots, one for ceiling and one for side
%to ceiling should be a null (at 0°)
%to side should be null at 90° and 270°
%this corresponds to the figure eight charakteristic
clear

%%%%%parameters%%%%%
options.doBeamforming = true;
options.beamforming.doNoProcess = true;
options.beamforming.noProcess.frequNum = 50;
options.beamforming.noProcess.frequMin = 100;
options.beamforming.noProcess.frequMax = 10000;
options.beamforming.doWeightMatSynthesis = true;
options.beamforming.weightMatSynthesis.angle = 90;
options.beamforming.noiseAngle = 0;
options.beamforming.muMVDR = -50;
options.beamforming.doBeampattern = true;
options.beamforming.beampattern.phi = [0:360];
options.beamforming.beampattern.teta = 90;
geometry = [0 0.01];
%%%%%parameters%%%%%

addpath('../');
if(~exist('tmp/'))
	mkdir('tmp/');
end
options.tmpDir = 'tmp/';

options.geometry = [geometry;zeros(2,numel(geometry))];
options.inputSignals = ones(numel(geometry),10);

resultsSide = start(options);%run

options.beamforming.beampattern.phi = 0;
options.beamforming.beampattern.teta = [-90:90];

resultsCeil = start(options);%run ceiling

frequencies = round(10*resultsSide.frequency)/10;%all freuqencies where pattern
												%and coeffs where calculated
teta = resultsCeil.beamforming.beampattern.teta;%all angles where pattern was
												%calculated
%teta = round(teta/options.beamforming.beampatternResolution)...
		%*options.beamforming.beampatternResolution;
phi = resultsSide.beamforming.beampattern.phi;%all angles where pattern was
												%calculated
%phi = round(phi/options.beamforming.beampatternResolution)...
		%*options.beamforming.beampatternResolution;

beampatternSide = resultsSide.beamforming.beampattern.pattern;%get resulting
																%beampattern
beampatternSide = 10*log10(beampatternSide);%to dB
beampatternSide = round(beampatternSide*100)/100;%round to two digits
beampatternCeil = resultsCeil.beamforming.beampattern.pattern;%get resulting
																%beampattern
beampatternCeil = 10*log10(beampatternCeil);%to dB
beampatternCeil = round(beampatternCeil*100)/100;%round to two digits
dataSide = [phi;squeeze(beampatternSide)];
dataSide = [[numel(phi);frequencies.'],dataSide];
dataCeil = [teta;squeeze(beampatternCeil)];
dataCeil = [[numel(teta);frequencies.'],dataCeil];

%write data to csv file
dlmwrite('tmp/testBeamSteering_side.csv',dataSide,'precision',2);
dlmwrite('tmp/testBeamSteering_ceiling.csv',dataCeil,'precision',2);

%write gnuplot file
fId = fopen('tmp/testBeamSteering.plt','w');
fprintf(fId,'#!/usr/bin/gnuplot\n');
fprintf(fId,'set datafile separator ","\n');
fprintf(fId,'set terminal png\n');
fprintf(fId,'unset key\n');
fprintf(fId,'set pm3d map\n');
fprintf(fId,'set logscale y\n');
fprintf(fId,'set cbrange [-40:0]');
fprintf(fId,'\n');
fprintf(fId,'set output "testBeamSteering_side.png"\n');
fprintf(fId,'splot "testBeamSteering_side.csv" nonuniform matrix\n');
fprintf(fId,'\n');
fprintf(fId,'set output "testBeamSteering_ceiling.png"\n');
fprintf(fId,'splot "testBeamSteering_ceiling.csv" nonuniform matrix\n');
fclose(fId);

system('cd tmp/;gnuplot testBeamSteering.plt');%call gnuplot to generate graphics
