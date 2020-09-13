clear
X = choose_data(1);

re_sel = 1;%1 只是用样本内数据计算 2使用全部数据计算

T = length(X);
X = X(end:-1:1);
targ_tick = {'sh600109','sz002500'};

sub_table_re1 = zeros(T,7);
sub_table_re2 = zeros(T,7);

X2 = cell(T,1);
for i = 1:T
    ind1 = strcmp(X{i}.ticket,targ_tick(1));
    ind2 = strcmp(X{i}.ticket,targ_tick(2));
    if eq(re_sel,1)
    ind = X{i}.tradingdate(ind1)<'2013-09-09';
    else
    ind = 1:size(X{i}(ind1,:),1);
    end
    
    x1 = X{i}.close(ind1);
    x2 = X{i}.close(ind2);
    x1 = x1(ind);
    x2 = x2(ind);
    %subplot(3,1,i);plot([x1,x2]);
    corr(x1,x2)
    if eq(i,1)
        plot([x1,x2])
        legend({'GJ','SX'})
    end
    sub_table_re1(i,:) = static_curve(x1);
    sub_table_re2(i,:) = static_curve(x2);
    
    X2{i} = [x1,x2];
end

table_re1 = [sub_table_re1;sub_table_re2];
table_re1(1:2:end,:) = sub_table_re1;
table_re1(2:2:end,:) = sub_table_re2;

function re = static_curve(y)
re = [mean(y),median(y),max(y),min(y),std(y),skewness(y),kurtosis(y)];
end