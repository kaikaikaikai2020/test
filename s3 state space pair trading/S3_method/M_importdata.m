clear
% pn = 'H:\datasets\历史分钟数据\历史分钟数据\2013\2013-07-01';
% fn = '2013-07-01 5min.csv';
var_name = {'ticket','tradingdate','open','high','low','close','volume','amount','turnover'};
var_type = [{'string','datetime'},repmat({'double'},1,7)];
tref = xlsread('tref.xlsx');
targ_tick = {'sh600109','sz002500'};
t0 = datenum(2013,7,1);
tt = datenum(2013,10,22);
tref = tref(tref>=t0&tref<=tt);
T = length(tref);

N = 60*4/5*2*2*length(tref);
sz = [N 9];

X = cell(1,3);
for i = 1:3
    X{i} = table('Size',sz,'VariableTypes',var_type,'VariableNames',var_name);
end
cout_num = zeros(1,3);

P_min = [5,15,30];
P_xls_name = '%s %dmin.csv';
P_pn = 'H:\datasets\历史分钟数据\历史分钟数据\2013\';



for i = 1:T
    P_time = datestr(tref(i),'yyyy-mm-dd');
    pn = fullfile(P_pn,P_time);
    
    for j = 1:3
        fn = sprintf(P_xls_name,P_time,P_min(j));
        sub_fn = fullfile(pn,fn);
        x = readtable(sub_fn,'HeaderLines',1);
        x.Properties.VariableNames = var_name;
        x1 = x(strcmp(x.ticket,targ_tick(1))|strcmp(x.ticket,targ_tick(2)),:);
        m = size(x1,1);
        sub_ind = cout_num(j)+1:cout_num(j)+m;
        X{j}(sub_ind,:) = x1;
        cout_num(j) = cout_num(j) + m;
    end
    
    %keyboard
    sprintf('%d-%d',i,T)
end
for i = 1:3
    X{i}(cout_num(i)+1:end,:)=[];
end
save data_S3 X tref



