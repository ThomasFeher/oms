% load genetic optimization package
pkg load ga;

% add oms path
omsPath ='~/Daten/Tom/oms';
addpath(omsPath);

%options = gaoptimset('Display','diagnose'...
                    %,'FitnessLimit',0 ...
					%,'OutputFcns',@saveGeneration);
options = gaoptimset('FitnessLimit',0 ...
                    ,'PopInitRange',[1,0,0,0;10,1,1,1]);
[x,fval,exitflag,output,population,scores] = ...
ga(@fitfunc,4,[],[],[],[],[1,0,0,0],[10,1,1,1],[],options);
