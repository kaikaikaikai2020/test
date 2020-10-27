clear
dN = 'data_pro';
tn = 'main_index_s42';
tN = sprintf('%s.%s',dN,tn);
var_info = {'index_id','ticker','tradeDate','openPrice','highPrice','lowPrice','closePrice','volume'};

pn = 'E:\BaiduNetdiskDownload\data';
fn = dir(fullfile(pn,'*.xlsx'));
b = [fn.bytes];
fn = {fn.name}';
[b,ia] = sort(b);
fn = fn(ia);
id = cellfun(@(x) contains(x,'$'),fn);
fn = fn(~id);
T = length(fn);
for i = 1%6:T
    
    sub_data=pb_xls_data(fullfile(pn,fn{i}));
    sub_index = strsplit(fn{i},' ');
    sub_index = sub_index{1};
    
    T1 = length(sub_data.stocks);
    
    temp_stocks = sub_data.stocks;
    for j = 1:T1
        temp = strsplit(temp_stocks{j},' ');
        temp_stocks(j) = temp(1);
    end
    
    if all(~strcmp(sub_index,{'AS51','Nifty'}))
        temp = max(cellfun(@length,temp_stocks));
        temp_str = ['%0.',num2str(temp),'d'];
        temp_stocks=cellfun(@(x) sprintf(temp_str,str2double(x)),temp_stocks,'UniformOutput',false);
    end
    
    sub_re = cell(T1,1);
    for j = 1:T1
        temp = [sub_data.tref,sub_data.tref,sub_data.tref,num2cell([sub_data.PX_OPEN(:,j),sub_data.PX_HIGH(:,j),...
            sub_data.PX_LOW(:,j),sub_data.PX_LAST(:,j),sub_data.PX_VOLUME(:,j)])];
        
        temp(:,1) = {sub_index};
        temp(:,2) = temp_stocks(j);
        
        v = cellfun(@isnan,temp(:,4:end));
        v = sum(v,2);
        v = v>0;
        
        sub_re{j} = temp(~v,:)';
    end
    sub_re = [sub_re{:}]';
    
    OK = datainsert_adair(tN,var_info,sub_re);
    sprintf('%d-%d',i,T)
    
    
end