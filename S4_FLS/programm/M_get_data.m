%M_get_data
clear

var_name = {'ticket','tradingdate','open','high','low','close','volume','amount','turnover'};
var_type = [{'string','datetime'},repmat({'double'},1,7)];

t0 = datenum(2010,9,2);
tt = datenum(2014,3,4);
[~,~,targ_tick] = xlsread('bank_ticker.xlsx');
targ_tick = targ_tick(2:end,1);
tref = xlsread('tref.xlsx');
tref = tref(tref>=t0&tref<=tt);
T = length(tref);

N = ceil(60*4/5*length(targ_tick)*T*1.2);
sz = [N 9];
X = table('Size',sz,'VariableTypes',var_type,'VariableNames',var_name);

P_min = 5;
P_xls_name = '%s %dmin.csv';
cout_num = 0;
for i = 1:T
    
    P_pn = sprintf('H:\\datasets\\历史分钟数据\\历史分钟数据\\%d\\',year(tref(i)));
    
    P_time = datestr(tref(i),'yyyy-mm-dd');
    pn = fullfile(P_pn,P_time);
    
    for j = 1:1
        fn = sprintf(P_xls_name,P_time,P_min(j));
        sub_fn = fullfile(pn,fn);
        x = readtable(sub_fn,'HeaderLines',1);
        x.Properties.VariableNames = var_name;
        x1 = x(contains(x.ticket,targ_tick),:);
        m = size(x1,1);
        sub_ind = cout_num(j)+1:cout_num(j)+m;
        X(sub_ind,:) = x1;
        cout_num(j) = cout_num(j) + m;
    end
    
    %keyboard
    sprintf('%d-%d',i,T)
end
%for i = 1:3
    X(cout_num+1:end,:)=[];
%end