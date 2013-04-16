function dist = ringDist(x,y,length)
dist = abs(x-y);
tooLong = dist>(length/2);
tooLongIndex = find(tooLong);
dist(tooLongIndex) = abs(dist(tooLongIndex)-length);
