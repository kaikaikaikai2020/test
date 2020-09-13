clear
load dmd_regress_re2.mat
%load dmd_regress_re_window.mat
%load dmd_regress_re_window_update1.mat;re = re(:,[1,5,2,4,3,6]);
%load dmd_regress_re_window_update3.mat;re = re(:,[1,5,2,4,3,6]);

X0 = [ones(size(re(:,1))),re(:,1),abs(re(:,2))];
y0 = re(:,3);

[b,bint,r,rint,stats] = regress(y0,X0);

t = datetime(targ_tref,'ConvertFrom','datenum');
t_str = cellstr(datestr(targ_tref,'yyyy/mm/dd'));
%plot(targ_tref,real(re(:,end))*100,'LineWidth',2);

%xticks(targ_tref(floor(linspace(1,end,12))))

% a = 2005:2016;
% b = zeros(size(a));
% for i = 1:length(b)
%     b(i) = datenum(a(i),7,8);
% end
% c = cellstr(datestr(b,'yyyy/mm/dd'));
plot(real(re(:,4))*100,'LineWidth',2);
set(gca,'YLim',[95,100]);
xticks(floor(linspace(1,length(t),12)))
xticklabels(t_str(floor(linspace(1,length(t),12))));
setpixelposition(gcf,[408,381,1065 ,420]);
movegui(gcf,'center');

figure
[~,~,x] = xlsread('sz399300.xlsx');
tref_300 = datenum(x(2:end,2));
close_price_300 = cell2mat(x(2:end,4));
[~,ia] = intersect(tref_300,targ_tref);
close_price_300 = close_price_300(ia);

y = movavg(real(re(:,4)),'linear',30);
yyaxis right
plot(y*100,'LineWidth',2);
set(gca,'YLim',[95,100]);
xticks(floor(linspace(1,length(t),12)))
xticklabels(t_str(floor(linspace(1,length(t),12))));
yyaxis left
plot(close_price_300,'LineWidth',2);
setpixelposition(gcf,[408,381,1065 ,420]);
movegui(gcf,'center');