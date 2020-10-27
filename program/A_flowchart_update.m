%{
补充指数测试
ls-test
lo-test_lo
%}

clear

symbol_pool = {'AS51', 'hscei', 'hsi', 'msci', 'nky', 'topix','Nifty'};
T_symbol_pool = length(symbol_pool);
t=datestr(now,'yyyy-mm-dd');

for sel = 0:1
    if eq(sel,0)
        run_mod = 'f';
        key_str = 'S42 补充指数-经典模型-多';
        sub_tn = 'S42.s42_index_test_lo';
    else
        run_mod = 'f';
        key_str = 'S42 补充指数-经典模型-多空';
        sub_tn = 'S42.s42_index_test';
    end

    sql_str = 'select symbol,tradeDate,chg from %s where index_id="%s" and  g_num=1 and c_m = "%s"';
    tref = yq_methods.get_tradingdate('2010-01-01',t);
    sta_re2 = cell(T_symbol_pool,1);
    write_sel = true;
    if write_sel
        pn_write = fullfile(pwd,'计算结果');
        if ~exist(pn_write,'dir')
            mkdir(pn_write)
        end
        obj_wd = wordcom(fullfile(pn_write,sprintf('%s.doc',key_str)));
        xls_fn = fullfile(pn_write,sprintf('%s.xlsx',key_str));
    end

    for i = 1:T_symbol_pool
        sub_symbol = symbol_pool{i};

        y = fetchmysql(sprintf(sql_str,sub_tn,sub_symbol,run_mod),3);
        y1= unstack(y,'chg','symbol');
        tref =  y1.tradeDate;
        r_day = table2array(y1(:,2:end));
        r_day(isnan(r_day)) = 0;
        r_day = mean(r_day,2);

        [tref,ia] = sort(tref);
        r_day = r_day(ia);

        ind=datenum(tref)>datenum(2010,1,1);
        tref = tref(ind,:);
        r_day = r_day(ind,:);

        r_c = cumprod(1+r_day);
        t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref,'UniformOutput',false);

        T = length(t_str);
        h=figure;
        title_str = sub_symbol;
        plot(r_c,'-','LineWidth',2);
        set(gca,'xlim',[0,T]);
        set(gca,'XTick',floor(linspace(1,T,15)));
        set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
        set(gca,'XTickLabelRotation',90)    
        setpixelposition(h,[223,365,1345,420]);
        box off
        title(title_str)    
        [v0,v_str0] = curve_static(r_c,[],false);

        [v,v_str] = ad_trans_sta_info(v0,v_str0); 
        result2 = [v_str;v]';
        result = [{'',title_str};result2];
        if ~eq(i,1)
            result = result(:,2);
        end
        sta_re2{i} = result;
        if write_sel
            obj_wd.pasteFigure(h,title_str);
        end

    end
    y = [sta_re2{:}];
    y = y';
    if write_sel
        obj_wd.CloseWord();
        xlswrite(xls_fn,y);
    end
end