classdef bac_result_S39<handle
    properties        
        index_title = containers.Map({'a','000300','000905','000001'},...
            {'A股市场','沪深300','中证500','上证综指'});    
        method_title =containers.Map([1,2,3],{'弹簧策略','动量上涨加减速','动量下跌加减速'});
    end
    methods
        function update_S39(obj)
            obj.update_signal23()
            obj.update_return_day();
            dos('python S39_ON_spring_method.py')
        end
        function get_all_results(obj)
            obj.update_S39();%升级数据
            key_str = 'S39弹簧、动量加减速策略';
            %选股结果
            file_name = sprintf('%s表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            
            tn = 'S37.S39_result';
            tn_symbol = 'S37.symbol_pool_S39';
            %var_info = {'tradingdate', 'method_ID', 'index_code', 'more_r', 'less_r'};
            sql_str = ['select tradingdate,more_r,less_r from %s where method_ID = %d and ',...
                'index_code = ''%s'' order by tradingdate'];    
            sql_str_symbol = ['select tradingdate,more_r,less_r from %s where method_ID = %d and ',...
                'index_code = ''%s'' order by tradingdate limit 1'];    
            sub_re1 = cell(3,1);
            sub_re1_1 = sub_re1;
            for i = 1:3
                method_id = i;
                sub_re2 = cell(3,1);
                sub_re2_1 = sub_re2;
                for j = 1:4
                    index_id = obj.index_title.keys;
                    index_id = index_id{j};
                    title_str = sprintf('多空-%s-%s',obj.method_title(method_id),obj.index_title(index_id));
                    sub_x = fetchmysql(sprintf(sql_str,tn,method_id,index_id),2);
                    r_day = cell2mat(sub_x(:,2:end));
                    r_day = r_day(:,1)-r_day(:,2);
                    r_c = cumprod(1+r_day);
                    h = obj.draw_figure2(sub_x(:,1),r_c,title_str);%画图并将曲线参数写入word    
                    obj_wd.pasteFigure(h,title_str);
                    [v0,v_str0] = curve_static(r_c(:,1));
                    [v,v_str] = ad_trans_sta_info(v0,v_str0);
                    temp1 = [[{''};v_str'],[title_str;v']];
                    sub_re2{j} = temp1;
                    
                    sub_x_symbol = fetchmysql(sprintf(sql_str_symbol,tn_symbol,method_id,index_id),2);
                    sub_re2_1{j} = [{title_str},sub_x_symbol]';
                end
                sub_re1{i} = [sub_re2{:}];
                sub_re1_1{i} = [sub_re2_1{:}];
            end
            sub_re1 = [sub_re1{:}]';
            obj_wd.CloseWord()
            sta_re = sub_re1([1,2:2:end],:);
            sta_re = cell2table(sta_re);
            writetable(sta_re,sprintf('%s.csv',file_name)) 
            
            sta_re_1 =[{'方法名称','时间','做多仓位','做空仓位'};[sub_re1_1{:}]'];
            sta_re_1 = cell2table(sta_re_1);
            writetable(sta_re_1,fullfile(pn0,sprintf('%s仓位.csv',file_name)));
        end
        %update signal 2 and 3
        function update_signal23(obj)
            %新的选股结果写入数据库
            %更新一周数据需要19s
            key_str = '动量加速周框架数据更新';
            %参数设置
            p_window = 18*4;
            tn = 'S37.symbol_pool_S39';
            var_info = {'tradingdate', 'method_ID', 'index_code', 'more_r', 'less_r'};

            %t0_t0 = yq_methods.get_table_end_date(tn,'tradingdate');
            sql_str = 'select tradingdate from %s where method_ID=2 order by tradingdate desc limit 1';
            t0_t0 = fetchmysql(sprintf(sql_str,tn),2);
            t0_t0 = t0_t0{1};
            tref = yq_methods.get_week_end();
            if strcmp(tref(end),t0_t0)
                sprintf(sprintf('已经是最新数据，无需 %s',key_str))
                return
            end
            id = find(strcmp(tref,t0_t0));
            % 选股起始时间
            back_date = t0_t0;
            begin_t = tref{id-p_window*2+1};
            % 股票池的信息日期
            info_date = t0_t0;
            info_date_1year_before = datestr(datenum(info_date)-365,'yyyy-mm-dd');
            index_pool = {'a','000300','000905','000001'};
            index_info = {'A股市场','沪深300','中证500','上证综指'};
            symbol_select = cell(size(index_info));
            for index_sel = 1:length(index_info)
                index_code = index_pool{index_sel};
                %index_name = index_info{index_sel};
                %指数结果
                sql_str_index = ['select endDate,closePrice from yuqerdata.yq_MktIdxwGet ',...
                    'where ticker = ''%s'' and endDate>=''%s'' order by endDate'];
                %x_index = fetchmysql(sprintf(sql_str_index,index_code,back_date),2);
                % 月度收益
                sql_str_month_return = ['select endDate,closeprice/precloseprice-1 from yuqerdata.yq_MktEquwAdjAfGet ',...
                    'where ticker = "%s" and endDate>="%s" and tradeDays>0 order by endDate '];

                hs_300 = yq_methods.get_index_pool(index_code,info_date);

                if strcmp(index_code,'000001')
                    %ST
                    st = yq_methods.get_stpt_symbol(info_date);
                    hs_300 = setdiff(hs_300,st);
                    %B股及次新股
                    sql_str =   ['select distinct(ticker)  from yuqerdata.equget  where equTypeCD = "A" ',...
                        'and ListSectorCD<=3 and  listDate <="%s" order by ticker'];
                    symbol_a = fetchmysql(sprintf(sql_str,info_date_1year_before),2);
                    %symbol_a = yq_methods.get_symbol_A();
                    hs_300 = intersect(hs_300,symbol_a);
                end
                %月度日期
                tref = yq_methods.get_week_end();
                tref_num = datenum(tref);
                tref_sel = tref_num >= datenum(begin_t);
                tref = tref(tref_sel);
                tref_num = tref_num(tref_sel);
                T_tref = length(tref);

                T_symbols = length(hs_300);
                F = cell(T_symbols,1);
                parfor i = 1:T_symbols
                    %读取股票数据
                    x = fetchmysql(sprintf(sql_str_month_return,hs_300{i},begin_t),2);
                    if size(x,1)<p_window
                        F{i} = nan(T_tref,3);
                        continue
                    end
                    sub_tref = x(:,1);
                    x = cell2mat(x(:,2));
                    x(isnan(x)) = 0;
                    %动量上涨、下跌指标    
                    f1 = obj.get_moment_speed(x,p_window);
                    %加速、减速指标
                    f2 = obj.get_curve_fit(x,p_window);
                    [~,ia,ib] = intersect(tref,sub_tref);
                    sub_re = nan(T_tref,3);
                    sub_re(:,1) = 0;
                    sub_re(ia,:) = [x(ib),f1(ib),f2(ib)];
                    %sub_re = [x,f1,f2];
                    F{i} = sub_re;
                    sprintf('%s %d-%d',key_str,i,T_symbols)
                end
                F = [F{:}];
                %限制回测区间
                tref_sel = tref_num > datenum(back_date);
                tref = tref(tref_sel);
                %tref_num = tref_num(tref_sel);
                T_tref = length(tref);
                F = F(tref_sel,:);
                if isempty(F)
                    continue
                end
                %月度收益及两个指标
                %return_df = F(:,1:3:end);
                speed_df = F(:,2:3:end);
                curve_df = F(:,3:3:end);    
                %动量上涨、下跌分组
                ind_b_t = obj.get_top_bottom(speed_df,30);
                %r = zeros(T_tref,4);
                symbol_pool = cell(T_tref,6);
                for i = 1:T_tref
                    %加速上涨
                    ind1 = ind_b_t{i}{1};
                    sub_x = curve_df(i,ind1);
                    symbol_pool(i,1) = {hs_300(ind1(sub_x<0))};
                    symbol_pool(i,2) = {hs_300(ind1(sub_x>0))};    
                    %加速下跌
                    ind2 = ind_b_t{i}{2};
                    sub_x2 = curve_df(i,ind2);
                    symbol_pool(i,3) = {hs_300(ind2(sub_x2<0))};
                    symbol_pool(i,4) = {hs_300(ind2(sub_x2>0))};  
                    symbol_pool(i,5) = {index_code};
                    symbol_pool(i,6) = tref(i);
                end
                symbol_select{index_sel} = symbol_pool';
            end
            symbol_select = [symbol_select{:}]';
            if ~isempty(symbol_select)
                %结果写入数据库,须保留
                %var_info = {'tradingdate', 'method_ID', 'index_code', 'more_r', 'less_r'};
                T_undo = size(symbol_select,1);
                sub_f1 = cell(T_undo,1);
                sub_f2 = sub_f1;
                for i = 1:T_undo
                    sub_code_pool = symbol_select(i,:);
                    %more-less more-less
                    sub_more1 = strjoin(sub_code_pool{1},',');
                    sub_less1 = strjoin(sub_code_pool{2},',');
                    sub_more2 = strjoin(sub_code_pool{3},',');
                    sub_less2 = strjoin(sub_code_pool{4},',');
                    sub_index = sub_code_pool{5};
                    sub_t = sub_code_pool{6};
                    sub_f1{i} = {sub_t,2,sub_index,sub_more1,sub_less1}';
                    sub_f2{i} = {sub_t,3,sub_index,sub_more2,sub_less2}';
                end
                sub_f1 = [sub_f1{:}]';
                sub_f2 = [sub_f2{:}]';

                if ~isempty(sub_f1)
                    datainsert_adair(tn,var_info,sub_f1);
                end
                if ~isempty(sub_f2)
                    datainsert_adair(tn,var_info,sub_f2);
                end
            end            
        end
    end
    methods(Static)
        function re = get_top_bottom(x,p)
            if nargin<2
                p = 30;
            end
            T = size(x,1);
            re = cell(T,1);
            for i = 1:T
                sub_x = x(i,:);
                ind1 = find(~isnan(sub_x));
                sub_x1 = sub_x(ind1);
                p1 = prctile(sub_x1,p);
                p2 = prctile(sub_x1,100-p);
                ind_t=ind1(sub_x1>=p2);
                ind_b =ind1(sub_x1<=p1);
                %[~,ia] = sort(sub_x1);
                %num_remain = round(length(ind1)*0.3);
                %ind_b = ind1(ia(1:num_remain));
                %ind_t = ind1(ia(end-num_remain+1:end));                
                re{i} = {ind_t,ind_b};
            end
        end
        function f = get_moment_speed(x,p_window)
            T = size(x,1);
            f =  nan(T,1);
            for i = p_window:T
                sub_x = x(i-p_window+1:i,:);
                temp = cumprod((1+sub_x).^(1/p_window))-1;
                f(i) = temp(end);
            end
        end
        function f =get_curve_fit(x,p_window)
            T = length(x);
            f = nan(T,1);
            for i = p_window:T
                sub_x = x(i-p_window+1:i,:);
                temp = polyfit((1:p_window)',sub_x,2);
                f(i) = temp(1);
            end
        end
        function draw_figure(tref,r_day,title_str,legend_str)
            r_c = cumprod(1+r_day);
            t_str = cellstr(datestr(datenum(tref),'yyyymmdd'));

            T = length(t_str);
            h1=figure;

            plot(r_c(:,1:end),'-','LineWidth',2);
            set(gca,'xlim',[0,T]);
            set(gca,'XTick',floor(linspace(1,T,15)));
            set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(h1,[223,365,1345,420]);
            box off
            legend(legend_str,'NumColumns',length(legend_str),'Location','best');
            if ~isempty(title_str)
                title(sprintf('%s',title_str));
            end
        end
        %
        function h1 = draw_figure2(tref,r_c,title_str,legend_str)
            if nargin < 3
                title_str = [];
            end
            if nargin < 4
                legend_str = [];
            end
            t_str = cellstr(datestr(datenum(tref),'yyyymmdd'));

            T = length(t_str);
            h1=figure;

            plot(r_c(:,1:end),'-','LineWidth',2);
            set(gca,'xlim',[0,T]);
            set(gca,'XTick',floor(linspace(1,T,15)));
            set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(h1,[223,365,1345,420]);
            box off
            if ~isempty(legend_str)
                legend(legend_str,'NumColumns',length(legend_str),'Location','best');
            end
            if ~isempty(title_str)
                title(sprintf('%s',title_str));
            end
        end
        
        %
        function update_return_day()
            key_str = '写入历史收益数据';
            tn = 'S37.S39_result';
            var_info = {'tradingdate', 'method_ID', 'index_code', 'more_r', 'less_r'};
            tn_symbol = 'S37.symbol_pool_S39';

            index_pool = {'a','000300','000905','000001'};
            %index_info = {'沪深300','中证500','上证综指'};
            t0 = yq_methods.get_table_end_date(tn);
            if isempty(t0)
                t0 = '2008-06-06';
            end
            %t0 = '2008-06-06';%must be delete
            tref = yq_methods.get_tradingdate(t0);
            tref = tref(2:end);
            if isempty(tref)
                sprintf('无需更新，已经是最新 %s',key_str)
                return
            end
            T = length(tref);

            sql_str_r = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate = ''%s''';
            sql_str_t = ['select tradingdate from %s where method_ID = %d and index_code=''%s'' ',...
                'and tradingdate<''%s'' order by tradingdate desc limit 1'];
            sql_str_symbol = ['select more_r,less_r from %s where method_ID = %d and index_code=''%s'' ',...
                'and tradingdate=''%s'''];
            r_re1 = cell(T,1);
            parfor i = 1:T
                sub_r = fetchmysql(sprintf(sql_str_r,tref{i}),2);
                sub_re1 = cell(3,1);
                for j = 1:3%3个方法
                    sub_re2 = cell(size(index_pool));
                    for k = 1:length(index_pool)%4个股票池
                        t = fetchmysql(sprintf(sql_str_t,tn_symbol,j,index_pool{k},tref{i}),2);
                        if isempty(t)
                            continue
                        else
                            t = t{1};
                        end
                        sub_symbol = fetchmysql(sprintf(sql_str_symbol,tn_symbol,j,index_pool{k},t),2);
                        sub_symbol_m = strsplit(sub_symbol{1},',');
                        sub_symbol_l = strsplit(sub_symbol{2},',');
                        [~,ia,ib] = intersect(sub_r(:,1),sub_symbol_m);
                        sub_r_m = zeros(size(sub_symbol_m(:,1)));
                        sub_r_m(ib) = cell2mat(sub_r(ia,2));
                        [~,ia,ib] = intersect(sub_r(:,1),sub_symbol_l);
                        sub_r_l = zeros(size(sub_symbol_l(:,1)));
                        sub_r_l(ib) = cell2mat(sub_r(ia,2));

                        sub_re2{k} = {tref{i},j,index_pool{k},mean(sub_r_m),mean(sub_r_l)}';
                    end
                    sub_re1{j} = [sub_re2{:}];
                end
                r_re1{i} = [sub_re1{:}];
                sprintf('%s %d-%d',key_str,i,T)
            end
            r_re1 = [r_re1{:}]';
            if ~isempty(r_re1)
                datainsert_adair(tn,var_info,r_re1);
            end            
        end        
    end
end