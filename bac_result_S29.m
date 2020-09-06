classdef bac_result_S29 < handle
    properties
        factors_S29 = [];
        factors_S29_dir= [1,1,1];
        factors_S29_info = {'双向选择','交叉不限制行业','交叉限制行业'};
        symbol_pool_S29 = 'symbol_pool_S22'
        symbol_pool_all = {   [],    '000905','000300'};
        symbol_pool_info = {'全市场','中证500','沪深300'};
        obj_S29 = [];
    end
    
    methods
        function obj = bac_result_S29()
            %S29
            tn_num_29 = length(obj.factors_S29_info);
            obj.factors_S29=cell(tn_num_29,1);
            for i = 1:tn_num_29
                obj.factors_S29{i} = sprintf('S29f%0.2d',i);
            end            
        end
        function get_all_results(obj)
            obj.select_symbols();
            obj.get_group_return();
            obj.get_report();
        end
        function select_symbols(obj)
            tn = 'S29_signal';
            var_info = {'tradingdate','pool_name','method_name','symbol'};
            key_str = 'S29';
            tn_result = sprintf('S37.%s',tn);        
            sql_str_t0='select distinct(tradingdate) from %s where method_name=''%s''';
            
            %sql_str_t0_0 = ['select (min(pub_date)) from S29.factor_yuqer_com ',...
            %    'group by factor_name order by pub_date desc limit 1'];
            %t0 = fetchmysql(sql_str_t0_0,2);            
            t0 = '2008-08-01';
            tref_month = yq_methods.get_month_end();
            tref = tref_month(datenum(tref_month)>datenum(t0));
            
            for i = 1:3
                if isempty(obj.obj_S29)
                    obj.obj_S29 = S29_sel_symbol();
                end
                
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,obj.factors_S29{i}),2);
                tref_do = setdiff(tref,tref_complete);
                T_tref_do = length(tref_do);                
                parfor j = 1:T_tref_do
                    sub_t = tref_do{j};
                    re1 = cell(size(obj.symbol_pool_info));
                    for k = 1:length(obj.symbol_pool_info)
                        sprintf('%s:%d-%d-%d-%d',key_str,j,T_tref_do,i,3)
                        if eq(i,1)
                            symbol = obj.obj_S29.get_symbol_m1(sub_t,obj.symbol_pool_all{k});
                        elseif eq(i,2)
                            symbol = obj.obj_S29.get_symbol_m3(sub_t,obj.symbol_pool_all{k});
                        else
                            symbol = obj.obj_S29.get_symbol_m4(sub_t,obj.symbol_pool_all{k});
                        end
                        if isempty(symbol)
                            continue
                        end
                        sub_re = symbol(:,[1,1,1,1]);
                        sub_re(:,1) = {sub_t};
                        sub_re(:,2) = obj.symbol_pool_info(k);
                        sub_re(:,3) = obj.factors_S29(i);
                        re1{k} = sub_re';
                    end
                    re1 = [re1{:}]';
                    if ~isempty(re1)
                        datainsert_adair(tn_result,var_info,re1);
                    end
                end                
            end            
        end
        function get_group_return(obj)
            if nargin < 2
                method_id = 29;
            end
            
            key_str = sprintf('S%d回测结果',method_id);
            tn = sprintf('S%d_result',method_id);
            tn2 = sprintf('S%d_signal',method_id);
            
            var_info = {'tradingdate','pool_name','method_name','f_f'};
            
            sql_str1 = 'select tradingdate from S37.%s where pool_name =''%s'' and method_name = ''%s'' order by tradingdate limit 1';
            sql_str2 = 'select symbol from S37.%s where pool_name=''%s'' and method_name = ''%s'' and tradingdate=''%s''';
            sql_str3 = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate =''%s''';
            sql_str4 = 'select distinct(tradingdate) from S37.%s where pool_name=''%s'' and method_name = ''%s'' order by tradingdate';
            
            for index_sel = 1:3
                index_name = obj.symbol_pool_info{index_sel};
                factor_num = length(obj.factors_S29);
                for i = 1:factor_num
                    sub_factor_name = obj.factors_S29{i};
                    t0 = fetchmysql(sprintf(sql_str1,tn2,index_name,sub_factor_name),2);
                    t0 = t0{1};
                    tref_f = fetchmysql(sprintf(sql_str4,tn2,index_name,sub_factor_name),2);
                    tref_f_num = datenum(tref_f);

                    tref = yq_methods.get_tradingdate(t0);
                    tref_complete = 'select tradingdate from S37.%s where method_name = ''%s'' and pool_name = ''%s''';
                    tref_complete = fetchmysql(sprintf(tref_complete,tn,sub_factor_name,index_name),2);
                    tref = setdiff(tref,tref_complete);

                    T_tref = length(tref);
                    F = cell(T_tref);
                    parfor j = 1:T_tref
                        sub_t = tref{j};
                        ind = find(tref_f_num<datenum(sub_t),1,'last');
                        if isempty(ind)
                            r = 0;
                        else
                            sub_t2 = tref_f{ind};%因子时间
                            f1 = fetchmysql(sprintf(sql_str2,tn2,index_name,sub_factor_name,sub_t2),2);
                            if isempty(f1)
                                r = 0;
                            else
                                %这里需要修正
                                y1 = fetchmysql(sprintf(sql_str3,sub_t),2);  
                                [~,ia] = intersect(y1(:,1),f1);
                                r = mean(cell2mat(y1(ia,end)));
                                if isnan(r) || isinf(r)
                                    r = 0;
                                end
                            end
                        end
                        f = num2cell(r(:,[1,1,1,1:end]));
                        f(:,1) = {sub_t};
                        f(:,2) = {index_name};
                        f(:,3) = {sub_factor_name};
                        F{j} = f';                    
                        sprintf('%s计算每日分组回测结果-%s %d-%d %d-%d %s',key_str,sub_t,j,T_tref,i,factor_num,index_name)
                    end 
                    F = [F{:}]';                    
                    if ~isempty(F)
                        sprintf('%s每日回测结果写入数据库%0.2d-%d',key_str,i,factor_num)
                        datainsert_adair(sprintf('S37.%s',tn),var_info,F)
                    end
                end
            end
        end
        function get_report(obj,method_id)  
            if nargin < 2
                method_id = 29;
            end
            key_str = sprintf('S%d回测结果',method_id);
            tn = sprintf('S%d_result',method_id);            
            sql_str1 = 'select * from S37.%s where method_name=''%s'' order by tradingdate'; 
            
            file_name = sprintf('%s因子表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            factor_name = obj.factors_S29;
            T_factor = length(factor_name);            
            sta_re = cell(T_factor,1);
            for i = 1:T_factor                
                sub_factor_name = factor_name{i};
                x = fetchmysql(sprintf(sql_str1,tn,sub_factor_name),2);
                sub_re = cell(1,3);
                for j = 1:3
                    sub_x = x(strcmp(x(:,2),obj.symbol_pool_info(j)),:);
                    tref = sub_x(:,1);
                    r_day = cell2mat(sub_x(:,4:end));
                    r_day = month_fee_update(tref,r_day);
                    title_str = sprintf('%s-%s-%s',key_str,sub_factor_name,obj.symbol_pool_info{j});
                    h1 = obj.draw_figure(tref,r_day,title_str);
                    obj_wd.pasteFigure(h1,' ');
                    [v0,v_str0] = curve_static(cumprod(1+r_day(:,end)));
                    [v,v_str] = obj.ad_trans_sta_info(v0,v_str0); 
                    sub_re{j} = [[{''};v_str'],[{title_str};v']];
                end
                sta_re{i} = [sub_re{:}];
            end
            obj_wd.CloseWord()
            
            sta_re = [sta_re{:}];
            sta_re = sta_re(:,[1,2:2:end])';
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re)            
        end

    end
    methods(Static)
        function h1 = draw_figure(tref,r_day,title_str)
            r_c = cumprod(1+r_day);
            t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref,'UniformOutput',false);
            h1=figure;
            bpcure_plot_updateV2(t_str,r_c(:,end))
            setpixelposition(gcf,[223,365,1345,420]);
            title(sprintf('%s 净值与回撤',title_str));
        end
        function [v,v_str0] = ad_trans_sta_info(v0,v_str0)
            v=v0;
            id1 = [1:5,8,11,12,13,15];
            v(id1) = v0(id1) * 100;
            v = num2cell(v);
            v_str0(id1) = cellfun(@(x) [x,'(%)'],v_str0(id1),'UniformOutput',false);
            id2 = [6,7,10];
            v(id2) = cellfun(@(x) sprintf('%d',x),v(id2),'UniformOutput',false);
            id3 = 1:length(v);
            id3(id2) = [];
            v(id3) = cellfun(@(x) sprintf('%0.2f',x),v(id3),'UniformOutput',false);
        end
    end
    
end