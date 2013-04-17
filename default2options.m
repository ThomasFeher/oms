
function options = default2options(defaultOptions,options)
names = fieldnames(defaultOptions);
for k=1:length(names)
	%find sub-structs that are no struct-arrays like options.impulseResponses
	if(isstruct(defaultOptions.(names{k}))&&numel(defaultOptions.(names{k}))==1)
		if(~isfield(options,names{k})||isempty(options.(names{k})))
			options.(names{k}) = defaultOptions.(names{k});
		else
			options.(names{k}) = default2options(defaultOptions.(names{k}),...
					options.(names{k}));
		end
	elseif ~isfield(options,names{k}) || isempty(options.(names{k}))
		options.(names{k}) = defaultOptions.(names{k});
	end
end
