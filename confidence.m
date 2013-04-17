%calculates the 95% confidence intervall
%input:
% 	goodNum: number of correct recognized words
% 	num: number of elements
%output:
% 	conf: confidence is: +-conf
function conf = confidence (goodNum,num)
mu = goodNum/num;%mean
conf = 2*sqrt((mu-mu^2)/(num-1));
