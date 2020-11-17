clear
%load dmd_regress_re2.mat
%load dmd_regress_re_window_update1.mat;re = re(:,[1,5,2,4,3,6]);
%load dmd_regress_re_window_update2.mat
load dmd_regress_re_window_update3.mat;re = re(:,[1,5,2,4,3,6]);

[~,~,x] = xlsread('sz399300.xlsx');

tref_300 = datenum(x(2:end,2));
close_price_300 = cell2mat(x(2:end,4));

[~,ia] = intersect(tref_300,targ_tref);
tref_300 = tref_300(ia);
close_price_300 = close_price_300(ia);

close_price_300_return = [0;close_price_300(2:end)./close_price_300(1:end-1)-1];

t = datetime(targ_tref,'ConvertFrom','datenum');
t_str = cellstr(datestr(targ_tref,'yyyy/mm/dd'));

y = movavg(real(re(:,4)),'linear',30);
%y = movmean(real(re(:,4)),30);

y2 = y;
for i = 120:length(y)
    sub_wind = i-120+1:i;
    y2(i) = half_year_cutvalue(y(sub_wind));
end

v1 = 1.03;
ind1 = y>y2 &abs(re(:,2))>=v1;
ind2 = y<=y2 | abs(re(:,2))<0.99;
ind3 =  abs(re(:,2))<0.99;

T = length(ind1);
r1 = zeros(T,1);
r2 = zeros(T,1);
fee = 3/1000/2;

signal_ind = zeros(T,1);

for i = 2:T-1
    if ind1(i)
        signal_ind(i+1) = 1;
        if ~eq(signal_ind(i+1),signal_ind(i))
            r2(i+1) = fee;
        end
        continue
    end
    if ind2(i)
        signal_ind(i+1) = 0;
        if ~eq(signal_ind(i+1),signal_ind(i))
            r2(i+1) = fee;
        end
        continue
    end
    
    signal_ind(i+1) = signal_ind(i);
    r2(i+1) = 0;
end

r1(eq(signal_ind,1))=close_price_300_return(eq(signal_ind,1));

r3 = r1-r2;
y_back_test =cumprod(1+r3);
y_back_ref = close_price_300/close_price_300(1);
xticks(floor(linspace(1,length(t),12)))
xticklabels(t_str(floor(linspace(1,length(t),12))));

%辅助信号
close_price_300_ma = movavg(close_price_300,'linear',30);
%close_price_300_ma = movmean(close_price_300,30);
r1 = zeros(T,1);
r2 = zeros(T,1);
signal_ind2 = zeros(T,1);
signal_value = 0;
signal_type=0;
mark_pos = -inf;
for i = 3:T-1
    
    add_signal1 = close_price_300(i)<close_price_300(i-1) & close_price_300(i)<close_price_300_ma(i) & close_price_300(i-1)<close_price_300_ma(i-1) & close_price_300(i-2)>=close_price_300_ma(i-2); %下穿
    if ind1(i) %买点
        signal_ind2(i+1) = 1;
        if ~eq(signal_ind2(i+1),signal_ind2(i))
            r2(i+1) = fee;
        end
        if close_price_300(i)>close_price_300_ma(i)
            signal_type = 1;
        else
            mark_pos = i;
            signal_type = 2;
        end        
        continue
    end
    %卖点
    if eq(signal_type,1)
        if add_signal1 || ind3(i)
            signal_ind2(i+1) = 0;
            if ~eq(signal_ind2(i+1),signal_ind2(i))
                r2(i+1) = fee;
            end
            signal_type=0;
            mark_pos = -inf;
            continue
        end
    end
    if eq(signal_type,2)
        if eq(i-mark_pos,5) || ind3(i)
            signal_ind2(i+1) = 0;
            if ~eq(signal_ind2(i+1),signal_ind2(i))
                r2(i+1) = fee;
            end
            signal_type=0;
            mark_pos = -inf;
            continue
        end
    end

    signal_ind2(i+1) = signal_ind2(i);
    r2(i+1) = 0;
end

r1(eq(signal_ind2,1))=close_price_300_return(eq(signal_ind2,1));
r3 = r1-r2;
y_back_test2 =cumprod(1+r3);

% sub_ind = targ_tref>=datenum(2005,12,1);
% y_back_ref = y_back_ref(sub_ind);
% t_str = t_str(sub_ind);
% y_back_test = y_back_test(sub_ind);
% y_back_test2 = y_back_test2(sub_ind);
% y_back_test = y_back_test/y_back_test(1);
% y_back_test2 = y_back_test2/y_back_test2(1);
% t = t(sub_ind);

obj = plot([y_back_ref,y_back_test,y_back_test2],'LineWidth',2);
xticks(floor(linspace(1,length(t),12)))
xticklabels(t_str(floor(linspace(1,length(t),12))));
legend({'300','信号1','信号2'},'location','best');
obj(1).Color=[0,0.4510,0.7412];
obj(2).Color=[0.6392,0.0784, 0.1804];
obj(3).Color=[0.4706,0.6706,0.1882];

[v1,v_str1,sta_val1] = curve_static(y_back_ref);
[v2,v_str2,sta_val2] = curve_static(y_back_test);
[v3,v_str3,sta_val3] = curve_static(y_back_test2);
