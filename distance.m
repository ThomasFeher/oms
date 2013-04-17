function retval = distance(sig1,sig2)
	retval = norm(sig1/norm(sig1) - sig2/norm(sig2));
end
