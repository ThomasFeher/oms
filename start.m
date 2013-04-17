function [results opt] = start(options)
%load default parameters
defaults;
if nargin<1%no input arguments
	options = defaultOptions;%use default options
else%options given
	%use given options and defaults for not given options
	options = default2options(defaultOptions,options);
end

%check if matlab or octave is running this script
options.isMatlab = isMatlab();

if(options.doLogfile)%write to log file
	if(isMatlab)
		[logText results opt] = evalc('framework(options)');
	else
		logText = system('octave < framework.m');
	end
	%TODO load results and opt in case of using octave
	fId = fopen(opt.logFile,'w');
	fprintf(fId,logText);
	fclose(fId);
else%write to console
	[results opt] = framework(options);
end
