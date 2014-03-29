function retVal = dot_expand(inp)
if(~isvector(inp) || size(inp,1)>1 || ~ischar(inp))
	error('Input argument must be a string.');
end

retVal = regexprep(inp,'^./',[pwd '/']);

%!fail('dot_expand(''test''.'')');
%!fail('dot_expand(1)');
%!fail('dot_expand([1 2])');
%!test
%! x = '/test';
%! ret = dot_expand(x);
%! assert(ret,x);
%!test
%! x = 'test/x';
%! ret = dot_expand(x);
%! assert(ret,x);
%!test
%! ret = dot_expand('./test');
%! assert(~strcmp(ret(1),'.'));
