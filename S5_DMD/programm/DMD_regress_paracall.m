clear

temp = load('dmd_regress_re_window_update1.mat');

load ticker_300_pool.mat ticker_300 t_300 datenum_300

[~,~,x] = xlsread('sz399300.xlsx');

tref_300 = datenum(x(2:end,2));
close_price_300 = cell2mat(x(2:end,4));

tref = xlsread('tref.xlsx');
[tref,ia,ib] = intersect(tref,tref_300);
close_price_300 = close_price_300(ib);

num1 = -5;
num2 = 5;
num3 = -60;
num3_a = -temp.re(:,end);
num3_a(6:end) = num3_a(1:end-5);
num3_a(1:6) = -60;
t0 = datenum(2005,7,1);
tt = datenum(2017,3,1);

targ_tref = tref(tref>=t0&tref<=tt);

T = length(targ_tref);

re = zeros(T,4);
%过去一周收益率，本征值，未来一周收益率
parfor i = 1:T
    num3 = num3_a(i);
    t0 = targ_tref(i);
    sub_re = get_sub_dmd_result(t0,tref,close_price_300,ticker_300,t_300,datenum_300,num1,num2,num3);
    re(i,:) = sub_re;
    sprintf('%d-%d',i,T)
end

function re = get_sub_dmd_result(t0,tref,close_price_300,ticker_300,t_300,datenum_300,num1,num2,num3)
    
    re = zeros(1,4);
    [~,ticker] = get_300_tickets_update(t0,ticker_300,t_300,datenum_300);
    [t1,t1_ind] = get_trading_date_interval(tref,t0,num1); %过去一周
    [t2,t2_ind] = get_trading_date_interval(tref,t0,num2); %未来一周
    re(1) = close_price_300(t1_ind(end))/close_price_300(t1_ind(1))-1;
    re(3) = close_price_300(t2_ind(end))/close_price_300(t2_ind(1))-1;   
    
    t3 = get_trading_date_interval(tref,t0,num3); %过去60天
    [X,del_ind] = get_history_300_data(ticker,t3(1),t3(end),length(t3));
    
    [mu,Phi,pred,R2] = dmd_method(X);
    re(4) = R2;
    re(2) = mu(1,1);
end




