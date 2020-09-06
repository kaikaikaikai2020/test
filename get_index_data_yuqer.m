function [index_data,index_code] = get_index_data_yuqer(index_name,t1,t2)
    if nargin < 2
        t1 = '0000-00-01';
    end
    if nargin < 3
        t2='3000-10-10';
    end
    
    if isnumeric(t1)
        t1 = datestr(t1,'yyyy-mm-dd');
    end
    if isnumeric(t2)
        t2 = datestr(t2,'yyyy-mm-dd');
    end
    
    data = containers.Map({'上证指数','沪深300','中证500','创业板指','中小板指','中证1000',...
        '上证综指','上证50','深次新股','深证成指','中证全指','中证流通'},{'sh000001','sh000300','sh000905','sz399006','sz399005','sh000852',...
        'sh000001','sh000016','sz399678','sz399001','sz000985','sz000902'});
    index_code = data(index_name);
    index_code = index_code(3:end);
    tn = 'yuqerdata.yq_index';
    sql_str = ['select tradedate,openIndex,closeIndex from %s',10,...
            'where symbol = ''%s'' and tradedate >=''%s''',10,...
            'and tradedate <= ''%s'' order by tradedate'];
    index_data = fetchmysql(sprintf(sql_str,tn,index_code,t1,t2),2);
    
    
    
    
end

