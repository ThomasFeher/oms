clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath('~/epstk/m');

options.doConvolution = true;
options.inputSignals = rand(9,20000);
options.irDatabaseSampleRate = 48000;
options.impulseResponses = struct('angle',0,...
		'distance',{0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1},'room','refRaum');
options.irDatabaseName = 'twoChanMicHiRes';
options.blockSize = 512;
options.timeShift = options.blockSize/2;

[result opt] = start(options);

%v = zeros(size(result.input.sigVecEval{1},2),1);
for cnt=1:9
	sigVec{cnt} = result.input.sigVecEval{cnt}(:,6:40,:);
	sigVecKugel{cnt} = squeeze(sigVec{cnt}(1,:,:) + sigVec{cnt}(2,:,:));
	sigVecAcht{cnt} = squeeze(sigVec{cnt}(1,:,:) - sigVec{cnt}(2,:,:));
	m(cnt,:) = mean(abs(sigVecKugel{cnt})./abs(sigVecAcht{cnt}));
	n(cnt,:) = abs(mean(angle(sigVecKugel{cnt})-angle(sigVecAcht{cnt})))/pi*180;
	o(cnt,:) = mean(abs((sigVecKugel{cnt})./(sigVecAcht{cnt})));
	%v = v + transp(squeeze(abs(sum(result.input.sigVecEval{cnt}(1,:,:),3))));
	for frequCnt=1:10%floor(numel(frequencies)/10)
		%dataString = sprintf('%04.2f nah: %02.1f %02.1f fern: %02.1f %02.1f'...
				%,frequencies(frequCnt)/1000,meanNah,varNah...
				%,meanFern,varFern);
		%disp(dataString);
	end
end

disp(squeeze(mean(abs(result.input.sigVecEval{1}(1,:,:)),3)));
symbList = {'plus.psd', 'star.psd', 'ring.psd', 'fring.psd', 'rect.psd',...
		'frect.psd', 'triaC.psd', 'ftriaC.psd', 'tria.psd', 'ftria.psd'};
eopen('/erk/tmp/feher/distance.eps');
eglobpar;
ePlotAreaWidth = 85;
ePlotAreaHeight = 50;
eYGridVisible = 1;
eYAxisWestScale = [0 0.1 1.4];
eXAxisSouthScale = [0 0.1 1];
eYAxisWesLabelText = '|p/v|';
eXAxisSouthLabelText = 'distance in m';
for cnt=1:numel(symbList)
	edsymbol(sprintf('s%d',cnt),symbList{cnt},0.25,0.25);
end
for cnt=(1:8)+3
	eplot([0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1],m(:,cnt),...
			sprintf('%5f Hz',opt.frequency(cnt)),sprintf('s%d',cnt-3));
	eplot([0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1],m(:,cnt));
end
eclose;
newbbox=ebbox(1);

eopen('/erk/tmp/feher/distanceAngle.eps');
eglobpar;
ePlotAreaWidth = 85;
ePlotAreaHeight = 50;
eYGridVisible = 1;
eYAxisWestLabelText = 'angle of Z(r,f) in degree';
eXAxisSouthLabelText = 'distance in m';
ePlotLegendPos = [90,40];
for cnt=1:numel(symbList)
	edsymbol(sprintf('s%d',cnt),symbList{cnt},0.25,0.25);
end
for cnt=(1:8)+3
	eplot([0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1],n(:,cnt),...
			sprintf('%3.0f Hz',opt.frequency(cnt)),sprintf('s%d',cnt-3));
	eplot([0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1],n(:,cnt));
end
eclose;
newbbox=ebbox(1);

eopen('/erk/tmp/feher/distanceComplex.eps');
eglobpar;
ePlotAreaWidth = 85;
ePlotAreaHeight = 50;
eYGridVisible = 1;
eYAxisWestLabelText = 'magnitude of Z(r,f)';
eXAxisSouthLabelText = 'distance in m';
ePlotLegendPos = [90,40];
for cnt=1:numel(symbList)
	edsymbol(sprintf('s%d',cnt),symbList{cnt},0.25,0.25);
end
for cnt=(1:8)+3
	eplot([0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1],o(:,cnt),...
			sprintf('%3.0f Hz',opt.frequency(cnt)),sprintf('s%d',cnt-3));
	eplot([0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1],o(:,cnt));
end
eclose;
newbbox=ebbox(1);
