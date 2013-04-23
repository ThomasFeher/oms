%stores loaded (or convolved) signals in their frequency domain representation
%in the temp folder when this signal already exists, this one is immediately
%loaded instead of loading the time domain signal (and convoluting) and
%transforming it
defaultOptions.doFdStore = false;
%restore time domain signal after processing in frequency domain
defaultOptions.doTdRestore = false;
defaultOptions.doEval = false;
defaultOptions.doEvalStd = false;
defaultOptions.doEvalPeass = false;

%%%%%logging%%%%%
defaultOptions.doLogfile = false;
defaultOptions.logIdDigits = 6;
%%%%%logging%%%%%

%%%%%misc%%%%%
defaultOptions.c = 340;
defaultOptions.debug = false;%only used for debugging
%%%%%misc%%%%%

%%%%%input signals%%%%%
%if false, files given in 'inputSignals' are used, otherwise these files are
		%convolved with the database impulse responses
defaultOptions.doConvolution = false;
defaultOptions.inputSignals = ones(2,10);
defaultOptions.fs = 16000;
defaultOptions.irDatabaseName = 'terminal';%available databases: 'terminal',
											%'twoChanMic', 'twoChanMicHiRes',
											%'fourMic','threeChanDMA'
defaultOptions.irDatabaseSampleRate = 16000;
defaultOptions.irDatabaseChannels = 'all'; % = [2 3];
defaultOptions.impulseResponses =...
		struct('angle',{0 90},'distance',0.8,'room','refRaum');
%%%%%input signals%%%%%

%%%%%time-frequency-domain conversion%%%%%
defaultOptions.blockSize = 128;
defaultOptions.timeShift = 60;
%sets 'zeroPads' zeros bevore AND after the block, so blockSize becomes 2x
%zeroPads + blockSize
defaultOptions.zeroPads = 0;
%%%%%time-frequency-domain conversion%%%%%

%%%%%Twin Microphone%%%%%
%TODO output similar to ADMA
%differential microphone array with 2 omnidirectional microphones:
defaultOptions.doDma = false;
defaultOptions.doDistanceFiltering = false;
defaultOptions.doDistanceGate = false;%TODO implement
defaultOptions.doTwinMicBeamforming = false;
defaultOptions.doTwinMicNullSteering = false;
defaultOptions.doTwinMicWienerFiltering = false;
defaultOptions.dma.angle = 90;%angle of zero sensitivity in degree
%ratio between power of sphere and figure eight signals,used to determine
		%the distance
defaultOptions.distanceFilter.threshold = 1.0;
defaultOptions.distanceFilter.update = 0.7;
%distance filter operates only below this value in Hz:
defaultOptions.distanceFilter.cutoffFrequencyHigh = 800;
defaultOptions.distanceFilter.cutoffFrequencyLow = 100;
defaultOptions.distanceFilter.withGate = false;
defaultOptions.distanceGate.threshold = 0.7;%[0..1]
%beam width in degree, '30' corresponds to: -15 to 15 degree
defaultOptions.twinMic.beamformer.angle = 30;
defaultOptions.twinMic.beamformer.update = 1;
defaultOptions.twinMic.nullSteering.algorithm = 'fix'; %'fix','NLMS','ICA'
defaultOptions.twinMic.nullSteering.angle = 90; %in degree, only for fix algo
defaultOptions.twinMic.nullSteering.mu = 0.01; %learning rate, only NLMS!
defaultOptions.twinMic.nullSteering.alpha = 0; %only NLMS!
defaultOptions.twinMic.nullSteering.update = 0.1; %only ICA!
defaultOptions.twinMic.nullSteering.iterations = 1;
defaultOptions.twinMic.wienerFilter.update = 1;
%%%%%Twin Microphone%%%%%

%%%%%beamforming%%%%%
defaultOptions.doBeamforming = false;
defaultOptions.beamforming.doNoProcess = false;%no processing, just calculate
												%weights and pattern
defaultOptions.beamforming.doGeometrySynthesis = false;%TODO implement (see beamformer.m)
defaultOptions.beamforming.doWeightMatSynthesis = false;
defaultOptions.beamforming.weightMatSynthesis.angle = 0;%0 is perpendicular to
							%microphone axis (only x-coords)
defaultOptions.beamforming.doBeampattern = false;
defaultOptions.beamforming.beampattern.phi = [-90:90];%angle phi in degree
defaultOptions.beamforming.beampattern.teta = [-90:90];%angle teta in degree
defaultOptions.beamforming.doWng = false;%calculate white noise gain
defaultOptions.beamforming.wng.phi = 0;
defaultOptions.beamforming.wng.teta = 0;
defaultOptions.beamforming.delays = 0;%delays in time domain, will be added to
										%weights and amp
defaultOptions.beamforming.weights = 0;%if vector and size equals number of
									%microphones:
									%weights are delays in time domain
									%if matrix of size of number of microphones
									%times number of frequencies: weights
									%are frequency domain coefficients
									%else: ignored
									%problem: if evaluating only one frequency,
									%its impossible to distinguish
defaultOptions.beamforming.amp = 1;%if weights given as time domain delays this
									%can provide additional amplification for
									%microphone if given as a vector
%array geometry: [x1 x2 ... xN;y1 y2 ... yN;z1 z2 ... zN]
		%is set automatically when reading input data from a database
defaultOptions.geometry = [-0.1 0.1;0 0;0 0];
%defaultOptions.beamforming.doSigProcessing = false;
defaultOptions.beamforming.doMuMVDROptimization = false;%TODO implement
defaultOptions.beamforming.muMVDR = inf;%-inf -> sdb, inf -> dsb
defaultOptions.beamforming.noiseAngle = 'diffuse';%angle in degree or 'diffuse'
%only for stand alone use of weighting matrix synthesis, otherwise these values
		%will be determined automatically through blocksize and signal
		%sample rate. they will be overwritten with the apropriate values!
defaultOptions.beamforming.noProcess.frequNum = 200;
defaultOptions.beamforming.noProcess.frequMin = 20;
defaultOptions.beamforming.noProcess.frequMax = 20000;
%defaultOptions.beamforming.beampatternResolution = 1;%in degree
%%%%%beamforming%%%%%

%%%%%ICA%%%%%
%TODO when doFDICA false, use identity matrix for demixing or the matrix given in
		%options.W if it exists
defaultOptions.doFDICA = false;
defaultOptions.doFDICASourceLoc = false;
defaultOptions.ica.doBeampattern = false;
defaultOptions.ica.postProc = '';%'binMaskLevel';
defaultOptions.iterICA = 100;
defaultOptions.startFrequ = 0; %in Hz
%number of adjcent frequency bin that are averaged for sorting
defaultOptions.fAvNum = 1; 
%number of samples for moving average to calculate envelope of
%time-frequency-samples for sorting
defaultOptions.tAvNum = 1; 
defaultOptions.ica.beampatternResolution = 1;%in degree
defaultOptions.sortCorrBlock.blockSize = 0.3;%in seconds
defaultOptions.sortCorrBlock.corrThreshold = 0.8;
defaultOptions.sortList = {};
%%%%%ICA%%%%%

%%%%%RPM estimation%%%%%
defaultOptions.doRpmEstimation = false;
%algorithm, autoCorrFrequ is best
%['peakMeanRatio' 'maxLhHisto' 'autoCorrFrequ' 'autoCorrTime']
defaultOptions.rpmEstimation.algo = 'autoCorrFrequ';
%upper limit for rpm value
defaultOptions.rpmEstimation.rpmHigh = 5000;
%lower limit for rpm value
defaultOptions.rpmEstimation.rpmLow = 500;
%upper frequency to be processd in Hz
defaultOptions.rpmEstimation.frequHigh = 500;
%lowest possible frequency in Hz
defaultOptions.rpmEstimation.frequLow = 10;
defaultOptions.rpmEstimation.histRes = 1;%histogram resolution in Hz
%number of loudest/best frequencies to use
defaultOptions.rpmEstimation.candNum = 10;
%cut out low energy spectral values
defaultOptions.rpmEstimation.doSpecEnhance = false;
%all spectral values below maximum*specEnhanceThreshold are set to zero
defaultOptions.rpmEstimation.specEnhanceThreshold = 0.7;
%likelihood function to rate frequency
defaultOptions.rpmEstimation.maxLhHisto.mu = 10; %in Hz
defaultOptions.rpmEstimation.maxLhHisto.sigma = 10; %in Hz
defaultOptions.rpmEstimation.peakMeanRatio.peakMeanRatio = 0.5; %in Hz
defaultOptions.rpmEstimation.smoothAlgo = 'mean';%'mean' or 'median'
%defaultOptions.rpmEstimation.autoCorr.algo = 'frequ';%['frequ' 'time' 'gccPhat']
%number of values for smoothing, 1 means no smoothing
defaultOptions.rpmEstimation.smoothNum = 1; 
%do a linear prediction with that number of previous results
%to narrow the list of candidates
%if set to zero, no prediction is done at all
defaultOptions.rpmEstimation.predictionCoeffNum = 0;
%range where values must lie in to be accepted by linear prediction algorithm
%[predictValue-predictionRange <= predictValue <= predictValue+predictionRange]
defaultOptions.rpmEstimation.predictionRange = 100;
%use a histogram to select among candidates
defaultOptions.rpmEstimation.doHistogram = false;
%car information
defaultOptions.rpmEstimation.useCarInformation = false;
defaultOptions.rpmEstimation.za = 4; %cylinders
defaultOptions.rpmEstimation.m = 0.5; %motor type(1:two-stroke,0.5:four-stroke)
defaultOptions.rpmEstimation.gz = 1; %simultaniously fired cylinders
%%%%%RPM estimation%%%%%

%%%%%speech recognition%%%%%
defaultOptions.doSpeechRecognition = false;
defaultOptions.speechRecognition.doRemote = false;%start recognizer on eakss1 and
		%proceed processing of subsequent tasks
defaultOptions.speechRecognition.doGetRemoteResults = false;%gather results of
		%previous remote speech recognition experiment no speech recognition
		%will be done if this key is set true
defaultOptions.speechRecognition.sigDir = '';
defaultOptions.speechRecognition.db = 'samurai';%'samurai', 'apollo'
defaultOptions.speechRecognition.model = '3_15';
%%%%%speech recognition%%%%%

defaultOptions.tmpDir = '~/tmp/';
defaultOptions.resultDir = '/erk/home/feher/Simulationen/ergebnisse/last/';
defaultOptions.sourceLocOptions.frequLow = 0;
defaultOptions.sourceLocOptions.frequHigh = inf;

%%%%%ADMA%%%%%
%output: result.signal(1,:) = binary masked signal
		%result.signal(2,:) = adma signal
		%result.signal(3,:) = sphere signal
defaultOptions.doADMA = false;
defaultOptions.adma.doICA = false; 
defaultOptions.adma.doEqualization = true;%equalization of cardioids'
														%frequency response
%TODO: change to doFindMax
defaultOptions.adma.findMax = false;%use adaptive algorithm to find speaker
%TODO: change to doFindMin
defaultOptions.adma.findMin = false;%use adaptive algorithm to find noise source
defaultOptions.adma.returnCardioids = false;%returns the time domain signals
				%of the calculated cardioid signals in results.adma.cardioids
defaultOptions.adma.returnEights = false;%returns the time domain signals
						%of the calculated dipole signals in results.adma.eights
defaultOptions.adma.steeringMethod = 'cardioids';%'cardioids' or 'eights'
defaultOptions.adma.theta1 = 0;%angle of speaker
defaultOptions.adma.theta2 = 180;%angle of noise source
defaultOptions.adma.speaker_range=[-45 45];%limited range to search speaker in
%range to search min and max in, should not be altered in most cases
defaultOptions.adma.search_range = 0:5:355;
defaultOptions.adma.Mask = false;%do binary masking TODO: change to doMask
%set beampattern of dma
%cardioid ignores theta2 and sets it to 180 
defaultOptions.adma.pattern = 'best';%'best', 'cardioid'
defaultOptions.adma.mask_update = 0.2;
defaultOptions.adma.mask_angle = 0.2;%TODO take an angle as for the twin mic,
										%and set to 0.9
defaultOptions.adma.d = 24.8e-3;%distance between microphones
defaultOptions.adma.zero_noise = false;%if true, set output signal to zero if
										%no speaker could be found
%%%%%ADMA%%%%%
