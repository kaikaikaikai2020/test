%S46-part1 五等分，周度
classdef bac_result_S46<handle
    properties
        obj_S37 = bac_tool_S37();
        symbol_pool = 'symbol_pool_S46';
        factors = {'period_mean_distance'};
        factors_full = {'S46_f1'};
        tns = {'S46.S46f1'};
        tns_info = {'网络动量因子'};
        zn_sel = 1;
        f_dir = {'-'};
        group_return_tn = {'factor_group5_return_S46'};
    end
    methods
        function get_all_results(obj)
            %part1
            %python因子合成部分，合并发过来          
            dos('python S46_part1_signal.py')
            %生成表格 股票池 收益 
            obj.create_table()
            %选股和写入收益
            obj.select_symbols_S46_f1()
            obj.get_group_return()
            %生成报告
            obj.get_report()
            %part2 指数部分
            dos('python S46_part2_index_update.py')
            obj.index_ef_result()
        end
        function create_table(obj)        
            obj.obj_S37.create_symbol_pool_table(obj.symbol_pool);
            obj.create_group_return_result_table()
        end
        function create_group_return_result_table(obj)
            dN = 'S37';
            for i = 1%1:2
                tn = obj.group_return_tn{i};
                var_info = obj.obj_S37.group_return_var{i};
                var_type = cell(size(var_info));
                var_type(:) = {'float'};
                var_type(1:3) = {'varchar(20)','date','varchar(8)'};
                %key_var = {'symbol','tradingdate'};
                key_var = strjoin(var_info([1,2,3]),',');
                %key_var = var_info{1};
                create_table_adair(dN,tn,var_info,var_type,key_var)
            end
        end
        
        function index_ef_result(obj)
            tn = 'S46.S46_part2_index';
            index_code_pool = {'000001','000905','000300'};
            sql_str = 'select tradeDate,cum_rtn_gb from %s where ticker = "%s" order by tradeDate';
            
            key_str = 'S46-指数择时';
            file_name = sprintf('%s表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            T_factor = length(index_code_pool);            
            sta_re = cell(T_factor,1);            
            for i = 1:T_factor
                sub_index_code = index_code_pool{i};
                sub_sql_str = sprintf(sql_str,tn,sub_index_code);
                x = fetchmysql(sub_sql_str,2);
                t_str = x(:,1);
                t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),t_str,'UniformOutput',false);
                y_c = cell2mat(x(:,2));
                r_c = zeros(size(y_c));
                r_c(2:end) = y_c(2:end)./y_c(1:end-1)-1;
                r_c(1) = 0;                
                h = obj.plot_curve(t_str,y_c,sub_index_code);
                obj_wd.pasteFigure(h,sub_index_code);
                [v0,v_str0] = curve_static(cumprod(1+r_c(:,end)));
                [v,v_str] = obj.obj_S37.ad_trans_sta_info(v0,v_str0); 
                sta_re{i} = [[{''};v_str'],[{sub_index_code};v']];
            end
            obj_wd.CloseWord()            
            sta_re = [sta_re{:}];
            sta_re = sta_re(:,[1,2:2:end])';
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re)
            
            
        end
        
        %按照池子选择
        function select_symbols_S46_f1(obj)            
            T_f = length(obj.tns);
            tref_week = fetchmysql('select distinct(tradeDate) from S46.S46f1 order by tradeDate ',2);
            if ~isempty(tref_week)
                tref_week = tref_week(datenum(tref_week)>=datenum(2014,1,1));
            end
            sql_str = 'select distinct(tradeDate) from %s';
            sql_str_t0='select distinct(tradingdate) from S37.%s where factor_name=''%s''';            
            sql_str_f = 'select ticker,%s%s from %s where tradeDate = ''%s''';
            for i = 1:T_f
                sub_key = obj.factors_full{i};
                sub_fdir = obj.f_dir{i};
                sub_fname = obj.factors{i};
                
                tN = obj.tns{i};  
                sub_zn_sel = obj.zn_sel(i);
                tref = fetchmysql(sprintf(sql_str,tN),2);
                tref = intersect(tref_week,tref);
                
                tref_complete = fetchmysql(sprintf(sql_str_t0,obj.symbol_pool,sub_key),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    
                    %get symbol
                    sub_t = tref_do{j};
                    sub_f = fetchmysql(sprintf(sql_str_f,sub_fdir,sub_fname,tN,sub_t),2);
                    f = obj.get_symbol(sub_key,sub_t,sub_f,sub_zn_sel);
                    datainsert_adair(sprintf('S37.%s',obj.symbol_pool),obj.obj_S37.var_info_symbol,f)
                    sprintf('S46因子%0.2d-%s选股结果写入数据库',i,sub_t)                    
                end                
            end
        end
        %中性化等操作
        function F = get_symbol(obj,sub_key,sub_t,x0,sub_zn_sel)
            if sub_zn_sel>0
                sub_zn_sel = true;
            else
                sub_zn_sel = false;
            end
            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.obj_S37.symbol_pool_info)
                sub_index = obj.obj_S37.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = obj.nero_test(x,sub_t,sub_zn_sel);
                y= obj.obj_S37.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = {sub_key};
            F(:,2) = {sub_t};
        end
        %get chg
        function get_group_return(obj)            
            sql_str1 = 'select tradingdate from S37.%s where factor_name=''%s'' order by tradingdate limit 1';
            sql_str2 = 'select symbol,id_a,id500,id300 from S37.%s where factor_name=''%s'' and tradingdate=''%s''';
            sql_str3 = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate =''%s''';
            sql_str4 = 'select distinct(tradingdate) from S37.%s where factor_name=''%s'' order by tradingdate';
            T_f = length(obj.factors);
            for i = 1:T_f
                sub_factor_name = obj.factors_full{i};
                sub_tn = obj.symbol_pool;
                t0 = fetchmysql(sprintf(sql_str1,sub_tn,sub_factor_name),2);
                t0 = t0{1};
                tref_f = fetchmysql(sprintf(sql_str4,sub_tn,sub_factor_name),2);
                tref_f_num = datenum(tref_f);
                
                tref = yq_methods.get_tradingdate(t0);
                tref_complete = 'select tradingdate from S37.%s where factor_name = ''%s'' and id_pool = ''全市场''';
                tref_complete = fetchmysql(sprintf(tref_complete,obj.group_return_tn{1},sub_factor_name),2);
                tref = setdiff(tref,tref_complete);
                
                T_tref = length(tref);
                chg_re = cell(T_tref,1);
                parfor j = 1:T_tref
                    sub_t = tref{j};
                    ind = find(tref_f_num<datenum(sub_t),1,'last');
                    if isempty(ind)
                        r = zeros(3,obj.obj_S37.group_num1+1);
                    else
                        sub_t2 = tref_f{ind};%因子时间
                        f1 = fetchmysql(sprintf(sql_str2,sub_tn,sub_factor_name,sub_t2),2);
                        %这里需要修正
                        y1 = fetchmysql(sprintf(sql_str3,sub_t),2);                    
                        sub_r = obj.obj_S37.get_sub_group_return(f1,y1);
                        r = [sub_r,(sub_r(:,end)-sub_r(:,1))];%已经调整为正方向  .*obj.factors_S36_dir(i)];
                    end
                    f = num2cell(r(:,[1,1,1,1:end]));
                    f(:,1) = {sub_factor_name};
                    f(:,2) = {sub_t};
                    f(:,3) = obj.obj_S37.symbol_pool_info';
                    chg_re{j} = f';                    
                    sprintf('S46 每日回测结果写入数据库-%s %d-%d %d-%d',sub_t,j,T_tref,i,T_f)
                end
                f = [chg_re{:}]';
                if ~isempty(f)
                    datainsert_adair(sprintf('S37.%s',obj.group_return_tn{1}),obj.obj_S37.group_return_var{1},f)
                end
            end
        end
        %%%%%%%%%%%
        function get_report(obj)           
            
            key_str = 'S46-part1-';
            factor_name = obj.factors_full;
            f_factor_info = obj.tns_info;           
            
            sql_str1 = 'select * from S37.%s where factor_name=''%s'' order by tradingdate'; 
            
            file_name = sprintf('%s因子表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            T_factor = length(factor_name);
            
            sta_re = cell(T_factor,1);
            for i = 1:T_factor
                sub_factor_name = factor_name{i};
                x = fetchmysql(sprintf(sql_str1,obj.group_return_tn{1},sub_factor_name),2);
                sub_re = cell(1,3);
                for j = 1:3
                    sub_x = x(strcmp(x(:,3),obj.obj_S37.symbol_pool_info(j)),:);
                    tref = sub_x(:,2);
                    r_day = cell2mat(sub_x(:,4:end));
                    %需要添加手续费判断
                    r_day = month_fee_update(tref,r_day);
                    title_str = sprintf('%s-%s',f_factor_info{i},obj.obj_S37.symbol_pool_info{j});
                    [h1,h2] = obj.obj_S37.draw_figure(tref,r_day,title_str);
                    obj_wd.pasteFigure(h1,' ');
                    obj_wd.pasteFigure(h2,' ');
                    [v0,v_str0] = curve_static(cumprod(1+r_day(:,end)));
                    [v,v_str] = obj.obj_S37.ad_trans_sta_info(v0,v_str0); 
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
       
        %市值和行业中性化
        function x1 =nero_test(x1,t_str,sub_zn_sel)
            if nargin < 3
                sub_zn_sel = true;
            end
            window1 = 180;%33原本是60天，为了和S36统一，使用了180
            %上市时间
            sql_str4 = ['select ticker,listDate from yuqerdata.equget where listStatusCd !=''UN''',...
                            'and listDate is not null'];
            %sql_str6 = ['select symbol,log(f_mv),f_reverse,f_std,f_change from S33.factor_zxh ',...
            %    'where tradingdate = ''%s'''];
            sql_str6 = ['select symbol,log(negMarketValue) from yuqerdata.yq_dayprice ',...
                'where tradeDate = ''%s'''];
            symbol_info = fetchmysql(sql_str4,2);
            symbol_listdate = datenum(symbol_info(:,2));
            sql_str3 = 'select ticker from   yuqerdata.st_info where tradedate =''%s''';
            %st
            st = fetchmysql(sprintf(sql_str3,t_str),2);
            st = cellfun(@str2double,st,'UniformOutput',false);
            st = cellfun(@(x) sprintf('%0.6d',x),st,'UniformOutput',false);
            [~,ia] = intersect(x1(:,1),st);
            x1(ia,:) = [];
            %新股
            ind = datenum(t_str)-symbol_listdate>window1;
            [~,ia] = intersect(x1(:,1),symbol_info(ind,1));
            x1 = x1(ia,:);

            %中性化
            %sub_f_ner = get_ner_dataS36(t_str);
            sub_f_ner = fetchmysql(sprintf(sql_str6,t_str),2);
            sub_f_ner = sub_f_ner(:,1:2);
            %industry code
            x_indus = yq_methods.get_industry_class_2(t_str);
            inds = suscc_intersect({x1(:,1),sub_f_ner(:,1),x_indus(:,1)});
            x1 = x1(inds(:,1),:);
            sub_f_ner=sub_f_ner(inds(:,2),:);
            x_indus = x_indus(inds(:,3),:);

            x1_v = cell2mat(x1(:,2));
            sub_f_ner_v = cell2mat(sub_f_ner(:,2:end));
            x_indus_v = cell2mat(x_indus(:,2));        
            dummy_f = yq_methods.trans_dummy(x_indus_v(:,end));        
            %regress
            %[~,~,x1_v] = regress(x1_v,[ones(size(x1_v)),sub_f_ner_v,dummy_f]);
            if sub_zn_sel
                warning off            
                [~,~,x1_v] = regress(x1_v,[ones(size(x1_v)),sub_f_ner_v,dummy_f]);             
                warning on
                x1 = [x1(:,1),num2cell(x1_v)];
            end
        end

        function create_table1()
            var_info = {'ticker','tradeDate','com2','degrev'};
            var_type = {'varchar(8)','date','float','float'};
            [OK1,OK2,OK3] = create_table_adair('S45','S45factor_py2',var_info,var_type,'ticker,tradeDate');
            sprintf('%d-%d-%d',OK1,OK2,OK3)      
            var_info = {'ticker','tradeDate','com2'};
            var_type = {'varchar(8)','date','float'};
            [OK1,OK2,OK3] = create_table_adair('S45','S45factor_py3',var_info,var_type,'ticker,tradeDate');
            sprintf('%d-%d-%d',OK1,OK2,OK3)   
        end
        function h = plot_curve(t_str,r_c,title_str)
            h=figure;
            bpcure_plot_updateV2(t_str,r_c(:,end))
            setpixelposition(gcf,[223,365,1345,420]);
            title(sprintf('%s 多空组合与回撤',title_str));
        end
    end    
end