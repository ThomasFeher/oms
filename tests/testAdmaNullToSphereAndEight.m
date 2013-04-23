clear;
addpath('../');

%figure eight
weight = admaNullToSphereAndEight(90);
weight = round(weight*100)/100;
if(weight~=0)
	error('test of admaNullToSphereAndEight failed');
end

%cardioid
weight = admaNullToSphereAndEight(180);
weight = round(weight*100)/100;
if(weight~=0.5)
	error('test of admaNullToSphereAndEight failed');
end

%big angles
%figure eight
weight = admaNullToSphereAndEight(270);
weight = round(weight*100)/100;
if(weight~=0)
	error('test of admaNullToSphereAndEight failed');
end

%figure eight
weight = admaNullToSphereAndEight(450);
weight = round(weight*100)/100;
if(weight~=0)
	error('test of admaNullToSphereAndEight failed');
end

%negative angles
%figure eight
weight = admaNullToSphereAndEight(-90);
weight = round(weight*100)/100;
if(weight~=0)
	error('test of admaNullToSphereAndEight failed');
end

%cardioid
weight = admaNullToSphereAndEight(-180);
weight = round(weight*100)/100;
if(weight~=0.5)
	error('test of admaNullToSphereAndEight failed');
end
