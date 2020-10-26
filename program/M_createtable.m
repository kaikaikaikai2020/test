clear
dN = 'data_pro';
tn = 'main_index_s42';
var_info = {'index_id','ticker','tradeDate','openPrice','highPrice','lowPrice','closePrice','volume'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:3) = {'varchar(20)','varchar(10)','date'};
key_var = strjoin(var_info(1:3),',');
[OK1,OK2,OK3] = create_table_adair(dN,tn,var_info,var_type,key_var);


   