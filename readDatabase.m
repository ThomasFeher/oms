%convolutes impulse responses specified in databaseName and databaseParam with
		%signals specified in inSigNames
		%all returned signals are in matrices where each row is one channel and
		%each column is a time point
%@param databaseName string containing the name of the database
%@param inSigNames cell array with absolute or relative paths and file names
		%of the input signals or
		%an array contain sampled signal values with each row containing one
		%signal
%@param databaseParam struct array with fields 'distance' and 'angle' for each
		%source; it may also include the field 'level' that determains the
		%desired levels relative to each other in dB, if this field does not
		%exist, signal levels are not changed
%@param micsToLoad either string 'all' or array of numbers that describe the
		%microphones that shall be used. e.g. [2 3 4] to use second, third and
		%fourth microphone
%@param sampleRate sample rate in Hz
%@param databasesDir root dir for databases
%TODO possibility to change database directory via option parameter, as in
%twoChanMicHiRes
%TODO call all database read functions via string

function [outData signalSingle inputSignals FsSig geometry] = readDatabase...
		(databaseName,inSigNames,databaseParam,micsToLoad, sampleRate...
		,databasesDir)
	usage = ['usage: readDatabase(databaseName,inSigNames'...
	         '[,databaseParam,micsToLoad])'];
	if(nargin<2||nargin>6)
		error(usage);
	end
	if(nargin<5)
		sampleRate = 16000;
	elseif(~isscalar(sampleRate))
		error('sampleRate must be a scalar');
	end
	if(nargin<4)
		micsToLoad = 'all';
	end
	if(~ischar(databaseName))
		error('databaseName must be a character array');
	end
	if(~ischar(inSigNames)&&~iscell(inSigNames)&&~ismatrix(inSigNames))
		error(['inSigNames must be a character array (in case of one input '...
		       'file signal) or a cell array of character arrays (for '...
			   'multiple input files or an array, where each row is one '...
			   'input signal']);
	end
	if(ischar(inSigNames))
		sigNum = 1;
	elseif(iscell(inSigNames))
		sigNum = numel(inSigNames);
		if (sigNum==1) %cell array with only one elelment
			inSigNames = inSigNames{1};
		end
	else
		sigNum = size(inSigNames,1);
	end
	if(nargin>2)
		if(~isstruct(databaseParam))
			error('databaseParam must be a structure or structure array');
		end
		if(numel(databaseParam)~=sigNum)
			if(numel(databaseParam)==1)%use params for all channels
				databaseParam(1:sigNum) = struct(databaseParam);
			else
				error(sprintf(['number of input signals (%d) and database '...
				'parameters (%d) not matching'],sigNum,numel(databaseParam)));
			end
		end
	end

	%load impulse responses
	switch(databaseName)%TODO call function with this name directly (str2func)
	case('terminal')
		if(nargin<3) %use standard values
			databaseParam = struct('distance', 0.8,'angle',0,'room','refRaum');
		end
		[impulseResponses FsIR micNum geometry] = terminal(databaseParam);
	case({'2ChanMic' 'twoChanMic'})
		if(nargin<3) %use standard values
			databaseParam = struct('distance', 0.5,'angle',0,'room','refRaum');
		end
		[impulseResponses FsIR micNum geometry] = twoChanMic(databaseParam);
	case({'2ChanMicHiRes' 'twoChanMicHiRes'})
		if(nargin<3) %use standard values
			databaseParam = struct('distance', 0.5,'angle',0,'room','refRaum');
		end
		[impulseResponses FsIR micNum geometry]...
				= twoChanMicHiRes(databaseParam,sampleRate,databasesDir);
	case({'4MicArray' 'fourMicArray' '4Mic' 'fourMic'})
		if(nargin<3) %use standard values
			databaseParam = struct('distance', 4,'room','museum');
		end
		[impulseResponses FsIR micNum geometry] = fourMic(databaseParam...
		                                                 ,sampleRate);
	case({'3chanDMA' 'threeChanDMA'})
		if(nargin<3) %use standard values
			databaseParam = struct('distance', 4,'room','studio');
		end
		[impulseResponses FsIR micNum geometry] = ThreeChanDMA(databaseParam...
												  ,sampleRate,databasesDir);
	otherwise
		%try calling the database name as function
		databaseHandle = str2func(['load' databaseName]);
		options.params = databaseParam;
		options.dir = databasesDir;
		options.fs = sampleRate;
		[impulseResponses FsIR micNum geometry] = databaseHandle(options);
	end

	if(strcmp(micsToLoad,'all'))
		micsToLoad = [1:micNum];
	elseif(any(micsToLoad>micNum))
		wrongChan = micsToLoad(find(micsToLoad>micNum));
		error(sprintf('channel %d not available, array has only %d channels'...
				,wrongChan,micNum))
	else
		geometry = geometry(:,micsToLoad);
	end

	%load input signals
	maxLength = 0;
	if(ischar(inSigNames)||iscell(inSigNames))
		if(sigNum==1) %single signal
			[inputSignals FsSig] = loadSignal(inSigNames);
		else %multiple signals
			for cnt=1:sigNum
				[inputSignalsUnequal{cnt} Fs(cnt)] = loadSignal...
				                                             (inSigNames{cnt});
				if(~isvector(inputSignalsUnequal{cnt}))
					error(sprintf('input signal %s is not mono')...
					                                         ,inSigNames{cnt});
				end
				if(numel(inputSignalsUnequal{cnt})>maxLength)
					maxLength = numel(inputSignalsUnequal{cnt});
				end
			end
			if(~any(Fs(1)==Fs)) %not all samlerates are equal
				error('samplerate mismatch of input signals');
			else %store samplerate as scalar
				FsSig = Fs(1);
			end
		end
		if(FsIR~=FsSig)
			error(sprintf(['samplerate mismatch between input signals (%d) '...
			               'and impulse response database (%d)'],FsSig,FsIR));
		end
	else
		inputSignals = inSigNames;
		FsSig = FsIR;
	end
	%make input signals' length equal
	if(exist('inputSignalsUnequal','var'))
		%default: longest signal
		if ((~isfield(databaseParam,'length'))||(databaseParam(1).length == 0))
			sigLength = maxLength;
		elseif (databaseParam(1).length == -1)
			sigLength = numel(inputSignalsUnequal{1});
		else
			sigLength = FsSig * databaseParam(1).length;
		end
		disp(sprintf('sigLength = %d samples',sigLength));
		inputSignals = zeros(sigNum,sigLength);
		for sigCnt=1:sigNum
			thisLength = size(inputSignalsUnequal{sigCnt},2);
			if(thisLength<sigLength)
				zeropad = zeros(1,sigLength-thisLength);
				inputSignals(sigCnt,:) = [inputSignalsUnequal{sigCnt} zeropad];
		  else
			  inputSignals(sigCnt,:) = inputSignalsUnequal{sigCnt}(1:sigLength);
		  end
		end
	else
		sigLength = size(inputSignals,2);
	end

	%adjust signal levels if needed
	if(isfield(databaseParam,'level')&&sigNum>1)
		for sigCnt=2:sigNum
			level = databaseParam(sigCnt).level - databaseParam(1).level;
			inputSignals(sigCnt,:)=signalLeveler(inputSignals(1,:),...
			                                     inputSignals(sigCnt,:),level);
		end
	end

	%convolution
	irLength = size(impulseResponses{1},2);
	micNum = numel(micsToLoad);
	outputLength = irLength + sigLength - 1;
	outData = zeros(micNum,outputLength);
	for sigCnt=1:sigNum
		signalSingle{sigCnt} = zeros(micNum,outputLength);
		for micCnt=1:micNum
			signalSingle{sigCnt}(micCnt,:) =...
				conv(inputSignals(sigCnt,:),...
				impulseResponses{sigCnt}(micsToLoad(micCnt),:));
		end
		outData = outData + signalSingle{sigCnt};
	end
	%zeropad input signals to make them of equal length then output signals
	inputSignals = [inputSignals zeros(sigNum,irLength-1)];
end

function [inputSignal Fs] = loadSignal(sigName)
	if(~ischar(sigName))
		error('inSigNames contains a non charackter array member');
	end
	try
		[inputSignal Fs] = wavread(sigName);
	catch err
		disp(sprintf('error opening %s',sigName));
		rethrow(err)
	end
	inputSignal = inputSignal';
end

function [impulseResponses Fs micNum geometry] = terminal(param)
	if(~isfield(param,'distance'))
		error('required field "distance" missing');
	end
	if(~isfield(param,'angle'))
		error('required field "angle" missing');
	end
	if(~isfield(param,'room'))
		error('required field "room" missing');
	end

	databaseDir = '/erk/daten1/uasr-data-feher/audio/Impulsantworten/Terminal/';
	micNum = 4;
	geometry = [-0.12 -0.03 0.03 0.12;zeros(2,4)];
	roomlist = {'buero' 'hallraum' 'refRaum'};
	distanceList = [0.8 1.8];
	angleList = [0:15:90];
	srcNum = numel(param);
	maxSize = 0;

	for srcCnt=1:srcNum
		if(~any(strcmp(param(srcCnt).room,roomlist)))
			error(sprintf('wrong room name (%s) in databaseParam(%d).room',...
					param(srcCnt).room,srcCnt));
		end
		if(~any(param(srcCnt).distance==distanceList))
			error(sprintf('wrong distance (%f) in databaseParam(%d).distance',...
					param(srcCnt).distance,srcCnt));
		end
		if(~any(param(srcCnt).angle==angleList))
			error(sprintf('wrong angle (%d) in databaseParam(%d).angle',...
					param(srcCnt).angle,srcCnt));
		end

		[impulseResponse Fs] = wavread(sprintf('%s%s_%03d_%02d.wav',...
				databaseDir,param(srcCnt).room,param(srcCnt).distance*100,...
				param(srcCnt).angle));
		if(size(impulseResponse,1)>maxSize)
			maxSize = size(impulseResponse,1);
		end
		impulseResponses{srcCnt} = impulseResponse';
	end
	clear impulseResponse;

	%in the case of using different rooms for different sources, shorter impulse
	%responses must be zero padded
	for srcCnt=1:srcNum
		irSize = size(impulseResponses{srcCnt},2);
		if(irSize<maxSize)
			zeropad = zeros(micNum,maxSize-irSize);
			impulseResponses{srcCnt} = [impulseResponses{srcCnt} zeropad];
		end
	end
end

function [impulseResponses Fs micNum geometry] = twoChanMic(param)
	if(~isfield(param,'distance'))
		error('required field "distance" missing');
	end
	if(~isfield(param,'angle'))
		error('required field "angle" missing');
	end
	if(~isfield(param,'room'))
		error('required field "room" missing');
	end

	databaseDir = '/erk/daten1/uasr-data-feher/audio/Impulsantworten/2ChanMic/';
	micNum = 2;
	geometry = [-0.0085 0.0085;zeros(2,2)];
	roomlist = {'praktikum' 'studio' 'refRaum'};
	distanceList = {[0.5 1.5] 'n' 'w'};
	angleList = [0:30:180];
	srcNum = numel(param);
	maxSize = 0;

	for srcCnt=1:srcNum
		if(~any(strcmp(param(srcCnt).room,roomlist)))
			error(sprintf('wrong room name (%s) in databaseParam(%d).room',...
					param(srcCnt).room,srcCnt));
		end
		if(~any(param(srcCnt).distance==distanceList{1}))
			error(sprintf('wrong distance (%f) in databaseParam(%d).distance'...
			                                  ,param(srcCnt).distance,srcCnt));
		end
		distanceString = distanceList{find(param(srcCnt).distance...
		                                                 ==distanceList{1})+1};
		if(~any(param(srcCnt).angle==angleList))
			error(sprintf('wrong angle (%d) in databaseParam(%d).angle',...
					param(srcCnt).angle,srcCnt));
		end

		fileString = sprintf('%s%s/IR16kHz/%s%03d',databaseDir,...
				param(srcCnt).room,distanceString,param(srcCnt).angle);
		fileString1 = [fileString '_1' '.wav'];
		fileString2 = [fileString '_2' '.wav'];
		disp(['reading file: ' fileString1]);
		[impulseResponse1 Fs] = wavread(fileString1);
		disp(['reading file: ' fileString2]);
		[impulseResponse2 Fs] = wavread(fileString2);
		impulseResponse = [impulseResponse1 impulseResponse2];
		if(size(impulseResponse,1)>maxSize)
			maxSize = size(impulseResponse,1);
		end
		impulseResponses{srcCnt} = impulseResponse';
	end
	clear impulseResponse;

	%in the case of using different rooms for different sources, shorter impulse
	%responses must be zero padded
	for srcCnt=1:srcNum
		irSize = size(impulseResponses{srcCnt},2);
		if(irSize<maxSize)
			zeropad = zeros(micNum,maxSize-irSize);
			impulseResponses{srcCnt} = [impulseResponses{srcCnt} zeropad];
		end
	end
end

function [impulseResponses Fs micNum geometry] = twoChanMicHiRes(param,fs...
                                                                ,baseDir)
	if(nargin<2)
		fs = 16000;
	end
	if(~isfield(param,'distance'))
		error('required field "distance" missing');
	end
	if(~isfield(param,'angle'))
		error('required field "angle" missing');
	end
	if(~isfield(param,'room'))
		error('required field "room" missing');
	end

	databaseDir = fullfile(baseDir,'2ChanMicHiRes');
	micNum = 2;
	correctionCoeff = [0 2.66]; %correction coefficient per channel in dB
	geometry = [-0.0085 0.0085;zeros(2,2)];
	roomlist = {'studio' 'refRaum'};
	distanceList = {[0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1]...
			[005 010 015 020 030 040 050 075 100]};
	angleList = [0:15:345];
	srcNum = numel(param);
	maxSize = 0;
	switch(fs)
	case(16000)
		irDir = 'IR16kHz';
	case(48000)
		irDir = 'IR';
	otherwise
		error(sprintf(['Database \"2ChanMicHighRes\" does not support %d'...
		               'Hz sample rate'],fs));
	end

	for srcCnt=1:srcNum
		if(~any(strcmp(param(srcCnt).room,roomlist)))
			error(sprintf('wrong room name (%s) in databaseParam(%d).room'...
			                                      ,param(srcCnt).room,srcCnt));
		end
		if(~any(param(srcCnt).distance==distanceList{1}))
			error(sprintf('wrong distance (%f) in databaseParam(%d).distance'...
			                                  ,param(srcCnt).distance,srcCnt));
		end
		distance = distanceList{2}(find(param(srcCnt).distance==...
				distanceList{1}));
		if(param(srcCnt).angle >= 360)
			param(srcCnt).angle = param(srcCnt).angle...
					- 360*floor(param(srcCnt).angle/360);
		end
		if(~any(param(srcCnt).angle==angleList))
			error(sprintf('wrong angle (%d) in databaseParam(%d).angle'...
			                                     ,param(srcCnt).angle,srcCnt));
		end

		fileString = sprintf('%s/%s/%03d_%03d',param(srcCnt).room,irDir...
		                                      ,param(srcCnt).angle,distance);
		fileString = fullfile(databaseDir,fileString);
		fileString1 = [fileString '_1' '.wav'];
		fileString2 = [fileString '_2' '.wav'];

		disp(['reading file: ' fileString1]);
		[impulseResponse1 Fs] = wavread(fileString1);
		disp(['reading file: ' fileString2]);
		[impulseResponse2 Fs] = wavread(fileString2);
		impulseResponse = [impulseResponse1 impulseResponse2];
		if(size(impulseResponse,1)>maxSize)
			maxSize = size(impulseResponse,1);
		end
		impulseResponses{srcCnt} = impulseResponse';
	end
	clear impulseResponse;

	%in the case of using different rooms for different sources, shorter impulse
	%responses must be zero padded
	for srcCnt=1:srcNum
		irSize = size(impulseResponses{srcCnt},2);
		if(irSize<maxSize)
			zeropad = zeros(micNum,maxSize-irSize);
			impulseResponses{srcCnt} = [impulseResponses{srcCnt} zeropad];
		end
	end
end

function [impulseResponses Fs micNum geometry] = fourMic(param)
	if(~isfield(param,'distance'))
		error('required field "distance" missing');
	end
	if(isfield(param,'angle'))
		warning(['angle is ignored because database "fourMic" has no data'...
		         'for different angles']);
	end
	if(~isfield(param,'room'))
		error('required field "room" missing');
	end

	databaseDir = '/erk/daten1/uasr-data-feher/audio/Impulsantworten/4-Mic/';
	micNum = 4;
	geometry = [-0.12 -0.03 0.03 0.12;zeros(2,4)];
	roomlist = {'museum' 'praktikumsraum' 'studio' 'wohnzimmer'};
	distanceList = [0.2:0.2:4];
	angleList = [];
	srcNum = numel(param);
	maxSize = 0;

	for srcCnt=1:srcNum
		if(~any(strcmp(param(srcCnt).room,roomlist)))
			error(sprintf('wrong room name (%s) in databaseParam(%d).room'...
			                                      ,param(srcCnt).room,srcCnt));
		end
		if(~any(param(srcCnt).distance==distanceList))
			error(sprintf('wrong distance (%f) in databaseParam(%d).distance'...
			                                  ,param(srcCnt).distance,srcCnt));
		end

		[impulseResponse Fs]=wavread(sprintf('%simpulsantwort_%s_%01.1fm.wav'...
		              ,databaseDir,param(srcCnt).room,param(srcCnt).distance));
		if(size(impulseResponse,1)>maxSize)
			maxSize = size(impulseResponse,1);
		end
		impulseResponses{srcCnt} = impulseResponse';
	end
	clear impulseResponse;

	%in the case of using different rooms for different sources, shorter impulse
	%responses must be zero padded
	for srcCnt=1:srcNum
		irSize = size(impulseResponses{srcCnt},2);
		if(irSize<maxSize)
			zeropad = zeros(micNum,maxSize-irSize);
			impulseResponses{srcCnt} = [impulseResponses{srcCnt} zeropad];
		end
	end
end


%% /** 
%   * Load impulse responses for three channel differential microphone array  
%   */
function [impulseResponses Fs micNum geometry] = ThreeChanDMA(param,fs,baseDir)
	if(nargin<2)
		fs = 48000;
	end
	if(~isfield(param,'distance'))
		error('required field "distance" missing');
	end
	if(~isfield(param,'angle'))
		error('required field "angle" missing');
	end
	if(~isfield(param,'room'))
		error('required field "room" missing');
	end

	micNum = 3;

  %%FALSCH
	geometry = [0 0 0; 0 0 0; 0 0 0];

	roomlist = {'studio'};

	distanceList = {[0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.75 1]...
	                [005 010 015 020 030 040 050 075 100]};
	angleList = [15:15:360];
	srcNum = numel(param);
	maxSize = 0;

	databaseDir = fullfile(baseDir,'3ChanDMA/');
  
	if (fs == 48000)
		irDir = 'IR';
	elseif (fs == 16000)
		irDir = 'IR/16kHz';
	else
		error(sprintf(['Database \"3ChanDMA\" does not support %d'...
		               'Hz sample rate'],fs));
	end

	for srcCnt=1:srcNum
		if(param(srcCnt).angle == 0)
			param(srcCnt).angle = 360;      %fix for file naming
		end
		if(~any(strcmp(param(srcCnt).room,roomlist)))
			error(sprintf('wrong room name (%s) in databaseParam(%d).room'...
			                                      ,param(srcCnt).room,srcCnt));
		end
		if(~any(param(srcCnt).distance==distanceList{1}))
			error(sprintf('wrong distance (%f) in databaseParam(%d).distance'...
			                                  ,param(srcCnt).distance,srcCnt));
		end
		distance = distanceList{2}(find(param(srcCnt).distance ...
		                                                  == distanceList{1}));
		if(~any(param(srcCnt).angle==angleList))
			error(sprintf('wrong angle (%d) in databaseParam(%d).angle'...
			                                     ,param(srcCnt).angle,srcCnt));
		end

		fileString = sprintf( '%s%s/%s/%d_%03d' ...
		                                       ,databaseDir ...
		                                       ,param(srcCnt).room ...
		                                       ,irDir ...
		                                       ,param(srcCnt).angle ...
		                                       ,distance );

		[impulseResponse1 Fs] = wavread([fileString '_01M' '.wav']);
		[impulseResponse2 Fs] = wavread([fileString '_02M' '.wav']);
		[impulseResponse3 Fs] = wavread([fileString '_03M' '.wav']);

		impulseResponse = [impulseResponse1 impulseResponse2 impulseResponse3];
		if(size(impulseResponse,1)>maxSize)
			maxSize = size(impulseResponse,1);
		end
		impulseResponses{srcCnt} = impulseResponse';
	end
	clear impulseResponse;

	%in the case of using different rooms for different sources, shorter impulse
	%responses must be zero padded
	for srcCnt=1:srcNum
		irSize = size(impulseResponses{srcCnt},2);
		if(irSize<maxSize)
			zeropad = zeros(micNum,maxSize-irSize);
			impulseResponses{srcCnt} = [impulseResponses{srcCnt} zeropad];
		end
	end
end

function out = ismatrix(in)
	out = false;
	s = size(in);
	if(size(s)~=2)
		return
	end
	if(s(1)<1||s(2)<1)
		return
	end
	out = true;
end
