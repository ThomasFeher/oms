%plots a spectrogram via epstk
function plotSpec(spec,name,title,scaleX,scaleY,width,height,titleDist)
if(nargin<8)
	titleDist = 5;
end
if(nargin<7)
	height = 30;
end
if(nargin<6)
	width = 100;
end
if(nargin<5)
	scaleY = [0 0 0];
end
if(nargin<4)
	scaleX = [0 0 0];
end

eopen(name);
if(~(nargin<3||isempty(title)))
	etitle(title,titleDist);
end
eglobpar;
eAxesLabelFontSize = 3;
eAxesValueFontSize = 3;
eXAxisSouthScale = scaleX;
%eXAxisSouthLabelText = 'time in s';
eYAxisWestScale = scaleY;
%eYAxisWestLabelText = 'frequency in Hz';
ePlotAreaWidth = width;
ePlotAreaHeight = height;
eImageLegendVisible = 0;
eimagesc(abs(20*log10(abs((spec(:,end:-1:1)).')+1)));
eclose(1,0);
newbbox=ebbox(1);
