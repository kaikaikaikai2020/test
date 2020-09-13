%M_sta_values
clear
p1 = [3,5,10,20,30,60];
p2 = 2:0.1:3.5;

t1 = length(p1);
t2 = length(p2);

% nh = zeros(t1,t2);
% sp = zeros(t1,t2);
% for i = 1:t1
%     for j = 1:t2
%         [nh(i,j),sp(i,j)]=FLS_strategy(p1(i),p2(j));
%         close all
%     end
% end

nh2 = zeros(t1,t2);
sp2 = zeros(t1,t2);
for i = 1:t1
    for j = 1:t2
        [nh2(i,j),sp2(i,j)]=cointegration_strategy(p1(i),p2(j));
        close all
    end
end