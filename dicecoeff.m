function r = dicecoeff(x1,x2)
	num = 2*x1*x2';
	denum = x1*x1'+x2*x2';
	r = num/denum;
end %function
