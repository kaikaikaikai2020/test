%��gcforest������д�����ݿ⣬ֻ������һ��
%{
'tradingdate', 'date', 'NO', 'PRI', NULL, ''
'pool_name', 'varchar(10)', 'NO', 'PRI', NULL, ''
'method_name', 'varchar(10)', 'NO', 'PRI', NULL, ''
'f_val1', 'float', 'YES', '', NULL, ''
'f_val2', 'float', 'YES', '', NULL, ''
'f_val3', 'float', 'YES', '', NULL, ''
'f_va4', 'float', 'YES', '', NULL, ''
'f_va5', 'float', 'YES', '', NULL, ''
'f_f', 'float', 'YES', '', NULL, ''

����ʷ����ת�Ƶ��Լ����ݿ⣬���ټ�����
%}
%���ݲ���

clear
sql_str1 = ['insert into S37.s19_result(tradingdate,pool_name,method_name,f_val1,f_val2,f_val3,f_va4,f_va5,f_f) ',...
    'select * from S37.s19_result_S43bac where method_name = "gcf" order by tradingdate'];
exemysql(sql_str1)

sql_str2 = ['insert into S37.s19_signal(tradingdate,pool_name,method_name,symbol,f_val) ',...
    'select * from S37.s19_signal_S43bac where method_name = "gcf" order by tradingdate'];
exemysql(sql_str2)

%