function [X,del_ind] = get_history_300_data(ticker,t1,t2,N)

ticker0 = ticker;

date1 = datestr(t1,'yyyy-mm-dd');
date2 = datestr(t2,'yyyy-mm-dd');
ticker = cellfun(@(x) ['''',x,''''],ticker,'UniformOutput',false);
symbol_str = strjoin(ticker,',');


sql_str = ['select symbol,closeprice from ycz_zhubi.stk_mkt_bwardquotation where symbol in (%s) and tradingdate >= ''%s'' and ',...
    'tradingdate <=''%s'' and filling < 2 order by tradingdate'];

sub_sql_str = sprintf(sql_str,symbol_str,date1,date2);
x = fetchmysql(sub_sql_str,2);

T = length(ticker0);
X = zeros(T,N);
del_ind = zeros(T,1);
for i = 1:T
    sub_x = x(strcmp(x(:,1),ticker0(i)),2);
    if eq(length(sub_x),N)
        X(i,:) = cell2mat(sub_x');
    else
        del_ind(i) = 1;
    end
    

end
X(eq(del_ind,1),:) = [];