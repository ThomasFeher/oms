clear
addpath('~/sim/framework/');

%%%%%parameters%%%%%
angleStart = 0;
angleEnd = 360;
angleStep = 15;
levelMin = -30;%lowest level to plot
distance = 0.5;
outpath = '/erk/home/feher/temp/';
outfile = 'irBeampattern';
outfileExt = 'csv';
plotfile = 'irBeampattern';
plotfileExt = '.plt';
doCalc = true;
doPlot = true;
frequencies = [200,500,1000,2500];%plot polar plots at these frequs
database = 'Twin';%'Twin','Three'
%%%%%parameters%%%%%

angles = [angleStart:angleStep:angleEnd];
options.inputSignals = 1;
%options.inputSignals = rand(1,1000)-0.5;
chanNum = 2;%with twinMic
options.doConvolution = true;
if(strcmpi(database,'twin'))
	options.irDatabaseName = 'twoChanMicHiRes';
elseif(strcmpi(database,'three'))
	options.irDatabaseName = 'threeChanDMA';
end
options.fs = 16000;
room = 'studio';
angleNum = numel(angles);
frequNum = numel(frequencies);
yticks = 0:10:-levelMin-10;%from 0 to a positive number
ytickLabels = levelMin:10:-10;%from levelMin until short before 0
%generate tick strings for the plot files
yticksString = [];
ytickLabelsString = [];
for tickCnt=1:numel(yticks)
	if(tickCnt~=1)
		yticksString = [yticksString ','];
		ytickLabelsString = [ytickLabelsString ','];
	end
	yticksString = [yticksString sprintf('%2.0f',yticks(tickCnt))];
	ytickLabelsString=[ytickLabelsString sprintf('%2.0f',ytickLabels(tickCnt))];
end

if doCalc
	for angleCnt=1:angleNum
		options.impulseResponses = struct('angle',angles(angleCnt)...
				,'distance',distance,'room',room);
		[results opt] = start(options);
		if angleCnt==1%create empty beampattern, to avoid permanent reallocation
			fftNum = numel(results.input.signal(1,:));%find number of time points
			fftFrequNum = floor(fftNum/2)+1;%find number of frequency points
			%fftFrequs = options.fs/2*linspace(0,1,fftFrequNum);%vector of frequencies
			fftFrequs = opt.frequency;
			%beampattern = zeros(chanNum,angleNum+1,fftFrequNum);%empty beampattern
			beampattern = zeros(chanNum,angleNum,fftFrequNum);%empty beampattern
			%calculate polar plot frequency indices
			for frequCnt=1:frequNum
				frequInd = find(fftFrequs>=frequencies(frequCnt));
				frequInds(frequCnt) =  frequInd(1);
			end
		end
		fftResult = fft(results.input.signal.');%do fft
		beampattern(:,angleCnt,:) = abs(fftResult(1:fftFrequNum,:).').^2;%take
												%absolute and square and store
	end
	%fftSize = size(fftResult,1);%size of complete fft vector
	%fftFrequNum = floor(fftSize/2)+1;%number of positive frequencies
	%fftFrequs = options.fs/2*linspace(0,1,fftFrequNum);%vector of frequencies
	%beampattern(:,angleNum+1,:) = beampattern(:,1,:);%last line = first line, to
												%connect plot to full circle

	%normalize for each frequency
	for chanCnt=1:chanNum
		maxPerFrequ = max(beampattern(chanCnt,:,:),[],2);%maximum for each frequ
		%disp(size(maxPerFrequ));
		%maxPerFrequ = maxPerFrequ(ones(1,angleNum+1),:);%expand to matrix
		maxPerFrequ = maxPerFrequ(ones(1,angleNum),:);%expand to matrix
		%disp(size(maxPerFrequ));
		%disp(beampattern(1,[1 10 angleNum+1],1:100)/100);keyboard
		beampattern(chanCnt,:,:) = squeeze(beampattern(chanCnt,:,:))...
				./ maxPerFrequ;
	end
	%to dB
	beampattern = 10*log10(beampattern);%to dB
	beampattern(beampattern<levelMin) = levelMin;%cut values below levelMin
	beampattern = round(10*beampattern)/10;%round to 1 decimal value
	for chanCnt=1:chanNum
		%generate heatmap data file
		dlmwrite([outpath outfile database sprintf('%d.',chanCnt) outfileExt]...
				,squeeze(beampattern(chanCnt,:,:)).');
		%generate polar data file
		data = squeeze(beampattern(chanCnt,:,frequInds));%pick data at frequencies
		data = data - levelMin;
		dataAll = [angles.',data];%first column is angles
		%dataAll = [frequNum,frequencies;dataAll];%first row is frequencies
		dlmwrite([outpath outfile database 'Polar' sprintf('%d.',chanCnt)...
				outfileExt],dataAll);
	end
end

%generate heatmap plot file
fId = fopen([outpath plotfile database 'Map' plotfileExt],'w');
fprintf(fId,'#!/usr/bin/gnuplot\n');
fprintf(fId,'set datafile separator ","\n');
fprintf(fId,'set cbrange [-40:0]\n');
%fprintf(fId,'set xrange [0:345]\n');
fprintf(fId,'set pm3d map\n');
fprintf(fId,'set xtics %d,%d,%d\n',angleStart,angleStep,angleEnd);
fprintf(fId,'set terminal pdf\n');
for chanCnt=1:chanNum
	fprintf(fId,['set output "' outfile database sprintf('Map%d.',chanCnt) 'pdf"\n']);
	fprintf(fId,['splot "' outfile database sprintf('%d.',chanCnt) outfileExt...
			'" using ($1*%d):2:3 matrix\n'],angleStep);
end
fclose(fId);

%generate polar plot file
plotString = ['"< perl -ne ''print join(\\"\\n\\",split(/,/,$_))'...
	' if($.==%d)''\\\n\t' outfile database '%d.' outfileExt '" using ($0*%d):1 w l'...
	' title "%dHz"'];
fId = fopen([outpath plotfile database 'Polar' plotfileExt],'w');
fprintf(fId,'#!/usr/bin/gnuplot\n');
fprintf(fId,'set datafile separator ","\n');
%fprintf(fId,'set xrange [0:345]\n');
fprintf(fId,'set xtics %d,%d,%d\n',angleStart,angleStep,angleEnd);
fprintf(fId,'set polar\n');
fprintf(fId,'set grid polar\n');
fprintf(fId,'unset xtics\n');
fprintf(fId,'unset ytics\n');
fprintf(fId,'set border 0\n');
fprintf(fId,'set size square\n');
fprintf(fId,'set angles degrees\n');
fprintf(fId,'set rrange [%d:0]\n',levelMin);
fprintf(fId,'set terminal pdf\n');
for chanCnt=1:chanNum
	fprintf(fId,['set output "' outfile database sprintf('Polar%d.',chanCnt) 'pdf"\n']);
	fprintf(fId,'plot ');
	for frequCnt=1:frequNum
		frequInd = find(fftFrequs>=frequencies(frequCnt));
		frequInd = frequInd(1);
%plot "< perl -ne 'print join(\"\n\",split(/,/,$_)) if($.==2)' irBeampattern1.csv" w l
		fprintf(fId,plotString,frequInd-1,chanCnt,angleStep,frequencies(frequCnt));
		if(frequCnt~=frequNum)
			fprintf(fId,',\\\n');
		else
			fprintf(fId,'\n');
		end
	end
	fprintf(fId,'\n');
end
fclose(fId);

if doPlot
	%plot with gnuplot
	system(['cd ' outpath ' ; gnuplot ' plotfile database 'Map' plotfileExt]);
	system(['cd ' outpath ' ; gnuplot ' plotfile database 'Polar' plotfileExt]);
end

%generate latex polar plot file
for chanCnt=1:chanNum
	fId = fopen([outpath plotfile database 'Polar' sprintf('%d',chanCnt) '.tex'],'w');
	fprintf(fId,'\\documentclass{standalone}\n');
	fprintf(fId,'\\usepackage{tikz}\n');
	fprintf(fId,'\\usepackage{pgfplots}\n');
	fprintf(fId,'\\usepgfplotslibrary{polar}\n');
	fprintf(fId,'\\pgfplotsset{compat=1.5}\n');%needed?
	fprintf(fId,'\\begin{document}\n');
	fprintf(fId,'\\begin{tikzpicture}\n');
	fprintf(fId,'\t\\begin{polaraxis}[\n');
	fprintf(fId,'\t\t\t,ymin=0\n');
	fprintf(fId,'\t\t\t,ymax=%d\n',-levelMin);
	fprintf(fId,'\t\t\t,xmin=%d\n',angleStart);
	fprintf(fId,'\t\t\t,xmax=%d\n',angleEnd);
	fprintf(fId,'\t\t\t,ytick={%s}\n',yticksString);
	fprintf(fId,'\t\t\t,yticklabels={%s}\n',ytickLabelsString);
	fprintf(fId,'\t\t\t,legend pos=outer north east\n');
	%fprintf(fId,'\t\t\t,cycle list name=color list\n',angleEnd);
	fprintf(fId,'\t\t]\n');
	fprintf(fId,'\n');
	for frequCnt=1:frequNum
		fprintf(fId,['\t\t\\addplot+ [no markers,thick]\n'...
	   			'\t\t\ttable [col sep=comma,y index=%d]\n'...
				'\t\t\t{%s%s%sPolar%d.%s};\n'],frequCnt,outpath,outfile...
				,database,chanCnt,outfileExt);
		fprintf(fId,'\t\t\\addlegendentry{%d~Hz};\n',frequencies(frequCnt));
		fprintf(fId,'\n');
	end
	fprintf(fId,'\t\\end{polaraxis}\n');
	fprintf(fId,'\\end{tikzpicture}\n');
	fprintf(fId,'\\end{document}\n');
	fclose(fId);
end
