clear

for sel = 0:1
if eq(sel,0)
    run_mod = 'm';
else
    run_mod = 'f';
end
if strcmp(run_mod,'m')
    key_str = 'S42 ָ����֤ Ѱ�Ų���';
else
    key_str = 'S42 ָ����֤ �̶�����';
end
index_str = ['000001-��֤��ָ,000002-��֤A��,000003-��֤B��,000004-��֤��ҵ,',...
    '000005-��֤��ҵ,000006-��֤�ز�,000007-��֤����,000008-��֤�ۺ�,000009-��֤380,',...
    '000010-��֤180,000011-��֤����,000012-��֤��ծ,000013-��֤��ծ,000015-��֤����,',...
    '000016-��֤50,000020-��֤������ҵ,000090-��֤��ͨ,000132-��֤100,000133-��֤150,',...
    '000300-����300,000852-��֤1000,000902-��֤��ͨ,000903-��֤100,000904-��֤200,',...
    '000905-��֤500,000906-��֤800,000907-��֤700,000922-��֤����,399001-��֤��ָ,',...
    '399002-��֤���ָR,399004-��֤100R,399005-��֤��С��ָ,399006-��ҵ��ָ,399007-��֤300,',...
    '399008-��С300,399009-��֤200,399010-��֤700,399011-��֤1000,399012-��֤��ҵ300,',...
    '399013-���о�ѡ,399015-��֤��С����,399107-��֤Aָ,399108-��֤Bָ,399301-������ծ,',...
    '399302-�˾ծ,399306-��֤ETF,399307-��֤תծ,399324-��֤����,399330-��֤100,',...
    '399333-��֤��С��R,399400-�޳�������,399401-�޳���С��,399649-��֤��С����'];
temp = strsplit(index_str,',');
index_info = cellfun(@(x) strsplit(x,'-'),temp,'UniformOutput',false);
symbol_pool_all = cellfun(@(x) x{1},index_info,'UniformOutput',false);
symbol_pool_info = cellfun(@(x) x{2},index_info,'UniformOutput',false);

sql_str = 'select distinct(symbol) from S42.S42_index where c_m = "%s"';
symbols = fetchmysql(sprintf(sql_str,run_mod),2);
T_symbols = length(symbols);
sql_str1 = 'select tradeDate,chg from S42.S42_index where symbol = "%s" and c_m = "%s"';

sta_re2 = cell(T_symbols,1);
write_sel = true;
if write_sel
    pn_write = fullfile(pwd,'������');
    if ~exist(pn_write,'dir')
        mkdir(pn_write)
    end
    obj_wd = wordcom(fullfile(pn_write,sprintf('%s.doc',key_str)));
    xls_fn = fullfile(pn_write,sprintf('%s.xlsx',key_str));
end
           

for i = 1:T_symbols
    sub_sql_str = sprintf(sql_str1,symbols{i},run_mod);
    sub_x = fetchmysql(sub_sql_str,2);
    r_day = cell2mat(sub_x(:,2));
    
    r_c = cumprod(1+r_day);
    t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],sub_x(:,1),'UniformOutput',false);

    T = length(t_str);
    h=figure;
    title_str = symbol_pool_info{strcmp(symbol_pool_all,symbols(i))};
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
    %Y2{i_sym} = [sub_tref,num2cell([y_c,y_c2])];
    
end
y = [sta_re2{:}];
y = y';
if write_sel
    obj_wd.CloseWord();
    xlswrite(xls_fn,y);
end
end