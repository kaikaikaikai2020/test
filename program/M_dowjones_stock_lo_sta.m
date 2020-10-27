clear

for sel = 1
if eq(sel,0)
    run_mod = 'm';
else
    run_mod = 'f';
end
if strcmp(run_mod,'m')
    key_str = 'S42 dowjones 寻优参数 多';
else
    key_str = 'S42 dowjones 固定参数 多';
end

sql_str = 'select distinct(symbol) from S42.S42_dowjones_lo where c_m = "%s"';
symbols = fetchmysql(sprintf(sql_str,run_mod),2);

T_symbols = length(symbols);
sql_str1 = 'select tradeDate,chg from S42.S42_dowjones_lo where symbol = "%s" and c_m = "%s" and g_num = 1';

sta_re2 = cell(T_symbols+1,1);
write_sel = true;
if write_sel
    pn_write = fullfile(pwd,'计算结果');
    if ~exist(pn_write,'dir')
        mkdir(pn_write)
    end
    obj_wd = wordcom(fullfile(pn_write,sprintf('%s.doc',key_str)));
    xls_fn = fullfile(pn_write,sprintf('%s.xlsx',key_str));
end
           
%将外汇结果综合起来作图
tref = cell(T_symbols,1);
Y = cell(size(tref));
for i = 1:T_symbols
    sub_sql_str = sprintf(sql_str1,symbols{i},run_mod);
    sub_x = fetchmysql(sub_sql_str,2);
    r_day = cell2mat(sub_x(:,2));
    r_c = cumprod(1+r_day);
    tref{i} = sub_x(:,1)';
    Y{i} = r_day;
    
    t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],sub_x(:,1),'UniformOutput',false);
    T = length(t_str);
    h=figure;
    title_str = symbols{i};
    plot(r_c,'-','LineWidth',2);
    set(gca,'xlim',[0,T]);
    set(gca,'XTick',floor(linspace(1,T,15)));
    set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
    set(gca,'XTickLabelRotation',90)    
    setpixelposition(h,[223,365,1345,420]);
    box off
    title(title_str)
    if write_sel
        obj_wd.pasteFigure(h,title_str);
    end
    [v0,v_str0] = curve_static(r_c,[],false);
    [v,v_str] = ad_trans_sta_info(v0,v_str0); 
    result2 = [v_str;v]';
    result = [{'',title_str};result2];
    if ~eq(i,1)
        result = result(:,2);
    end
    sta_re2{i} = result;
    sprintf('%s %d-%d',key_str,i,T_symbols)   
end

tref1 = unique([tref{:}]');
y = cell(T_symbols,1);
for i = 1:T_symbols
    sub_t = tref{i};
    sub_x = Y{i};
    [~,ia,ib] = intersect(tref1,sub_t);
    sub_y = zeros(size(tref1));
    sub_y(ia) = sub_x(ib);
    y{i} = sub_y;    
end
%%%%%%平均收益曲线
y = [y{:}];
r_c = mean(y,2);
r_c = cumprod(1+r_c);
t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref1,'UniformOutput',false);
T = length(t_str);
h=figure;
title_str = '组合曲线';
plot(r_c,'-','LineWidth',2);
set(gca,'xlim',[0,T]);
set(gca,'XTick',floor(linspace(1,T,15)));
set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
set(gca,'XTickLabelRotation',90)    
setpixelposition(h,[223,365,1345,420]);
box off
title(title_str)
if write_sel
    obj_wd.pasteFigure(h,title_str);
end
[v0,v_str0] = curve_static(r_c,[],false);
[v,v_str] = ad_trans_sta_info(v0,v_str0); 
result2 = [v_str;v]';
result = [{'',title_str};result2];
result = result(:,2);
sta_re2{end} = result;


y = [sta_re2{:}];
y = y';
if write_sel
    obj_wd.CloseWord();
    xlswrite(xls_fn,y);
end
end