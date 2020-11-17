%DMD 变动窗口结果
%update
%原来方法只是比较了本征值大小，大不一定准确率高，需要比较准确率

%2 预留5个交易日窗口，更正原始做法中使用未来信息
clear

load ticker_300_pool.mat ticker_300 t_300 datenum_300

[~,~,x] = xlsread('sz399300.xlsx');

tref_300 = datenum(x(2:end,2));
close_price_300 = cell2mat(x(2:end,4));
num_week = 5;
close_price_300_return_f = zeros(size(close_price_300));
close_price_300_return_b = close_price_300_return_f;
for i = num_week+1:length(close_price_300)-num_week
    close_price_300_return_f(i) = close_price_300(i+num_week)/close_price_300(i)-1;
    close_price_300_return_b(i) = close_price_300(i)/close_price_300(i-num_week)-1;
end

tref = xlsread('tref.xlsx');
num3 = -100;

t0 = datenum(2005,7,1);
tt = datenum(2017,3,1);

targ_tref = tref(tref>=t0&tref<=tt);

T = length(targ_tref);

re = zeros(T,6);
%过去一周收益率，本征值，未来一周收益率
for i = 1:T
    tic
    sprintf('begin %d-%d',i,T)
    t0 = targ_tref(i);
    sub_re = get_sub_dmd_result(t0,tref,tref_300,close_price_300_return_f,close_price_300_return_b,ticker_300,t_300,datenum_300,num3);
    re(i,:) = sub_re;
    
    sprintf('end %d-%d',i,T)
    toc
end

function re = get_sub_dmd_result(t0,tref,tref_300,close_price_300_return_f,close_price_300_return_b,ticker_300,t_300,datenum_300,num3)
    %tref 历史交易时间
    %tref_300 300历史交易时间
    %close_price_300_return_f 300 向前收益率
    %close_price_300_return_b 300 向后收益率
    %ticker_300 300历史股序号
    %t_300 300历史股时间 - 字符
    %datenum_300 300历史时间-数字
    %num3 窗口参数
    w_num =5; %number of week day
    ind = find(eq(tref_300,t0));    
    re = zeros(1,6);
    [~,ticker] = get_300_tickets_update(t0,ticker_300,t_300,datenum_300);
    re(1) = close_price_300_return_b(ind);
    re(2) = close_price_300_return_f(ind);   
    
    t3 = get_trading_date_interval(tref,t0,num3*2-w_num); %过去N+5天数据
    [X,~] = get_history_300_data(ticker,t3(1),t3(end),length(t3));
    y = close_price_300_return_f(max(1,ind+num3*2-w_num):ind);
    if length(y)<abs(num3*2)+1
        temp = abs(num3*2)+w_num+1-length(y);
        y = [zeros(temp,1);y];
    end
    
    wids = 50:2:100;
    xy_re = zeros(length(wids),3);
    for j = 1:length(wids)
        wid = wids(j);
        xy_data = zeros(100,2);
        for k = 1:100        
            sub_X = X(:,end-k-wid+1-w_num:end-k+1-w_num);
            [mu,~,~,R2] = dmd_method(sub_X);
            xy_data(k,:) = [abs(mu(1,1)),y(end-k+1-w_num)];
            if eq(k,1)
                xy_re(j,2:end) = [R2,mu(1,1)];
            end
        end
        xy_re(j,1) = sum((xy_data(:,1)-1).*xy_data(:,2)>0)/100;
    end
    [c_v,ia] = max(xy_re(:,1));
    %使用优化参数，计算最新的数值
    sub_wid = wids(ia);
    sub_X = X(:,end-sub_wid:end);
    [mu,~,~,R2] = dmd_method(sub_X);    
    re(3:6) = [c_v,R2,mu(1,1),sub_wid];
    %过去一周，未来一周，正确率，R2，Mu,window
    %1,2,3,4,5
end




