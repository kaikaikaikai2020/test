clear
load yq_info.mat
T = length(tn_info);
for i = 1:T
    sql_str = tn_info{i};
    exemysql(sql_str);
end