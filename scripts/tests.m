%calls all tests
clear
addpath([fileparts(fileparts(mfilename('fullpath'))) '/tests']);
addpath(fileparts(fileparts(mfilename('fullpath'))));

%create directory for output data
tmpDir = '/erk/tmp/feher/frameworkTests';
mkdir(tmpDir);

fileList = dir('../tests/');
%fileList = fileList(~fileList.isDir);%remove directories
%only files that end on ".m"
fileList = fileList(~cellfun(@isempty,regexp({fileList(:).name},'.*\.m$')));
testNum = numel(fileList);
errCnt = 0;
for fileCnt=1:numel(fileList)
	%keyboard
	file = fileList(fileCnt).name;
	fileName = regexp(file,'\.m$','split');
	try
		eval([fileName{1} '(tmpDir)']);
	catch 
		disp(lasterror.message);
		%disp(erro.cause);
		disp({lasterror.stack.file});
		disp({lasterror.stack.line});
		%keyboard
		errCnt = errCnt+1;
	end
end
disp(sprintf('Number of errors: %d\nNumber of tests:  %d',errCnt,testNum));
