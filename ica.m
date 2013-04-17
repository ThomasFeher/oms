function icaResults = ica(options,results)
disp('Calculating ICA...');
sigVec = results.last.sigVec;
sigNum = options.sigNum;
blockNum = options.blockNum;
blockSizeZeroPads = options.blockSizeZeroPads;
frequNum = options.frequNum;
iterICA = options.iterICA;
frequency = options.frequency;
startFrequ = options.startFrequ;
geometry = options.geometry;
c = options.c;
sigVecICA = zeros(sigNum,blockNum,frequNum);
iterations = zeros(frequNum,1);
wDiff = zeros(frequNum,iterICA);
negentDiff = zeros(frequNum,iterICA);
negent = zeros(frequNum,iterICA);
Wold = eye(sigNum);
WAll = zeros(sigNum,sigNum,frequNum);
WAllUnsort = zeros(sigNum,sigNum,frequNum);
WAllSort = zeros(sigNum,sigNum,frequNum);
tfhist = zeros(frequNum,180);
%Wold = Wold([2 1],:);
[x cntOffset] = min(abs(frequency-startFrequ));
cntArray = [1:frequNum];
cntArray = circshift(cntArray,[0 1-cntOffset]);
%for cnt=1:blockSizeZeroPads/2+1
for cnt=cntArray
	fprintf('ICA frequency %04d (%05.0f Hz)...',cnt,frequency(cnt));
	[tfhist(cnt,:) centers] = tfHist(sigVec(1,:,cnt),sigVec(2,:,cnt),...
		abs(geometry(1,2)-geometry(1,1)),c,frequency(cnt));
	%Wold = eye(sigNum);
	%[W,Wold,sigVecWhite,iterations(cnt),negentDiff(cnt,:)] = ...
		%FastICAHyv(sigVec(:,:,cnt),iterICA,Wold);
	[W,Wold,sigVecWhite,iterations(cnt),wDiff(cnt,:),negentDiff(cnt,:),...
		negent(cnt,:)] = FastICAcomplex(sigVec(:,:,cnt),iterICA,Wold,sigNum);
	%[W,Wold,sigVecWhite,iterations(cnt),negentDiff(cnt,:)] = ...
		%ICA_Amari(sigVec(:,:,cnt),iterICA,Wold,cnt);
	%W = eye(sigNum); iterations(cnt) = 1;%bypass ICA
	WAllUnsort(:,:,cnt) = W;
	sigVecICA(:,:,cnt) = (WAllUnsort(:,:,cnt)) * squeeze(sigVec(:,:,cnt));
	fprintf('%02d Iterations\n',iterations(cnt));
end
%%%%%ICA%%%%%

%%%%%ICA-source localization%%%%%
if(options.doFDICASourceLoc)
	abpO = abpOrig(geometry(1,:),WAllUnsort,frequency,options.sourceLocOptions);
	icaResults.abpOrig = abpO;
	abpF = abpFeher(geometry(1,:),WAllUnsort,frequency,options.sourceLocOptions);
	icaResults.abpFeher = abpF;
	[sourceNum sourcePos] = sourceCount(WAllUnsort,frequency,geometry,options);
	icaResults.sourceLoc.num = sourceNum;
	icaResults.sourceLoc.pos = sourcePos;
end
%%%%%ICA-source localization%%%%%

%%%%%sorting%%%%%
permMat = zeros(sigNum,sigNum,frequNum);
for cnt=1:frequNum
	permMat(:,:,cnt) = eye(sigNum);
end
E = zeros(sigNum,sigNum,sigNum);
for cnt=1:sigNum
	E(cnt,cnt,cnt) = 1;
end
%sortBypass;
sortCorrNeighbour;
%sortPatternFrequMultiMin;
%sortPatternFrequMultiMax;
%sortFFT;
%sortPattern;
%sortPatternEdge;
%sortPatternMin;
%sortPatternFrequMin;
%sortPatternFrequMinOpt;
%sortWeightVec;
%sortAmp;%not working!
%sortComplex;
%sortFeatureW;
icaResults.WAllSort = WAllSort;
%%%%%sorting%%%%%

sigVec= applyICA(WAllSort,sigVec,blockSizeZeroPads,blockNum);
icaResults.ica.sigVec = sigVec;
switch(options.ica.postProc)
case('sortCorrBlock')
	sortResult = sortCorrBlock(options,sigVec);
case('binMaskLevel')
	sortResult = binMaskLevel(options,sigVec);
otherwise
	sortResult.sigVec = sigVec;
end
icaResults.postproc.sigVec = sortResult.sigVec;

if(options.doConvolution)
	for srcCnt=1:options.srcNum
		icaResults.postproc.sigVecEval{srcCnt} = applyICA(WAllSort,...
				results.last.sigVecEval{srcCnt},blockSizeZeroPads,blockNum);
	end
end

if(options.ica.doBeampattern)
	icaResults.beampatternUnsort = beampattern(options,WAllUnsort,...
			options.ica.beampatternResolution);
	icaResults.beampatternSort = beampattern(options,WAllSort,...
			options.ica.beampatternResolution);
end
