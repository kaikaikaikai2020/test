clear
load VPIN.mat
%load VPIN_val
y = moving_window_average(VPIN(:,end),50);
y = y./V;
ind1 =VPIN(:,1)<datenum(2013,6,24);
%ind1 = VPIN(:,1)>=datenum(2013,6,21)&VPIN(:,1)<datenum(2013,6,24);
ind = VPIN(:,1)>=datenum(2013,6,24)&VPIN(:,1)<datenum(2013,6,26);
sub_y = [VPIN(ind,1),y(ind)];
subp1 = p1(ind);
parmhat = lognfit(y(ind1));
mx = parmhat(1);
stdx = parmhat(2);

p = logncdf(sub_y(:,end),mx,stdx);
yyaxis left
obj =plot([sub_y(:,end),p]);
obj(1).LineStyle='-';
obj(2).LineStyle='-';
obj(1).Color='r';
obj(2).Color='b';
set(gca,'YLim',[0,1.1]);
obj(1).LineWidth=2;
obj(2).LineWidth=2;
yyaxis right

plot(subp1,'k','linewidth',2);
legend({'VPIN','CDF of logVPIN','P'})

xtick_ind = floor(linspace(1,length(p),30));
xtick_label = cellstr(datestr(sub_y(xtick_ind,1),'yyyy/mm/dd HH:MM'));
xticks(xtick_ind)
xticklabels(xtick_label)
xtickangle(90)
%2013,8,16

ind1 =VPIN(:,1)<datenum(2013,8,16);
ind = VPIN(:,1)>=datenum(2013,8,16)&VPIN(:,1)<datenum(2013,8,17);
sub_y = [VPIN(ind,1),y(ind)];
subp1 = p1(ind);
parmhat = lognfit(y(ind1));
mx = parmhat(1);
stdx = parmhat(2);
p = logncdf(sub_y(:,end),mx,stdx);
figure;
yyaxis left
obj =plot([sub_y(:,end),p]);
obj(1).LineStyle='-';
obj(2).LineStyle='-';
obj(1).Color='r';
obj(2).Color='b';
obj(1).LineWidth=2;
obj(2).LineWidth=2;
yyaxis right
plot(subp1,'k','linewidth',2);
legend({'VPIN','CDF of logVPIN','P'})

xtick_ind = floor(linspace(1,length(p),30));
xtick_label = cellstr(datestr(sub_y(xtick_ind,1),'yyyy/mm/dd HH:MM'));
xticks(xtick_ind)
xticklabels(xtick_label)
xtickangle(90)

%{
p = logncdf(y(:,end),mx,stdx);
figure;plot([y(:,end),p])
legend({'VPIN','CDF'})
%}