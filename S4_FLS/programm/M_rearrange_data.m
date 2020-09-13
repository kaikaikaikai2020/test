%M_rearrange_data
clear 
load bank16_data
trade_time = sort(unique(X.tradingdate));
[~,~,targ_tick] = xlsread('bank_ticker.xlsx');
targ_tick_name = targ_tick(2:end,2);
targ_tick = targ_tick(2:end,1);

var_name = ['tradingdate',targ_tick'];
var_type = [{'string'},repmat({'double'},1,length(targ_tick))];


N = length(trade_time);
sz = [N length(var_name)];
X_matrix = table('Size',sz,'VariableTypes',var_type,'VariableNames',var_name);
X_matrix.tradingdate = trade_time;
T = length(targ_tick);
for i = 1:T
    sub_x= X(contains(X.ticket,targ_tick(i)),:);
    [~,ia,ib] = intersect(X_matrix.tradingdate,sub_x.tradingdate,'stable');
    X_matrix.(targ_tick{i})(ia) = sub_x.close(ib);
end

X = X_matrix{:,2:end};
X(eq(X,0)) = nan;

save blank_16_data_matrix X trade_time targ_tick targ_tick_name
