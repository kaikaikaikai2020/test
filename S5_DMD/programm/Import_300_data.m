%import 300 com
clear
[~,~,x] = xlsread('csi300_compo_weights.csv');
t = x(2:end,3);
tickers = x(2:end,6);
ticker = cellfun(@(x) x(1:end-5),tickers,'UniformOutput',false);
ticker = cellfun(@(x) x(end-5:end),ticker,'UniformOutput',false);
t_300 = unique(t);
t_u_num = datenum(t_300);
T = length(t_300);

[datenum_300,ia] = sort(t_u_num);
t_300 = t_300(ia);

ticker_300 = cell(T,1);

for i = 1:length(t_300)
    ticker_300{i} = ticker(strcmp(t,t_300(i)));
end

save ticker_300_pool ticker_300 datenum_300 t_300