function [t,ticker,t_str] = get_300_tickets_update(t0,ticker_300,t_300,datenum_300)

%load ticker300.mat t ticker
if nargin < 2
    load ticker_300_pool.mat ticker_300 t_300 datenum_300
end
% [~,~,x] = xlsread('沪深300指数历史年分成分股名单.xlsx');
% 
% x(1,:) = cellfun(@num2str,x(1,:),'UniformOutput',false);
% x(2:end,1:end-2) = cellfun(@(x) num2str(x,'%0.6d'),x(2:end,1:end-2),'UniformOutput',false);
% 
% t = datenum(x(1,:),'yyyymm');
% ticker = x(2:end,:);

ind=  find(datenum_300<t0,1,'last');
if isempty(ind)
    ind = 1;
end
t=datenum_300(ind);
t_str = t_300(ind);
ticker = ticker_300{ind};