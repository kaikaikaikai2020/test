clear

close all

[X,b_M05,b_M15,b_M30 ]= choose_data(3);

targ_tick = {'sh600109','sz002500'};
data_sel = 1;

title_str = {'5M','15M','30M'};

if eq(data_sel,3)
    b = b_M30(:,end);
elseif eq(data_sel,2)
    b = b_M15(:,end);
else
    b = b_M05(:,end);
end


ind1 = strcmp(X{data_sel}.ticket,targ_tick(1));
ind2 = strcmp(X{data_sel}.ticket,targ_tick(2));

t = X{data_sel}.tradingdate(ind1);
t.Format = 'uuuu-MM-dd HH:mm';
ind_model = t<'2013-9-7';


x1 = X{data_sel}.close(ind1);
x2 = X{data_sel}.close(ind2);
spread_value = x1 - x2 .* b;
spread_value(1:2) = 0;
Mspread_value = spread_value-mean(spread_value(ind_model));
%Mspread_value = spread_value-mean(spread_value);

figure
plot(Mspread_value(ind_model),'linewidth',2)
std_x = std(Mspread_value(ind_model));
hold on
lims = axis(gca);
plot(lims(1:2)',[0;0],'r:','linewidth',1);

plot(lims(1:2)',[-1,1;-1,1] * std_x,'k-','linewidth',1);
plot(lims(1:2),[-1,1;-1,1]*std_x*2,'k-.','linewidth',1);
set(gca,'fontsize',12);
xlabel('Index')
ylabel('Mspread')
title(title_str{data_sel})