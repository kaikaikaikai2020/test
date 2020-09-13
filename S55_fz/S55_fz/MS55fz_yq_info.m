clear
dn = 'yuqerdata';
tn = fetchmysql(sprintf('show tables from %s',dn),2);
T = length(tn);
tn_info = cell(T,1);
for i = 1:T
    sql_str = fetchmysql(sprintf('show create table %s.%s',dn,tn{i}),2);
    sql_str = sql_str{2};
    sql_str = strrep(sql_str,tn{i},sprintf('%s.%s',dn,tn{i}));
    tn_info{i} = sql_str;
end

save yq_info tn_info