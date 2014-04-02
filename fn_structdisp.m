function fn_structdisp(Xname)
% function fn_structdisp Xname
% function fn_structdisp(X)
%---
% Recursively display the content of a structure and its sub-structures
%
% Input:
% - Xname/X     one can give as argument either the structure to display or
%               or a string (the name in the current workspace of the
%               structure to display)
%
% A few parameters can be adjusted inside the m file to determine when
% arrays and cell should be displayed completely or not
%
%---
% Thomas Deneux 
% last modification: September 20th, 2007

if ischar(Xname)
    X = evalin('caller',Xname);
else
    X = Xname;
    Xname = '';
end

if ~isstruct(X), error('argument should be a structure or the name of a structure'), end
rec_structdisp(Xname,X)

%---------------------------------
function rec_structdisp(Xname,X)
%---

%-- PARAMETERS (Edit this) --%

ARRAYMAXROWS = inf;
ARRAYMAXCOLS = inf;
ARRAYMAXELEMS = inf;
CELLMAXROWS = inf;
CELLMAXCOLS = inf;
CELLMAXELEMS = inf;
CELLRECURSIVE = true;

%----- PARAMETERS END -------%

if isstruct(X)
    F = fieldnames(X);
    nsub = length(F);
    Y = cell(1,nsub);
    subnames = cell(1,nsub);
    for i=1:nsub
        f = F{i};
        Y{i} = X.(f);
        subnames{i} = [Xname '.' f];
    end
elseif CELLRECURSIVE && iscell(X)
    nsub = numel(X);
    s = size(X);
    Y = X(:);
    subnames = cell(1,nsub);
    for i=1:nsub
        inds = s;
        globind = i-1;
        for k=1:length(s)
            inds(k) = 1+mod(globind,s(k));
            globind = floor(globind/s(k));
        end
        subnames{i} = [Xname '{' num2str(inds,'%i,')];
        subnames{i}(end) = '}';
    end
end

for i=1:nsub
    a = Y{i};
    if isstruct(a)
        if length(a)==1
            rec_structdisp(subnames{i},a)
        else
            for k=1:length(a)
                rec_structdisp([subnames{i} '(' num2str(k) ')'],a(k))
            end
        end
    elseif iscell(a)
        if size(a,1)<=CELLMAXROWS && size(a,2)<=CELLMAXCOLS && numel(a)<=CELLMAXELEMS
            rec_structdisp(subnames{i},a)
        end
	elseif ischar(a)
		disp([subnames{i} ' = ' a]);
	elseif isscalar(a)
		if(isa(a,'function_handle'))
			disp([subnames{i} ' = ' func2str(a)]);
		else
			disp([subnames{i} ' = ' num2str(a)]);
		end
	%if is linearly spaced vector with more than 2 elements
	elseif (numel(find(size(a)>1))==1 ...%one dim > 1
				&& numel(a)>2 ...%more than 2 elements
				&& all(a == linspace(a(1),a(end),numel(a)))) %linearly spaced
		disp([subnames{i} ' = ' num2str(a(1)) ':'...
								num2str((a(end)-a(1))/(numel(a)-1)) ':'...
								num2str(a(end))]);
	elseif size(a,1)>1 && size(a,1)<=ARRAYMAXROWS && size(a,2)<=ARRAYMAXCOLS && numel(a)<=ARRAYMAXELEMS
		disp([subnames{i} ':'])
		disp(a)
	elseif length(a) > 1
		disp([subnames{i} ' = ' num2str(a(:).')]);
    end
end
