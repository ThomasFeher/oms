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

%test null steering, can not be tested this way, need to make a complete
%framework call and use artificial impulse responses, which are not implemented
%yet
%options.findMax = false;
%options.findMin = false;
%options.d = 0.0248;
%options.doEqualization = false;
%options.steeringMethod = 'eights';
%options.theta1 = 150;
%options.theta2 = options.theta1 + 90;
%result = adma([1 2 3],10,16000,options,340);
%%eights are: [1-2,3-1,2-3] = [-1,2,-1]
%%cardioids are approximately the same, due to very low frequency
%%sphere is: (-1)+2+(-1) = 0;
%if(any(result~=[]))
	%error('test of adma steering failed');
%end
