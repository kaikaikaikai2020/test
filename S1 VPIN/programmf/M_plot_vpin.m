clear
load VPIN.mat

y = moving_window_average(VPIN(:,end),50);
y = y./V;
figure
h = histogram(y);

figure
yyaxis left
bar(y,'b');
hold on
plot(y,'b.');
ylabel('VPIN')
xlabel('bucket')
yyaxis right
plot(p1,'r','linewidth',2)
ylabel('P')

axis tight
re1 = table_sta1(y);
re1
re2 = zeros(6,3);
for i = 2011:2016
    sub_x = y(eq(year(VPIN(:,2)),i));
    re2(i-2010,:) = [mean(sub_x),std(sub_x),length(sub_x)];
end
re2
figure;
cdfplot(y);
ylabel('Probability');
title('VPIN');

figure;
qqplot(log(y));
view(90,-90)





function x = table_sta1(y)
[~,~,JBSTAT]=jbtest(y);
x = [kurtosis(y),skewness(y),JBSTAT];
end