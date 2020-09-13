function [t,ticker] = get_300_tickets(t0)

load ticker300.mat t ticker
% [~,~,x] = xlsread('沪深300指数历史年分成分股名单.xlsx');
% 
% x(1,:) = cellfun(@num2str,x(1,:),'UniformOutput',false);
% x(2:end,1:end-2) = cellfun(@(x) num2str(x,'%0.6d'),x(2:end,1:end-2),'UniformOutput',false);
% 
% t = datenum(x(1,:),'yyyymm');
% ticker = x(2:end,:);

ind=  find(t<t0,1,'last');
if isempty(ind)
    ind = 1;
end
t=t(ind);
ticker = ticker(:,ind);