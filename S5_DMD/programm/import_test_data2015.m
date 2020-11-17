clear
load ticker_300_pool.mat ticker_300 t_300 datenum_300
sql_str = ['select closeprice from ycz_zhubi.stk_mkt_bwardquotation where symbol = ''%s'' and tradingdate >= ''%s'' and ',...
    'tradingdate <=''%s'' and filling < 2 order by tradingdate'];

t0 = datenum(2015,4,1);
[~,ticker] = get_300_tickets_update(t0,ticker_300,t_300,datenum_300);

T = length(ticker);

t0 = datenum(2015,4,1);
tt = datenum(2015,6,1);

del_ind = zeros(T,1);

for i = 1:T
    sub_sql_str = sprintf(sql_str,ticker{i},datestr(t0,'yyyy-mm-dd'),datestr(tt,'yyyy-mm-dd'));
    x = fetchmysql(sub_sql_str);
    
    if eq(i,1);
        X = zeros(T,length(x));
    end
    if ~isempty(x) && eq(length(x),size(X,2))
        X(i,:) = x';
    else
        del_ind(i) = 1;
    end
    
    sprintf('%d-%d',i,T)
    
end


X(eq(del_ind,1),:) = [];


