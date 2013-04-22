%only steering method 'eights' tested
clear

addpath('../');

weightVec = admaParams(30,0,'eights');%should be [1;0;0]
weightVec = round(weightVec*100)/100;
if(any(weightVec~=[1;0;0]))
	error('test of adma steering failed');
end

weightVec = admaParams(150,0,'eights');%should be [-1;0;-1]
weightVec = round(weightVec*100)/100;
if(any(weightVec~=[-1;0;-1]))
	error('test of adma steering failed');
end

weightVec = admaParams(270,0,'eights');%should be [0;0;1]
weightVec = round(weightVec*100)/100;
if(any(weightVec~=[0;0;1]))
	error('test of adma steering failed');
end

%test vector input

weightVec = admaParams([30,150,270],0,'eights');%should be [1,-1,0;0,0,0;0,-1,1]
weightVec = round(weightVec*100)/100;
if(any(weightVec~=[1,-1,0;0,0,0;0,-1,1]))
	error('test of adma steering failed');
end

