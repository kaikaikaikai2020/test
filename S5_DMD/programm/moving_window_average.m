function y = moving_window_average(x,windowSize)
 
b = (1/windowSize)*ones(1,windowSize);
a = 1;

y = filter(b,a,x);