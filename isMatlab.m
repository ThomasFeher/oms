%check if matlab or octave is running this script
function is = isMatlab()
if(exist('OCTAVE_VERSION','builtin'))
	is = false;
else
	is = true;
end
