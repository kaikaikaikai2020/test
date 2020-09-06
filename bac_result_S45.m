%有两个因子基于python合成的因子
classdef bac_result_S45<handle
    properties
        obj_S37 = bac_tool_S37();
        symbol_pool = 'symbol_pool_S45';
        factors = {'deg','ave','deg_x','ave_x','com2','degrev'};
        factors_full = cellfun(@(x) ['S45f_',x],{'deg','ave','deg_x','ave_x','com2','degrev'},'UniformOutput',false)
        tns = {'S45.S45factor_py','S45.S45factor_py','S45.S45factor_py','S45.S45factor_py',...
            'S45.S45factor_py3','S45.S45factor_py2'};
        tns_info = {'度因子','溢出因子','修正度因子','修正溢出因子','组合因子1','修正反转因子'};
        zn_sel = [ones(1,4),0,0];
        f_dir = {' ','-',' ','-',' ',' '};
        group_return_tn = {'factor_group5_return_S45'};
    end
    methods
        function get_all_results(obj)
            %part1
            obj.get_part1_result();            
            %part2
            %升级基础因子数据
            dos('python S45_bac_tool_part2.py')
            %合成组合因子
            obj.com_factor()
            %生成表格 股票池 收益 
            obj.create_table()
            %选股和写入收益
            obj.select_symbols_S45()
            obj.get_group_return()
            %生成报告
            obj.get_report()
            %obj.
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
        %按照池子选择
        function select_symbols_S45(obj)            
            T_f = length(obj.tns);
            tref_month = yq_methods.get_month_end();
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
                tref = intersect(tref_month,tref);
                
                tref_complete = fetchmysql(sprintf(sql_str_t0,obj.symbol_pool,sub_key),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    
                    %get symbol
                    sub_t = tref_do{j};
                    sub_f = fetchmysql(sprintf(sql_str_f,sub_fdir,sub_fname,tN,sub_t),2);
                    f = obj.get_symbol(sub_key,sub_t,sub_f,sub_zn_sel);
                    datainsert_adair(sprintf('S37.%s',obj.symbol_pool),obj.obj_S37.var_info_symbol,f)
                    sprintf('S45因子%0.2d-%s选股结果写入数据库',i,sub_t)                    
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
                    sprintf('S37每日回测结果写入数据库-%s %d-%d %d-%d',sub_t,j,T_tref,i,T_f)
                end
                f = [chg_re{:}]';
                if ~isempty(f)
                    datainsert_adair(sprintf('S37.%s',obj.group_return_tn{1}),obj.obj_S37.group_return_var{1},f)
                end
            end
        end
        %%%%%%%%%%%
        function get_report(obj)           
            
            key_str = 'S45-part2-';
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
        %
        function get_part1_result()
            key_str = 'S45-part1-';
            file_name = sprintf('%s因子表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pnw = fullfile(pwd,'计算结果');
            if ~exist(pnw,'dir')
                mkdir(pnw);
            end
            obj_wd = wordcom(fullfile(pnw,sprintf('%s.doc',file_name)));

            pn0 = pwd;
            index_pool ={'000001','000300','000905','399006'};
            %index_pool ={'399006'};
            N_pool = 10:5:65;
            ids = get_com_id(index_pool,N_pool);
            T_ids = size(ids,1);
            %%{
            %更新指标 交给python
            parfor i = 1:T_ids
                sub_id = ids(i,:);
                index_code = index_pool{sub_id(1)};
                window_num = N_pool(sub_id(2));
                dos(sprintf('python S45_bac_tool.py %s %d a-index',index_code,window_num))
            end
            %}

            %读取指标，回测
            xls_re_all = cell(size(index_pool));
            for index_sel = 1:length(index_pool)
                index_code = index_pool{index_sel};
                t_inmodel1_str = '2010-01-01';
                t_inmodel1 = datenum(t_inmodel1_str);
                t_inmodel2_str = '2014-01-01';
                t_inmodel2 = datenum(t_inmodel2_str);
                state_window = 10;
                state_cut = 0.05;
                para_pool = 0.2:0.1:0.8;
                %window_num = 40;
                [ids2,T_a,T_b]= get_com_id(N_pool,para_pool);
                T_ids2 = size(ids2,1);
                para_fn = fullfile(pn0,sprintf('S45-part1-para1-%s-%s-%s.mat',index_code,t_inmodel1_str,t_inmodel2_str));
                if ~exist(para_fn,'file')
                    sta_re_cv_temp = cell(T_ids2,1);
                    parfor i = 1:T_ids2
                        sub_id = ids2(i,:);
                        window_num = N_pool(sub_id(1));
                        para = para_pool(sub_id(2));

                        sql_str = ['select tradeDate,closeIndex,rank_factor from S45.S45_f_vol ',...
                            'where symbol = "%s" and window_num = %d order by tradeDate'];
                        x = fetchmysql(sprintf(sql_str,index_code,window_num),2);
                        tref1 = x(:,1);
                        tref_num1 = datenum(tref1);
                        close_price1 = cell2mat(x(:,2));
                        f1 = cell2mat(x(:,3));

                        chg = zeros(size(close_price1));
                        chg(2:end) = close_price1(2:end)./close_price1(1:end-1)-1;
                        state_v = zeros(size(close_price1));
                        state_v(state_window+1:end) = close_price1(state_window+1:end)./close_price1(1:end-state_window)-1;
                        state_f = zeros(size(state_v));
                        state_f(state_v>state_cut) = 1;
                        state_f(state_v<-state_cut) = -1;

                        ind_inmodel = tref_num1>=t_inmodel1 & tref_num1<=t_inmodel2;
                        %signal-
                        ind = f1>para;
                        ind = circshift(ind,1);
                        ind(1) = 0;
                        %result
                        state_f_inmodel = state_f(ind_inmodel);    
                        r0 = ind(ind_inmodel).*chg(ind_inmodel);

                        temp1 = zeros(3,4);
                        j_ids = -1:1:2;
                        for j = 1:4
                            if j < 4
                                sub_ind = eq(state_f_inmodel,j_ids(j));
                            else
                                sub_ind = 1:length(state_f_inmodel);
                            end
                            y = cumprod(1+r0(sub_ind));
                            %parameter
                            [~,~,sta_val] = curve_static(y,[],false);
                            %sta_re_cv_temp{i} = [sta_val.nh,sta_val.drawdown,sta_val.sharp]';
                            temp1(:,j) = [sta_val.nh,sta_val.drawdown,sta_val.sharp]';
                        end
                        sta_re_cv_temp{i} = temp1;
                        sprintf('S45-part1-参数寻优 %d-%d',i,T_ids2)
                    end
                    sta_re_cv_temp = [sta_re_cv_temp{:}]';
                    save(para_fn,'sta_re_cv_temp')
                else
                    temp = load(para_fn);
                    sta_re_cv_temp = temp.sta_re_cv_temp;
                end
                %
                sta_re_cv = zeros(T_a,T_b,3,4);
                for i_method = 1:4
                    sub_sta_re_cv_temp = sta_re_cv_temp(i_method:4:end,:);
                    for i = 1:T_ids2
                        sub_id = ids2(i,:);
                        for j = 1:3
                            sta_re_cv(sub_id(1),sub_id(2),j,i_method) = sub_sta_re_cv_temp(i,j);
                        end    
                    end
                end
                window_num = zeros(4,1);
                para = zeros(4,1);
                for i = 1:4
                    re_sharp = sta_re_cv(:,:,1,i);
                    [m, n] = find(ismember(re_sharp, max(re_sharp(:))));
                    window_num(i) = N_pool(m(end));
                    para(i) =para_pool(n(end));
                end
                %validation

                for i = 1:4
                    sql_str = ['select tradeDate,closeIndex,rank_factor from S45.S45_f_vol ',...
                            'where symbol = "%s" and window_num = %d and tradeDate>="%s" order by tradeDate'];
                    x = fetchmysql(sprintf(sql_str,index_code,window_num(i),t_inmodel1_str),2);
                    if eq(i,1)
                        tref = x(:,1);
                        tref_num = datenum(tref);
                        close_price = cell2mat(x(:,2));
                        temp = cell2mat(x(:,3));
                        f = zeros(length(temp),4);
                    end
                    f(:,i) = temp;
                end

                %数据对齐
                %rsrs_f = load(sprintf('RSRS_%s.mat',index_code),'result');
                %rsrs_f = rsrs_f.result;
                sql_rsrs = 'select tradingdate,f_val from %s where symbol = "%s" order by tradingdate';
                tn_rsrs = 'S45.signal_rsrs';
                rsrs_f = fetchmysql(sprintf(sql_rsrs,tn_rsrs,index_code),2);

                [tref,ia,ib] = intersect(tref,rsrs_f(:,1));
                tref_num = tref_num(ia);
                f = f(ia,:);
                close_price = close_price(ia,:);

                rsrs_f = cell2mat(rsrs_f(:,2));

                chg = zeros(size(close_price));
                chg(2:end) = close_price(2:end)./close_price(1:end-1)-1;

                ind_inmodel = find(tref_num<=t_inmodel2);
                ind_val = find(tref_num>t_inmodel2);

                state_v = zeros(size(close_price));
                state_v(state_window+1:end) = close_price(state_window+1:end)./close_price(1:end-state_window)-1;
                state_f = zeros(size(state_v));
                state_f(state_v>state_cut) = 1;
                state_f(state_v<-state_cut) = -1;

                %原始signal
                ind1 = f(:,end)>para(end);
                ind1 = circshift(ind1,1);
                ind1(1) = 0;
                %升级后
                ind2 = zeros(size(ind1));
                ind2(eq(state_f,-1)) = f(eq(state_f,-1),1)>para(1);
                ind2(eq(state_f,0)) = f(eq(state_f,0),2)>para(2);
                ind2(eq(state_f,1)) = f(eq(state_f,1),3)>para(3);
                ind2 = circshift(ind2,1);
                ind2(1) = 0;

                %RSRS升级
                ind3 = zeros(size(ind1));
                %牛市
                ind3(eq(state_f,1)) = rsrs_f(eq(state_f,1));
                %熊市
                temp_id0 = eq(state_f,-1);
                ind3(temp_id0) = ind1(temp_id0)>0 & ind2(temp_id0)>0;
                %震荡市
                temp_id1 = eq(state_f,0);
                ind3(temp_id1) = ind1(temp_id1)>0 | ind2(temp_id1)>0;

                ind = [ind1,ind2,ind3];
                %result
                y = bsxfun(@times,ind,chg);
                %手续费
                fee = 0.5/10000;
                fee_ind1 = find(~eq(diff(ind1),0))+2;
                fee_ind1(fee_ind1>size(y,1))=[];

                fee_ind2 = find(~eq(diff(ind2),0))+2;
                fee_ind2(fee_ind2>size(y,1))=[];

                fee_ind3 = find(~eq(diff(ind3),0))+2;
                fee_ind3(fee_ind3>size(y,1))=[];

                y(fee_ind1,1) = y(fee_ind1,1)-fee;
                y(fee_ind2,1) = y(fee_ind2,1)-fee;
                y(fee_ind3,1) = y(fee_ind3,1)-fee;
                y = cumprod(1+y);
                %figure

                h=figure;
                yc = y(ind_val,:);
                yc = bsxfun(@rdivide,yc,yc(1,:));
                plot(yc,'LineWidth',2);
                t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref(ind_val),'UniformOutput',false);
                T_tstr = length(t_str);
                set(gca,'xlim',[0,T_tstr]);
                set(gca,'XTick',floor(linspace(1,T_tstr,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T_tstr,15))));
                set(gca,'XTickLabelRotation',90)    
                setpixelposition(h,[223,365,1345,420]);
                box off
                leg_str = {'成交量择时','牛熊增强','RSRS牛熊增强'};
                legend(leg_str,'NumColumns',3,'Location','best')
                title(index_code)
                obj_wd.pasteFigure(h,index_code);
                %统计参数
                %[v0,v_str0] = curve_static(y(ind_inmodel,1),[],false);
                %[v,v_str] = ad_trans_sta_info(v0,v_str0); 

                [v0,v_str0] = curve_static(y(ind_val,1),[],false);
                [v1,v_str1] = ad_trans_sta_info(v0,v_str0); 

                %[v0,v_str0] = curve_static(y(ind_inmodel,2),[],false);
                %[v3,v_str3] = ad_trans_sta_info(v0,v_str0); 

                [v0,v_str0] = curve_static(y(ind_val,2),[],false);
                [v4,v_str4] = ad_trans_sta_info(v0,v_str0); 

                %[v0,v_str0] = curve_static(y(ind_inmodel,3),[],false);
                %[v5,v_str5] = ad_trans_sta_info(v0,v_str0); 

                [v0,v_str0] = curve_static(y(ind_val,3),[],false);
                [v6,v_str6] = ad_trans_sta_info(v0,v_str0); 

                xls_re = [{sprintf('H%s',index_code),...
                    '成交量择时','牛熊增强','RSRS牛熊增强'};v_str1',v1',v4',v6'];
                xls_re_all{index_sel} = xls_re;

            end
            xls_re_all = [xls_re_all{:}]';
            obj_wd.CloseWord()
            xlstocsv_adair(fullfile(pnw,sprintf('%s.xlsx',file_name)),xls_re_all);            
        end
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
        function com_factor()
            tn2 = 'S45.S45factor_py2';
            tn3 = 'S45.S45factor_py3';
            var_info = {'ticker','tradeDate','com2','degrev'};
            var_info2 = {'ticker','tradeDate','com2'};
            %合成组合因子
            sql_str1 = 'select distinct(tradeDate) from %s';
            tref_all = fetchmysql(sprintf(sql_str1,'S45.S45factor_py'),2);
            tref_complete = fetchmysql(sprintf(sql_str1,'S45.S45factor_py2'),2);
            tref_all = setdiff(tref_all,tref_complete);
            T_tref = length(tref_all);
            sql_str2 = 'select ticker,deg_x,-ave_x from S45.S45factor_py where tradeDate = "%s"';
            sql_str3 = ['select ticker,-REVS20 from yuqerdata.yq_MktStockFactorsOneDayGet ',...
                 'where tradeDate = "%s" and REVS20 is not null'];
            %sql_str3 = ['select symbol,-f_reverse from S33.factor_zxh ',...
            %            'where tradingdate = ''%s'''];
            sql_str_st = 'select ticker from   yuqerdata.st_info where tradedate =''%s''';
            sql_str4 = ['select ticker,listDate from yuqerdata.equget where listStatusCd !=''UN''',...
                'and listDate is not null']; 
            symbol_info = fetchmysql(sql_str4,2);
            symbol_listdate = datenum(symbol_info(:,2));
            window = 120;
            re_db = cell(T_tref,1);
            re_db2 = cell(T_tref,1);
            parfor i = 1:T_tref
                sub_t = tref_all{i};
                x1 = fetchmysql(sprintf(sql_str2,sub_t),2);
                
                %st
                st = fetchmysql(sprintf(sql_str_st,sub_t),2);
                st = cellfun(@str2double,st,'UniformOutput',false);
                st = cellfun(@(x) sprintf('%0.6d',x),st,'UniformOutput',false);
                [~,ia] = intersect(x1(:,1),st);
                x1(ia,:) = [];

                %新股
                ind = datenum(sub_t)-symbol_listdate>window;
                [~,ia] = intersect(x1(:,1),symbol_info(ind,1));
                x1 = x1(ia,:);
                
                %中性化
                sub_x1 =S33_nero_test(x1(:,[1,2]),sub_t);
                sub_x2 = S33_nero_test(x1(:,[1,3]),sub_t);
                [sub_sym,ia,ib] = intersect(sub_x1(:,1),sub_x2(:,1));
                sub_x3 = zscore(cell2mat(sub_x1(ia,2)))+zscore(cell2mat(sub_x2(ib,2)));
                %加权得到合成因子
                x1 = [sub_sym,num2cell(sub_x3/2)];                
                %第二个因子                
                x2 = fetchmysql(sprintf(sql_str3,sub_t),2);
                x2 = nero_test(x2,sub_t);
                %等权合成
                [~,ia,ib] = intersect(x1(:,1),x2(:,1));
                sub_x3 = zscore(cell2mat(x1(ia,2)))+zscore(cell2mat(x2(ib,2)));
                x3 = [x1(ia,:),num2cell(sub_x3/2)];
                x3 = x3(:,[1,1,2:end]);
                x3(:,2) = {sub_t};
                re_db{i} = x3';
                
                x1 = x1(:,[1,1,2]);
                x1(:,2) = {sub_t};
                re_db2{i} = x1';
                sprintf('S45-part2- 合成综合因子1-2 %d-%d',i,T_tref)
            end
            re_db = [re_db{:}]';
            if ~isempty(re_db)
                datainsert_adair(tn2,var_info,re_db);
            end  
            
            re_db2 = [re_db2{:}]';
            if ~isempty(re_db2)
                datainsert_adair(tn3,var_info2,re_db2);
            end  
            
        end
    end    
end