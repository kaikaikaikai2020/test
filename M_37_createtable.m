%clear
dN= 'S37';
tn = 'S7_signal';

var_info = {'code1','code2','tradingdate','f_val'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:4) = {'varchar(10)','varchar(10)','date','int'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)


tn = 'S19_signal';

var_info = {'tradingdate','pool_name','method_name','symbol','f_val'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:5) = {'date','varchar(10)','varchar(10)','varchar(10)','int'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3,4]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)

tn = 'S21_signal';

var_info = {'tradingdate','pool_name','method_name','symbol','f_val'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:5) = {'date','varchar(10)','varchar(10)','varchar(10)','int'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3,4]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)


tn = 'S19_result';
var_info = {'tradingdate','pool_name','method_name','f_val1','f_val2',...
                'f_val3','f_va4','f_va5','f_f'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:3) = {'date','varchar(10)','varchar(10)'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)

tn = 'S21_result';
var_info = {'tradingdate','pool_name','method_name','f_val1','f_val2',...
                'f_val3','f_va4','f_va5','f_f'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:3) = {'date','varchar(10)','varchar(10)'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)

tn = 'S29_signal';
var_info = {'tradingdate','pool_name','method_name','symbol'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:4) = {'date','varchar(10)','varchar(10)','varchar(10)'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3,4]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)

tn = 'S29_result';
var_info = {'tradingdate','pool_name','method_name','f_f'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:3) = {'date','varchar(10)','varchar(10)'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)


tn = 'S34_signal';
var_info = {'tradingdate','pool_name','method_name','symbol','w'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:4) = {'date','varchar(10)','varchar(20)','varchar(10)'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3,4]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)

tn = 'S34_result';
var_info = {'tradingdate','pool_name','method_name','f_f','f_ref'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1:3) = {'date','varchar(10)','varchar(20)'};
%key_var = {'symbol','tradingdate'};
key_var = strjoin(var_info([1,2,3]),',');
%key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)
