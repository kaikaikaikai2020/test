clear
dN = 'S5';
tn = 'S5_para';
%tradeDate,过去一周，未来一周，正确率，R2，Mu,window
var_info = {'tradingdate','r_b5','r_a5','r1','r2','mu','wid'};
var_type = cell(size(var_info));
var_type(:) = {'float'};
var_type(1) = {'date'};
%key_var = {'symbol','tradingdate'};
%key_var = strjoin(var_info([1,2,3]),',');
key_var = var_info{1};
create_table_adair(dN,tn,var_info,var_type,key_var)

load dmd_regress_re_window_update3.mat
re(:,5) = abs(re(:,5));
re(:,[1:4,6:end]) = real(re(:,[1:4,6:end]));

x = [cellstr(datestr(targ_tref,'yyyy-mm-dd')),num2cell(re)];
conn = mysql_conn();
datainsert(conn,sprintf('%s.%s',dN,tn),var_info,x);
close(conn)