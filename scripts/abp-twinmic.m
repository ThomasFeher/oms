%funktioniert so nicht, da das Twin Mikrofon darauf beruht, dass beide Kapseln
%Nieren sind
clear
angle=[0 15 30 45 60 75]*2;
angleNum = numel(angle);
frequs = [1:1000:7001];
options.irDatabaseName = 'twoChanMic';
for frequCnt=frequs
	figure();
	options.iterICA = 100;
	options.sourceLocOptions.frequLow = frequCnt;
	options.sourceLocOptions.frequHigh = inf;
	options.inputSignals =...
			{'Daten/speech1.wav','Daten/speech2.wav'};
	for angleCnt=1:angleNum 
		options.impulseResponses = struct('angle',{angle(angleCnt) 180},...
				'distance',0.5,'room','refRaum');
		[results optRet] = fdICA(options);

		subplot(angleNum,2,angleCnt*2-1);
		plot(results.abpFeher);
		if(angleCnt==1)
			title(sprintf([['lower frequency: %d, upper frequency: %d']],...
					optRet.sourceLocOptions.frequLow,...
					optRet.sourceLocOptions.frequHigh));
		end
		srcPosString = '';
		for srcPosCnt=1:numel(results.sourceLoc.pos)
			srcPosString = [srcPosString sprintf('%d',results.sourceLoc.pos...
					(srcPosCnt)/pi*180)];
		end
		text(0,0.5,sprintf('source at: %s',srcPosString));
		subplot(angleNum,2,angleCnt*2);
		plot(results.abpOrig);
	end
end
clear options;
