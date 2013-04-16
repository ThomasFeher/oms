%optimize beamformer angle, blockSize and timeShift for noise sources between
%90 and 180 degree

%global optimzation toolbox, seems to not be installed
%addpath('/opt/MATLAB/R2012a/toolbox/globaloptim/globaloptim/');
%func = @gaTwinBfFnct;
%[x,fval,exitFlag,output,population,scores] =...
		%ga(@gaTwinBfFnct,3,[],[],[],[],[5,128,0],[90,10240,128]);

%code from matlab central "GODLIKE"
addpath('~/sim/framework');
addpath('~/sim/GODLIKE');
[sol fval exitflag output] = GODLIKE(@gaTwinBfFnct,50,[5,128,0.2],[90,4096,0.5]);

%found solution: 62, 767, 0.22, fval=0.0676, exitflag=1,
save('/erk/tmp/feher/optimizer_result','sol','fval','exitflag','output');
