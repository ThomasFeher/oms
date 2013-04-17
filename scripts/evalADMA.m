%TODO: change to same interface and behaviour as evalTwinMic
function [snrImp snrBefore snrAfter] = evalADMA(options,results,index)

  if (nargin == 2)
    index = 1;
  end

  signal = results.signalEval{1}(3,:);
  noise = zeros(size(signal));
  for srcCnt=2:options.srcNum
    noise = noise + results.signalEval{srcCnt}(3,:);
  end
  
  snrBefore = snr(signal,noise);

  signal = results.signalEval{1}(index,:);
  noise = zeros(size(signal));
  for srcCnt=2:options.srcNum
    noise = noise + results.signalEval{srcCnt}(index,:);
  end
  snrAfter = snr(signal,noise);
% %   if(options.doFDICA)
% %     for sigCnt=2:options.sigNum
% %       signal = results.signalEval{1}(sigCnt,:);
% %       noise = zeros(size(signal));
% %       for srcCnt=2:options.srcNum
% %         noise = noise + results.signalEval{srcCnt}(sigCnt,:);
% %       end
% %       snrAfterTest = snr(signal,noise)
% %       if(snrAfterTest>snrAfter)
% %         snrAfter = snrAfterTest;
% %       end
% %     end
% %   end

  snrImp = snrAfter - snrBefore;
end
