clear
addpath(fileparts(fileparts(mfilename('fullpath'))));
addpath([fileparts(fileparts(fileparts(mfilename('fullpath')))) '/GODLIKE']);
addpath('~/epstk/m');
bounds = [0.1,1;... %update coeff 	1
		0.8,1.2;... %threshold 		2
		500,800;... %cutoff high 	3
		0,200];... 	%cutoff low 	4
toUse = [1,2,3,4];
%diary('/erk/tmp/feher/twinDistOpt/log.txt');
[sol fval exitflag output] = GODLIKE(@twinDistOptFnct,50,bounds(toUse,1),...
													bounds(toUse,2),...
													{'DE';'PSO';'GA'},...
													'Display','on');
%diary off;

save('/erk/tmp/feher/gaFsd/optimizer_result','sol','fval','exitflag','output');
