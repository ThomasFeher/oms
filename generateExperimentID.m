%generates an ID and relatet log file
function [options] = generateExperimentID(options)
if(~isfield(options,'tmpDir'))
	error('no path for temporary files specified');
end
if(~exist(options.tmpDir,'dir'))
	error(sprintf(['directory for temporary files: %s does not exist.'...
			'Please set options.tmpDir to an existing directory.'],...
			options.tmpDir));
end

%number of digits of the temp id
idDigits = options.logIdDigits;
%search for log file with highest id
logList = dir(options.resultDir);%list of all files in temp dir
logList = logList(~[logList(:).isdir]);%throw out subdirectories
logList = logList(~cellfun(@isempty,regexp({logList(:).name},...
		['^log_\d{' sprintf('%d',idDigits) '}.txt$'])));%filter out log files

if(isempty(logList))%no log file found?
	id = 0;
else%found log file
	%new id is id of last file plus one
	id = sscanf(logList(end).name,'log_%d')+1;
end

%generate log file name if necessary
options.tmpID = id;
if(options.doLogfile)
	logFile = sprintf(['%slog_%0' sprintf('%d',idDigits) 'd.txt'],options.resultDir,id);
	options.logFile = logFile;
else
	options.logFile = 'no log file, switch on options.doLogfile';
end
