function [z,V,D]=whitening(x)

%Center Data
%{
mx=mean(x,2);
x(1,:)=x(1,:)-mx(1);
x(2,:)=x(2,:)-mx(2);
%}

%Whitening
%Cx=cov(x');
%{
Cx = x*conj(x')/size(x,2);
[E,D]=eig(Cx);
V=E/sqrt(D)*E';
%}
Cx = x*x'/size(x,2);
[E,D]=eig(Cx);
V = sqrt(inv(D))*E';
z=V*x;

