clear

for sel = 0:1
if eq(sel,0)
    run_mod = 'm';
else
    run_mod = 'f';
end
if strcmp(run_mod,'m')
    key_str = 'S42 指数验证 寻优参数';
else
    key_str = 'S42 指数验证 固定参数';
end
index_str = ['000001-上证综指,000002-上证A股,000003-上证B股,000004-上证工业,',...
    '000005-上证商业,000006-上证地产,000007-上证公用,000008-上证综合,000009-上证380,',...
    '000010-上证180,000011-上证基金,000012-上证国债,000013-上证企债,000015-上证红利,',...
    '000016-上证50,000020-上证中型企业,000090-上证流通,000132-上证100,000133-上证150,',...
    '000300-沪深300,000852-中证1000,000902-中证流通,000903-中证100,000904-中证200,',...
    '000905-中证500,000906-中证800,000907-中证700,000922-中证红利,399001-深证成指,',...
    '399002-深证深成指R,399004-深证100R,399005-深证中小板指,399006-创业板指,399007-深证300,',...
    '399008-中小300,399009-深证200,399010-深证700,399011-深证1000,399012-深证创业300,',...
    '399013-深市精选,399015-深证中小创新,399107-深证A指,399108-深证B指,399301-深信用债,',...
    '399302-深公司债,399306-深证ETF,399307-深证转债,399324-深证红利,399330-深证100,',...
    '399333-深证中小板R,399400-巨潮大中盘,399401-巨潮中小盘,399649-深证中小红利'];
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
    pn_write = fullfile(pwd,'计算结果');
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