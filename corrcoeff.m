function r = corrcoeff(x1,x2)
	vecLength = size(x1,2);
	x1 = x1-mean(x1);
	x2 = x2-mean(x2);
	num = x1*x2';
	denum = sqrt(x1*x1')*sqrt(x2*x2');
	r = num/denum;
	if(isnan(r))
		r = 0;
	end
end %function
