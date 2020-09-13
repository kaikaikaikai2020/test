function [X,del_ind] = get_index_com_data(ticker,sub_t,N)

ticker0 = ticker;
if isnumeric(sub_t)
    sub_t = cellstr(datestr(sub_t,'yyyy-mm-dd'));
end

date1 = sub_t{1};
date2 = sub_t{end};
ticker = cellfun(@(x) ['''',x,''''],ticker,'UniformOutput',false);
symbol_str = strjoin(ticker,',');


sql_str = ['select symbol,tradeDate,closeprice from yuqerdata.yq_dayprice where symbol in (%s) and tradedate >= ''%s'' and ',...
    'tradedate <=''%s'' order by tradedate'];

sub_sql_str = sprintf(sql_str,symbol_str,date1,date2);
x = fetchmysql(sub_sql_str,2);
T = length(ticker0);
X = zeros(T,N);
del_ind = zeros(T,1);
for i = 1:T
    sub_x = x(strcmp(x(:,1),ticker0(i)),2:3);
    if ~isempty(sub_x)
        temp = nan(size(sub_t));
        [~,ia,ib] = intersect(sub_x(:,1),sub_t);
        temp(ib) = cell2mat(sub_x(ia,2));
        temp = fillmissing(temp,'previous');
        if isnan(temp(1))
            del_ind(i) = 1;
        else
            X(i,:) =  temp';
        end
    else
        del_ind(i) = 1;
    end
    

end
X(eq(del_ind,1),:) = [];