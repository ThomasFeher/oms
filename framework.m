function [results options] = framework(options)
tic
more off;

%%%%%init%%%%%
%get path of oms framework
omsDir = fileparts(mfilename('fullpath'));
%create result dir
resultDir = options.resultDir;
if(~exist(resultDir,'dir'))
	mkdir(resultDir);
end
options = generateExperimentID(options);
fn_structdisp('options');%display options

results = struct(); %empty struct to put all results in
blockSize = options.blockSize;
if(blockSize<1)
	error(sprintf('options.blockSize must be bigger than 0, but is %d',...
			blockSize));
end
timeShift = options.timeShift;
zeroPads = options.zeroPads;
iterICA = options.iterICA;
startFrequ = options.startFrequ;
c = options.c;
fAvNum = options.fAvNum;
tAvNum = options.tAvNum;

%test geometry setting
%TODO more testing
if(any(size(options.geometry)==1))%vector, treat as x-coordinate
	options.geometry = [options.geometry;zeros(2,numel(options.geometry))];
elseif(size(options.geometry,1)~=3)%no three coordinates given, throw error
	error('geometry must contain 3 rows with the three coordinates');
end

if(options.doConvolution)
	%convolution;
	disp('Convolving signals...');
	[signal signalEval signalOrig fs geometry] = readDatabase(...
			options.irDatabaseName,options.inputSignals,...
			options.impulseResponses,options.irDatabaseChannels,...
			options.irDatabaseSampleRate,options.irDatabase.dir);
	options.geometry = geometry;
	options.fs = fs;
	srcNum = numel(signalEval);
	options.srcNum = srcNum;
	results.input.signalEval = signalEval;
	%store audio files in temp dir
	audioFileLength = size(signal,2);
	if(options.doEvalPeass)
		for srcCnt=1:srcNum 
			wavName = sprintf('%ssignalEval%d.wav',options.tmpDirExp,srcCnt);
			wavwrite(signalEval{srcCnt}'/...
					max(max(abs(signalEval{srcCnt}))),fs,wavName);
		end
		wavName = sprintf('%ssignalOrig.wav',options.tmpDirExp);
		wavwrite(signalOrig'/max(max(abs(signalOrig))),fs,wavName);
	end
	geometryX = geometry(1,:);
	geometryY = geometry(2,:);
	geometryZ = geometry(3,:);
	options.geometry = geometry;
else
	disp('Loading signals...');
	if(iscell(options.inputSignals))%names of audio files
		sigNum = numel(options.inputSignals);%get number of input signals
		for sigCnt=1:sigNum%read all signals
			try
				[signal(sigCnt,:) fs] = wavread(options.inputSignals{sigCnt});
			catch err
				disp('error while reading audio input.possible causes:');
				disp('- input file has more than one channel');
				disp('- input files have different lengths');
				rethrow(err);
			end
			%store sample rate TODO check for equal sample rates
			disp(sprintf('adjusting sample rate to %d',fs));
			options.fs = fs;
		end
		clear sigNum;
	elseif(isnumeric(options.inputSignals))%signals given as value arrays
		signal = options.inputSignals;%use these as input signals
		%get their sample rate
		%if(isfield(options,'fs'))
			fs = options.fs;
		%else
			%error('samplerate must be specified in options.fs');
		%end
	elseif(ischar(options.inputSignals))%only one signal given as file name
		try
			[signal fs] = wavexread(options.inputSignals);
		catch err
			[signal fs] = wavread(options.inputSignals);
		end
		signal = signal.';
		%set arbitrary geometry
		options.geometry = zeros(3,size(signal,1));
		options.fs = fs;%get sample rate
	else%none of standard input formats worked
		error('can not handle options.inputSignals');
	end
	geometry = options.geometry;
	geometryX = geometry(1,:);
	geometryY = geometry(2,:);
	geometryZ = geometry(3,:);
end
results.input.signal = signal;%store input signals

options.sigNum = size(signal,1);%get number of input signals
sigNum = options.sigNum;
if(sigNum~=size(geometry,2))
	error(sprintf([['number of signals (%d) and number of microphones in ']...
			['geometry (%d) are not equal']],sigNum,size(geometry,2)));
end
blockSizeZeroPads = 2*zeroPads + blockSize;%overall block size
options.blockSizeZeroPads = blockSizeZeroPads;
frequNum = blockSizeZeroPads/2+1;%number of frequency bins in frequency domain
options.frequNum = frequNum;
options.frequency = linspace(0,fs/2,frequNum);%frequency values
frequency = options.frequency;
%%%%%init%%%%%

%%%%%beamforming - weighting matrix synthesis%%%%%
if(options.doBeamforming)
	if(options.beamforming.doNoProcess)
		if(isscalar(options.beamforming.noProcess.frequNum))
			options.frequNum = options.beamforming.noProcess.frequNum;
			frequNum = options.frequNum;
			options.frequency =...
				logspace(log10(options.beamforming.noProcess.frequMin)...
				,log10(options.beamforming.noProcess.frequMax)...
				,options.frequNum);
			results.frequency = options.frequency;
		elseif(isvector(options.beamforming.noProcess.frequNum))
			if(iscolumn(options.beamforming.noProcess.frequNum))
				options.frequency = options.beamforming.noProcess.frequNum.';
			else
				options.frequency = options.beamforming.noProcess.frequNum;
			end
			frequNum = numel(options.frequency);
			options.frequNum = frequNum;
		else
			disp('size(options.beamforming.noProcess.frequNum):');
			disp(size(options.beamforming.noProcess.frequNum));
			error(['options.beamforming.noProcess.frequNum must be a scalar'...
				   'or a vector']);
		end
	end
	if(options.beamforming.doWeightMatSynthesis)
		disp('synthesizing weight matrix...')
		[weightMatSynthResults] = weightMatSynth(options);
		results.weightMatSynth = weightMatSynthResults;
		options.beamforming.weights = weightMatSynthResults.W;
	else%include beamforming.weights, beamforming.amp and beamforming.delays,
				%if given or just use equal weights
		W = options.beamforming.weights;%weights in frequency domain
		delays = options.beamforming.delays;%time domain delays
		amp = options.beamforming.amp;%amplification of each microphone
		noDelay = true;
		noWeight = true;
		noAmp = true;
		%time domain delays
		if(all(size(delays)==[sigNum,1]))%delays given as column vector
			W = W.';%transpose
		end
		if(all(size(delays)==[1,sigNum]))%delays given as row vector
			disp('transforming delays to frequency domain...');
			delays = exp(-i*2*pi*delays.'*options.frequency);
			noDelay = false;
		else%no valid delays given
			disp('no valid time domain delays found');
			delays = zeros(sigNum,frequNum);%all delays are zero
		end
		if(all(size(W)==[sigNum,frequNum]))%no weights given, set all equal
			disp('using frequency domain weights');
			noWeight = false;
		else
			disp(['no valid frequency domain weights found']);
			W=ones(sigNum,frequNum)/sigNum;
		end
		W = W + delays;%add delays to weights
		%multiply with amplification weights, if given
		if(all(size(amp)==[sigNum,1]))%amplifications given as column vector
			amp = amp.';%transpose
		end
		if(all(size(amp)==[1,sigNum]))%amplifications given as row vector
			disp('adding amplifications to microphones...');
			amp = amp.' * ones(1,frequNum);
			W = W .* amp;
			noAmp = false;
		else
			disp('no valid amplifications found');
		end
		options.beamforming.weights = W;
		if(noWeight&noDelay&noAmp)
			disp('all microphones equally weighted');
		end
	end
	if(options.beamforming.doBeampattern)
		beampatternResults = beampattern(options);
		results.beamforming.beampattern = beampatternResults;
		results.beamforming.beampattern.teta =...
	   			options.beamforming.beampattern.teta;
		results.beamforming.beampattern.phi =...
				options.beamforming.beampattern.phi;
	end
end
%%%%%beamforming - weighting matrix synthesis%%%%%

%%%%%speech recognition%%%%%
if(options.doSpeechRecognition)
	sigDir = options.speechRecognition.sigDir;
	sigDirRemote = options.speechRecognition.sigDirRemote;
	resultDirRemote = options.speechRecognition.resultDirRemote;
	uasrPath = options.speechRecognition.uasrPath;
	uasrDataPath = options.speechRecognition.uasrDataPath;
	tmpDir = options.tmpDir;
	model = options.speechRecognition.model;
	db = options.speechRecognition.db;
	disp('speech recognition...');
	logFilename2 = fullfile(resultDir,'logExtern.txt');%copy external log file
								%back to original machine with this file name

	% expand heading tilde and dot, UASR seems to not like it
	if(~isMatlab())%only possible in Octave TODO find Matlab function
		uasrPath = tilde_expand(uasrPath);
		uasrDataPath = tilde_expand(uasrDataPath);
		tmpDir = tilde_expand(tmpDir);
		sigDir = tilde_expand(sigDir);
	end
	uasrPath = dot_expand(uasrPath);
	uasrDataPath = dot_expand(uasrDataPath);
	tmpDir = dot_expand(tmpDir);
	sigDir = dot_expand(sigDir);

	if(options.speechRecognition.doRemote&&...
			~options.speechRecognition.doGetRemoteResults)
		%TODO make remote host (eakss1) a config key
		logFilename = fullfile(resultDirRemote,'log.txt');%log speech recognition here
		disp('copying files to remote machine...');
		recogName1 = fullfile(omsDir,'speechRecognizer.pl');
		recogName2 = fullfile(omsDir,'FileSemaphore.pm');
		recogNameRemote = fullfile(resultDirRemote,'speechRecognizer.pl');
		recogNameRemotePath = fullfile(resultDirRemote,'/');
		system(['ssh eakss1 mkdir -p ' resultDirRemote]);%create log dir on
													%remote machine
		system(['ssh eakss1 mkdir -p ' sigDirRemote]);%create sig dir on remote
													%machine
		%copy data files
		system(['scp ' sigDir '/*.* eakss1://' sigDirRemote],'-echo');
		%copy recognizer script
		system(['scp ' recogName1 ' ' recogName2 ' eakss1://' recogNameRemotePath],'-echo');
		disp(['running UASR on remote machine, see local logfile ' logFilename]);
		systemCall = ['ssh eakss1 "nohup perl -I' recogNameRemotePath  ' ' recogNameRemote ' ' sigDirRemote ' '...
			resultDirRemote ' ' db ' ' model ' >' logFilename ' 2>&1 </dev/null & "'];
		disp(systemCall);
		system(systemCall);
		results.speechRecognition = speechRecogGetResults();
	elseif(options.speechRecognition.doGetRemoteResults)
		logFilename = fullfile(resultDirRemote,'log.txt');%log speech recognition here
		disp('copying result files from remote machine...');
		disp(['scp eakss1://' logFilename ' ' logFilename2]);
		system(['scp eakss1://' logFilename ' ' logFilename2],'-echo');
		%read file
		fid = fopen(logFilename2,'r');
		lines = [];
		while ~feof(fid)
			line = fgets(fid);
			lines = [lines line];
		end
		fclose(fid);
		%get results from file
		results.speechRecognition = speechRecogGetResults(lines,db);
	else
		logFilename = fullfile(resultDir,'log.txt');%log speech recognition here
		results.speechRecognition = speechRecognizer(sigDir, tmpDir, db ...
                                                    ,model, uasrPath ...
                                                    ,uasrDataPath);
   end%do remote
end
%%%%%speech recognition%%%%%

%%%%%to frequency domain%%%%%
%sigVec: (signal,block,frequency)
%blockMat: (signal,block,time)
sigVecFileName = createFdFileName(options,sigNum);
if(exist(sigVecFileName,'file'));%did calc in a previous experiment
	disp('Loading frequency domain signals...');
	load(sigVecFileName);
else%need to do the calculation
	disp('Calculating frequency domain signals...');
	%sigVec: (signal,block,frequency)
	%blockMat: (signal,block,time)
	[sigVec blockMat blockNum blockTime] =...
			toFrequDomain(signal,blockSize,timeShift,zeroPads,fs);
	if(options.doConvolution)
		for srcCnt=1:srcNum
			[sigVecEval{srcCnt} blockMatEval{srcCnt}] =...
					toFrequDomain(signalEval{srcCnt},blockSize,timeShift,...
					zeroPads,fs);
		end
	end
	%if(~strcmp(inSigName,'noFile')&&options.doFdStore)
	if(options.doFdStore)
		if(options.doConvolution)
			save(sigVecFileName,'sigVec','blockMat','blockNum','blockTime',...
					'sigVecEval','blockMatEval');
		else
			save(sigVecFileName,'sigVec','blockMat','blockNum','blockTime');
		end
	end
end
%store results
options.blockNum = blockNum;
results.blockNum = blockNum;
results.blockTime = blockTime;
results.input.sigVec = sigVec;
results.input.blockMat = blockMat;
results.last.sigVec = sigVec;
results.last.blockMat = blockMat;
if(options.doConvolution)
	results.input.sigVecEval = sigVecEval;
	results.input.blockMatEval = blockMatEval;
	results.last.sigVecEval = sigVecEval;
	results.last.blockMatEval = blockMatEval;
end
%%%%%to frequency domain%%%%%

%time-frequency-domain histogram
%{
figure(1);clf;
subplot(411)
[tfhist centers] = tfHist(sigVec(2,:,10),sigVec(3,:,10),...
	abs(geometryX(3)-geometryX(2)),c,frequency(10));
disp([min(centers) max(centers)]);
plot(centers*180/pi,tfhist);
title(frequency(10))
subplot(412)
[tfhist centers] = tfHist(sigVec(2,:,20),sigVec(3,:,20),...
	abs(geometryX(3)-geometryX(2)),c,frequency(20));
plot(centers*180/pi,tfhist);
title(frequency(20))
%phi = angle(sigVec(2,:,10).*conj(sigVec(3,:,10)))/(2*pi*frequency(10));
%disp([min(phi) max(phi)]);
%plot(phi);
subplot(413)
[tfhist centers] = tfHist(sigVec(2,:,30),sigVec(3,:,30),...
	abs(geometryX(3)-geometryX(2)),c,frequency(30));
plot(centers*180/pi,tfhist);
title(frequency(30))
%phi = angle(sigVec(2,:,10)./sigVec(3,:,10))/(2*pi*frequency(10));
%disp(([min(phi) max(phi)]*c/abs(geometryX(3)-geometryX(2))));
%plot(phi);
subplot(414)
[tfhist centers] = tfHist(sigVec(2,:,40),sigVec(3,:,40),...
	abs(geometryX(3)-geometryX(2)),c,frequency(40));
plot(centers*180/pi,tfhist);
title(frequency(40))
%plot(acos(angle(sigVec(2,:,10)./sigVec(3,:,10))*c/(2*pi*frequency(10)*...
	%abs(geometryX(3)-geometryX(2)))));
%plot(asin(angle(sigVec(2,:,10).*conj(sigVec(3,:,10)))*c/(2*pi*frequency(10)*...
	%abs(geometryX(3)-geometryX(2)))));
%plot(asin(phi*c/abs(geometryX(3)-geometryX(2))));
%}

%%%%%%ADMA%%%%%%
if(options.doADMA)
	disp('adma processing ...');
	%keyboard

	%export raw cardioid or eight signals
	if(options.adma.returnCardioids...
	 ||options.adma.returnEights...
	 ||options.adma.doIcaBatch)
		[sigFullFd frequFull] = fftAndFrequ(signal,fs);
		[cardioidsFd eightsFd] = admaBuildCardioids(sigFullFd,frequFull...
					,options.adma.d,options.c,options.adma.doEqualization);
		results.adma.cardioids = ifft(cardioidsFd.').';
		results.adma.eights = ifft(eightsFd.').';
	end

	if(options.adma.doIcaBatch)
		%if(options.doTdRestore)
			%warning(['Result of batch ICA will be overwritten due to ' ...
					 %'<doTdRestore> key! Please set "options.doTdRestore ' ...
					 %'= false", or use result from "results.adma.icaBatch"']);
		%end
		unmixMat = FastICA(results.adma.cardioids,100);
		results.adma.icaBatch = unmixMat * results.adma.cardioids;	
		%results.signal = results.adma.icaBatch;
		if (options.doConvolution) % we don't know the correct signal yet, so
			results.eval.sigVecEval = sigVecEval; % bypass evaluation stage
		end 
	else
		%initialize parameter
		options.adma.oldMask = -1;%TODO throw out of options struct
		options.adma.last_theta = NaN;%TODO throw out of options struct

		%preallocate arrays
		sigVecNew = zeros(size(sigVec));
		sigVecCard = zeros(size(sigVec));
		if(options.doConvolution)
			for srcCnt=1:srcNum
				sigVecEvalNew{srcCnt} = zeros(size(sigVecEval{srcCnt}));
			end
		end

		%loop blocks
		for (blockCnt=1:blockNum) %process blockwise
			sigVecProc = squeeze(sigVec(:,blockCnt,:)); %current processing block

			[sigVecProc adma_opt sigVecCard(:,blockCnt,:)] = adma(sigVecProc...
																  ,frequency...
																  ,fs...
																  ,options.adma...
																  ,options.c);

			options.adma.oldMask = adma_opt.newMask;
			options.adma.last_theta = adma_opt.theta1;

			sigVecNew(:,blockCnt,:) = sigVecProc;

			results.adma.opt(blockCnt) = adma_opt;
			sigVecNew(:,blockCnt,:) = sigVecProc;

			%Process single Signal for SNR evaluation
			if(options.doConvolution)
				%process evaluation signals blockwise
				for srcCnt=1:srcNum
					%current processing block
					sigVecEvalProc = squeeze(sigVecEval{srcCnt}(:,blockCnt,:));
					adma_opt.findMax = false;%use angles determinded by regular
					adma_opt.findMin = false;%signal pass
					[sigVecEvalProc Evalopt] = adma(sigVecEvalProc, ...
													frequency, ...
													fs, ...
													adma_opt,...
													options.c);
					results.adma.EvalOpt(srcCnt,blockCnt) = Evalopt;
					sigVecEvalNew{srcCnt}(:,blockCnt,:) = sigVecEvalProc;
				end
			end
		end

		sigVec = sigVecNew;
		clear sigVecNew;
		results.adma.sigVec = sigVec; 
		results.adma.sigVecCard = sigVecCard;
		if (options.doConvolution)
			sigVecEval = sigVecEvalNew;
			clear sigVecEvalNew;
			results.eval.sigVecEval = sigVecEval;
		end 
	end % options.adma.doIcaBatch
end 
%%%%%%ADMA%%%%%%

%%%%%Beamforming%%%%%
if(options.doBeamforming)
	disp('beamforming...');
	sigVecNew = zeros(size(sigVec));
	for(blockCnt=1:blockNum)
		sigVecNew(1,blockCnt,:) = beamformProcessing(options,...
				squeeze(sigVec(:,blockCnt,:)),results.weightMatSynth.W);
	end
	sigVec = sigVecNew;
	clear sigVecNew;
	results.beamforming.sigVec = sigVec;
end
%%%%%Beamforming%%%%%

%%%%%Twin Mic%%%%%
if(doTwinMic(options))
	disp('Twin Mic Processing...');
	sigVecNew = zeros(size(sigVec));
	if(options.doConvolution)
		for srcCnt=1:srcNum
			sigVecEvalNew{srcCnt} = zeros(size(sigVecEval{srcCnt}));
		end
	end
	maskBf.previous = []; %initialize mask for beamforming
	maskDf.previous = []; %initialize mask for distance filter
	coeffWf.previous = []; %initialize coefficients for Wiener filter
	coeffNS.previous = []; %initialize coefficients for null steering
	%initialize array for estimatet null steering angles (NLMS and ICA)
	results.twinMic.nullSteering.angle = cell(blockNum,1);
	%results.twinMic.nullSteering.angle  = zeros(blockNum,1);
	for(blockCnt=1:blockNum) %process blockwise
		sigVecProc = squeeze(sigVec(:,blockCnt,:)); %current processing block
		if(options.doDma)
			sigVecProc = dma(options,sigVecProc);
		elseif(options.doTwinMicNullSteering)
			[sigVecProc coeffNS.previous] = twinMicNullSteering(options,...
					sigVecProc,squeeze(blockMat(:,blockCnt,:)),coeffNS);
			%store angle progression
			results.twinMic.nullSteering.angle{blockCnt} = coeffNS.previous;
		elseif(options.doTwinMicBeamforming&&options.doDistanceFiltering)
			[noi maskBf.previous] = twinMicBeamformer(options,...
					sigVecProc,maskBf);
			[noi maskDf.previous] = distanceFilter(options,...
					sigVecProc,maskDf);
			sigVecProc(2,:) = sigVecProc(1,:) + sigVecProc(2,:);
			sigVecProc(1,:) = sigVecProc(1,:) .* ...
					(maskBf.previous&maskDf.previous);
		elseif(options.doTwinMicBeamforming)
			[sigVecProc maskBf.previous] = twinMicBeamformer(options,...
					sigVecProc,maskBf);
		elseif(options.doDistanceFiltering)
			[sigVecProc maskDf.previous] = distanceFilter(options,...
					sigVecProc,maskDf);
		elseif(options.doTwinMicWienerFiltering)
			[sigVecProc coeffWf.previous] = twinMicWienerFilter(options,...
					sigVecProc,coeffWf);
		end
		sigVecNew(:,blockCnt,:) = sigVecProc;
		if(options.doConvolution)
			%process evaluation signals blockwise
			for srcCnt=1:srcNum
				%current processing block
				sigVecEvalProc = squeeze(sigVecEval{srcCnt}(:,blockCnt,:));
				if(options.doTwinMicNullSteering)
					sigVecEvalProc = twinMicNullSteering(options,...
							sigVecEvalProc,...
							squeeze(blockMatEval{srcCnt}(:,blockCnt,:)),...
							coeffNS);
				elseif(options.doTwinMicBeamforming&&options.doDistanceFiltering)
					sigVecEvalProc(2,:) = sigVecEvalProc(1,:) +...
							sigVecEvalProc(2,:);
					sigVecEvalProc(1,:) = sigVecEvalProc(1,:) .* ...
							(maskBf.previous&maskDf.previous);
				elseif(options.doTwinMicBeamforming)
					sigVecEvalProc = twinMicBeamformer(options,...
							sigVecEvalProc,maskBf.previous);
				elseif(options.doDistanceFiltering)
					sigVecEvalProc = distanceFilter(options,...
							sigVecEvalProc,maskDf.previous);
				elseif(options.doTwinMicWienerFiltering)
					sigVecEvalProc = twinMicWienerFilter(options,...
							sigVecEvalProc,coeffWf.previous);
				end
				sigVecEvalNew{srcCnt}(:,blockCnt,:) = sigVecEvalProc;
			end
		end
	end
	%make processed signal (sigVecNew) input signal for following algorhithms
		%(sigVec), same for evaluation signals
	sigVec = sigVecNew;
	clear sigVecNew;
	results.twinMic.sigVec = sigVec;
	results.last.sigVec = sigVec;
	if(options.doConvolution)
		sigVecEval = sigVecEvalNew;
		clear sigVecEvalNew;
		results.twinMic.sigVecEval = sigVecEval;
		results.last.sigVecEval = sigVecEval;
	end
end
%store result of complete twin mic processing chain
%results.twinMic.sigVec = results.last.sigVec;
%if(options.doConvolution)
	%results.twinMic.sigVecEval = results.last.sigVecEval;
%end
%%%%%Twin Mic%%%%%

%%%%%ICA%%%%%
if(options.doFDICA)
	icaResults = ica(options,results);
	sigVec = icaResults.postproc.sigVec;
	sigNum = size(sigVec,1);
	results.ica = icaResults;
	if(options.doConvolution)
		sigVecEval = icaResults.postproc.sigVecEval;
	end
	clear icaResults;
end
%%%%%ICA%%%%%

%%%%%to time domain%%%%%
if(options.doTdRestore)
	signalResult = ...
		toTimeDomain(sigVec,sigNum,blockSize,timeShift,zeroPads,blockNum);
	sigLength = size(results.input.signal,2);
	sigProcessedLength = size(signalResult,2);
	if(sigProcessedLength>=sigLength)
		doCut = true;
		results.signal = signalResult(:,1:sigLength);
	else
		doCut = false;
		diff = sigLength - sigProcessedLength;
		results.signal = [signalResult zeros(sigNum,diff)];
	end
	if(options.doConvolution)
		for srcCnt=1:srcNum
			signalEvalResult{srcCnt} = toTimeDomain(sigVecEval{srcCnt},sigNum,...
					blockSize,timeShift,zeroPads,blockNum);
			if(doCut)
				results.signalEval{srcCnt}=signalEvalResult{srcCnt}(:,1:sigLength);
			else
				results.signalEval{srcCnt} =...
						[signalEvalResult{srcCnt} zeros(sigNum,diff)];
			end
		end
	end
end
%%%%%to time domain%%%%%

if(options.doConvolution&options.doEval)
	results.eval = evaluate(options,results);
end

toc

%check if twin mic processing is switched on
function ret = doTwinMic(options)
ret = false;
if(options.doDma...
	|options.doDistanceFiltering...
	|options.doDistanceGate...
	|options.doTwinMicBeamforming...
	|options.doTwinMicNullSteering...
	|options.doTwinMicWienerFiltering)
	ret = true;
end

%TODO create hash of filename and store file with the hash as name instead of
%the generated name. this prevents awfull long filenames that could get too
%long to write
function sigVecFileName = createFdFileName(options,sigNum)
if(iscell(options.inputSignals))
	inSigName = strcat(options.inputSignals{:});
elseif(ischar(options.inputSignals))
	inSigName = options.inputSignals;
else%signal is given as array, we can't check whether we processed it before
	sigVecFileName = 'noFile';
	options.doFdStore = false;
	return
end
inSigName = regexprep(inSigName,{'/','\.'},'_');
%disp(inSigName);
sigVecFileName = sprintf('%s_%d_%d_%d_%d_%d_%d',...
							inSigName,...
							sigNum,...
							options.blockSize,...
							options.timeShift,...
							options.zeroPads,...
							options.fs,...
							options.doConvolution);
if(options.doConvolution)%append convolution information
	sigVecFileName = strcat(sigVecFileName,'_');
	%get field names of options.impulseResponses struct
	irFieldNames = fieldnames(options.impulseResponses);
	for irCnt=1:numel(irFieldNames)
		%get field name
		%keyboard
		%irFieldName = options.impulseResponses.(irFieldNames{irCnt})
		%add field name to file name
		sigVecFileName = strcat(sigVecFileName,irFieldNames{irCnt},'_');
		%get field content
		fieldContent = options.impulseResponses.(irFieldNames{irCnt});
		%iterate over field content and add each element to file name
		for eleCnt=1:numel(options.impulseResponses)
			element = options.impulseResponses(eleCnt).(irFieldNames{irCnt});
			%keyboard
			%add field content
			if(ischar(element))
				sigVecFileName = sprintf('%s%s_',sigVecFileName,...
						element);
			elseif(isnumeric(element))
				sigVecFileName = sprintf('%s%d_',sigVecFileName,...
						element);
			else
				error(['unknown field type while generating tmp file' ...
					   ' name for frequency domain data']);
			end
		end
	end
	sigVecFileName = sprintf('%s%s',sigVecFileName,options.irDatabaseName);
end
sigVecFileName = [fullfile(options.tmpDir,sigVecFileName) '.mat'];
