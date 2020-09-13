clear

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

t0 = datenum(2005,7,1);
tt = datenum(2017,3,1);

targ_tref = tref(tref>=t0&tref<=tt);

T = length(targ_tref);

re = zeros(T,4);
%过去一周收益率，本征值，未来一周收益率
for i = 1:T
    [~,ticker] = get_300_tickets_update(targ_tref(i),ticker_300,t_300,datenum_300);
    [t1,t1_ind] = get_trading_date_interval(tref,targ_tref(i),num1); %过去一周
    [t2,t2_ind] = get_trading_date_interval(tref,targ_tref(i),num2); %未来一周
    re(i,1) = close_price_300(t1_ind(end))/close_price_300(t1_ind(1))-1;
    re(i,3) = close_price_300(t2_ind(end))/close_price_300(t2_ind(1))-1;   
    
    t3 = get_trading_date_interval(tref,targ_tref(i),num3); %过去60天
    [X,del_ind] = get_history_300_data(ticker,t3(1),t3(end),length(t3));
    
    [mu,Phi,pred,R2] = dmd_method(X);
    re(i,4) = R2;
    re(i,2) = mu(1,1);
    %过去，mu，未来，R2
    sprintf('%d-%d',i,T)
end




