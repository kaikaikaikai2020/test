%合成dowjones的日线数据
clear
%{
dN = 'S42';
tn = 'dowjones_dayly';
var_info = {'tradeDate','symbol','openPrice','highestPrice','lowestPrice',...
    'closePrice','totalVolume','totalQuantity','totalTradeCount'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:2) = {'date','varchar(20)'};
key_var = 'symbol,tradeDate';
[OK1,OK2,OK3] = create_table_adair(dN,tn,var_info,var_type,key_var);
%}
tn = 'S42.dowjones_dayly';
var_info = {'tradeDate','symbol','openPrice','highestPrice','lowestPrice',...
    'closePrice','totalVolume','totalQuantity','totalTradeCount'};
symbols = fetchmysql('select distinct(Ticker) from index_comp_price_temp.american_djia',2);
T_symbols = length(symbols);
for i = 23:T_symbols
    sub_symbol = symbols{i};
    sql_str1 = 'select *,date(tradingdate) from index_comp_price_temp.american_djia where ticker = "%s" order by tradingdate';
    x = fetchmysql(sprintf(sql_str1,sub_symbol),2);
    
    x = x(:,[end,2:end-1]);
    
    tref = unique(x(:,1));
    T_tref = length(tref);
    y = cell(T_tref,1);
    parfor j = 1:T_tref
        sub_ind = strcmp(x(:,1),tref(j));
        sub_x = x(sub_ind,:);
        sub_x_v = cell2mat(sub_x(:,3:end));
        sub_x1 = sub_x_v(1,1);
        sub_x2 = max(sub_x_v(:,2));
        sub_x3 = min(sub_x_v(:,3));
        sub_x4 = sub_x_v(end,4);
        sub_x5 = sum(sub_x_v(:,5:end));
        sub_y = [sub_x(1,1:2),num2cell([sub_x1,sub_x2,sub_x3,sub_x4,sub_x5])];
        y{j} = sub_y';        
    end
    y(~eq(cellfun(@length,y),9)) = [];
    y = [y{:}]';
    datainsert_adair(tn,var_info,y)
    sprintf('合成dowjones日线数据 %d-%d',i,T_symbols)
    
end
