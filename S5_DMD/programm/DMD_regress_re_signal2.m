%clear
%load dmd_regress_re2.mat
%load dmd_regress_re_window_update1.mat;re = re(:,[1,5,2,4,3,6]);
load dmd_regress_re_window_update2.mat
[~,~,x] = xlsread('sz399300.xlsx');

tref_300 = datenum(x(2:end,2));
close_price_300 = cell2mat(x(2:end,4));

[~,ia] = intersect(tref_300,targ_tref);
tref_300 = tref_300(ia);
close_price_300 = close_price_300(ia);

close_price_300_return = [0;close_price_300(2:end)./close_price_300(1:end-1)-1];

X0 = [ones(size(re(:,1))),re(:,1),abs(re(:,2))];
y0 = re(:,3);

[b,bint,r,rint,stats] = regress(y0,X0);

t = datetime(targ_tref,'ConvertFrom','datenum');
t_str = cellstr(datestr(targ_tref,'yyyy/mm/dd'));
%plot(targ_tref,real(re(:,end))*100,'LineWidth',2);

%xticks(targ_tref(floor(linspace(1,end,12))))

plot(real(re(:,4))*100,'LineWidth',2);
set(gca,'YLim',[95,100]);
xticks(floor(linspace(1,length(t),12)))
xticklabels(t_str(floor(linspace(1,length(t),12))));

y = movavg(real(re(:,4)),'linear',30);

y2 = y;
for i = 120:length(y)
    sub_wind = i-120+1:i;
    y2(i) = half_year_cutvalue(y(sub_wind));
end

ind1 = y>y2;
[b,bint,r,rint,stats] = regress(y0(ind1,:),X0(ind1,:));


v1 = 1.02:0.01:1.10;
re5 = zeros(length(v1),4);
for ii = 1:length(v1)

temp_v1 = v1(ii);
ind1 = y>y2 &abs(re(:,2))>=temp_v1;

sum(ind1)

ind2 = find(ind1);
T = length(ind2);
ind3 = zeros(size(ind1));
re2 = zeros(T,1);
for i = 1:T
    sub_ind1 = ind2(i)+1;
    sub_ind2 = min(ind2(i)+5,length(ind1));
    temp = cumprod(1+close_price_300_return(sub_ind1:sub_ind2));
    re2(i)=temp(end)-1;
    ind3(sub_ind1:sub_ind2) = 1;
end


return1 = zeros(size(ind3));
return1(eq(ind3,1)) = close_price_300_return(eq(ind3,1));
% plot(cumprod(1+re2),'LineWidth',2)
% figure
% plot(cumprod(1+close_price_300_return(eq(ind3,1))),'LineWidth',2);
% figure
% plot(t,close_price_300)
% hold on
% plot(t(ind2),close_price_300(ind2),'*');

re3 = [temp_v1,sum(re2>0)/length(re2),mean(re2),length(re2)];
re5(ii,:) = re3;
end
