classdef bac_result_S38<handle
    properties
        tN_future = 'yuqerdata.yq_MktMFutdGet';
        future_pool_all
        future_pool_info        
        symbol_pool_all
        symbol_pool_info
        tref_com
        y0_com
        yf_com
    end
    methods
        function obj = bac_result_S38()
            sql_str_t = 'select tradeDate from %s order by tradeDate desc limit 1';
            tt = fetchmysql(sprintf(sql_str_t,obj.tN_future),2);
            %获取品种
            sql_str_type = ['select secShortName,contractObject from %s where ',...
                'tradeDate = ''%s'' and mainCon=1'];
            future_type = fetchmysql(sprintf(sql_str_type,obj.tN_future,tt{1}),2);
            [~,ia] = unique(future_type(:,2));
            future_type = future_type(ia,:);
            obj.future_pool_all = future_type(:,2);
            obj.future_pool_info = future_type(:,1);
            
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
            obj.symbol_pool_all = cellfun(@(x) x{1},index_info,'UniformOutput',false);
            obj.symbol_pool_info = cellfun(@(x) x{2},index_info,'UniformOutput',false);            
        end
        function get_single_results(obj)
            
            obj.tref_com = cell(6,1);
            obj.y0_com = obj.tref_com;
            obj.yf_com=obj.tref_com;
            
            i = 1;
            [obj.tref_com{i},obj.y0_com{i},obj.yf_com{i}] = get_high_order_result_index(obj);
            i = i+1;
            [obj.tref_com{i},obj.y0_com{i},obj.yf_com{i}] = get_LLT_results_index(obj);
            i = i + 1;
            [obj.tref_com{i},obj.y0_com{i},obj.yf_com{i}] = get_interval_breakthrough_index(obj);
            i = i+1;            
            [obj.tref_com{i},obj.y0_com{i},obj.yf_com{i}] = get_high_order_result_future(obj);
            i = i + 1;
            [obj.tref_com{i},obj.y0_com{i},obj.yf_com{i}] = get_LLT_results_future(obj);
            i = i + 1;
            [obj.tref_com{i},obj.y0_com{i},obj.yf_com{i}] = get_interval_breakthrough_future(obj);     
            
            
        end
        function get_all_results(obj)
            obj.get_single_results();
            obj.get_com_future();
            obj.get_com_index();
        end
        function get_com_index(obj)
            key_str = 'S38 三择时平均';      
            T_symbol_pool_all = length(obj.symbol_pool_all);
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s-指数%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            
            for index_sel =1:T_symbol_pool_all
                sub_index_info = obj.symbol_pool_info{index_sel};
                y = [obj.yf_com{1}{index_sel},obj.yf_com{2}{index_sel},obj.yf_com{3}{index_sel}];
%                y=[sub_f{:}];
                if size(y,2)<3
                    continue
                end
                y_bac_f = mean(y,2);
                y_bac_0 = obj.y0_com{1}{index_sel};
                tref = obj.tref_com{1}{index_sel};
                [v0,v_str0] = curve_static(y_bac_0);
                [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

                [v1,v_str1] = curve_static(y_bac_f);
                [v1,~] = ad_trans_sta_info(v1,v_str1);
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                end
                sta_re{index_sel} = sub_sta;
                %figure
                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'指数','综合择时'},'NumColumns',2,'location','best');
                title(sub_index_info)
                obj_wd.pasteFigure(h,sub_index_info);
                sprintf('%s %d-%d',key_str,index_sel,T_symbol_pool_all)
                
            end
            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))
        end
        function get_com_future(obj)
            key_str = 'S38 三择时平均';
            T_symbol_pool_all = length(obj.future_pool_all);
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s-期货%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            
            for index_sel =1:T_symbol_pool_all
                sub_index_info = obj.future_pool_info{index_sel};
                try
                y = [obj.yf_com{4}{index_sel},obj.yf_com{5}{index_sel},obj.yf_com{6}{index_sel}];
                catch
                    keyboard
                end
%                y=[sub_f{:}];
                if size(y,2)<3
                    continue
                end
                y_bac_f = mean(y,2);
                y_bac_0 = obj.y0_com{4}{index_sel};
                tref = obj.tref_com{4}{index_sel};
                [v0,v_str0] = curve_static(y_bac_0);
                [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

                [v1,v_str1] = curve_static(y_bac_f);
                [v1,~] = ad_trans_sta_info(v1,v_str1);
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                end
                sta_re{index_sel} = sub_sta;
                %figure
                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'指数','综合择时'},'NumColumns',2,'location','best');
                title(sub_index_info)
                obj_wd.pasteFigure(h,sub_index_info);
                sprintf('%s %d-%d',key_str,index_sel,T_symbol_pool_all)
                
            end
            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))
        end
        
    end
    
    methods 
        function [tref_all,Y_bac_0,Y_bac_f] = get_interval_breakthrough_index(obj)
            key_str = 'S38 区间突破择时-指数';
            para_kurt = 4;%厚尾判断阈值，文献推荐4
            T_symbol_pool_all = length(obj.symbol_pool_all);
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_0;
            sql_str_data = 'select tradeDate,openIndex,lowestIndex,highestIndex,closeIndex from yuqerdata.yq_index where symbol = ''%s'' order by tradeDate';  
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));

            for index_sel =1:T_symbol_pool_all
                sub_index_code = obj.symbol_pool_all{index_sel};
                sub_index_info = obj.symbol_pool_info{index_sel};
                x = fetchmysql(sprintf(sql_str_data,sub_index_code),2);
                data=cell2mat(x(:,2:end));
                x = x(:,[1,5]);
                tref = x(:,1);
                closeprice = cell2mat(x(:,2));
                sub_r = zeros(size(closeprice));
                sub_r(2:end) = closeprice(2:end)./closeprice(1:end-1)-1;
                closeprice = cumprod(1+sub_r)*100;

                T_tref = length(data(:,1));  % 行数

                % 定义策略参数
                K1 = 0.9;
                K2 = 0.9;
                N = 30;
                N_range = 2;
                % 计算峰度系数
                % 回测开始
                dataIndex = N + 1;  % 回测起始行数
                indicator1 = zeros(T_tref,1);
                while(dataIndex<=T_tref)
                    % 判断买入还是卖出  
                        % data数据格式：每一行表示一个时间单位（一天、一小时等）内的5个值——open,low,high,close,volume
                    HH = max(data(dataIndex-N_range:dataIndex-1,3));
                    LC = min(data(dataIndex-N_range:dataIndex-1,4));
                    HC = max(data(dataIndex-N_range:dataIndex-1,4));
                    LL = min(data(dataIndex-N_range:dataIndex-1,2));
                    Range = max([HH-LC,HC-LL]);
                    half_Range = Range/2;
                    %BuyLine = data(dataIndex,1) + K1*unifrnd(1,2);  % 买入门限
                    %SellLine = data(dataIndex,1) - K2*unifrnd(1,2); % 卖出门限
                    BuyLine = data(dataIndex,1) + K1*half_Range;
                    SellLine = data(dataIndex,1) - K2*half_Range;
                    price = data(dataIndex-N:dataIndex-1, 4);
                    percentage_change = diff(price)./price(1:end-1);    
                    kurt = kurtosis(percentage_change);

                    if eq(indicator1(dataIndex-1),0)
                        % 没有仓位
                        if( data(dataIndex,3)>BuyLine && kurt>para_kurt)
                            indicator1(dataIndex)=1;  % 开多仓
                        elseif( data(dataIndex,2)<SellLine && kurt>para_kurt)
                            indicator1(dataIndex)=-1;  % 开空仓
                        end
                    else
                        if eq(indicator1(dataIndex-1),1)
                            if data(dataIndex,2)<SellLine
                                indicator1(dataIndex)=-1;
                            end
                        else
                            if( data(dataIndex,3)>BuyLine )
                                indicator1(dataIndex) = 1;
                            end
                        end
                    end
                    dataIndex = dataIndex+1;
                end
                %信号延迟一天执行
                indicator0 = cat(1,0,indicator1);
                indicator1 = indicator0(1:end-1);
                y_bac_f = cumprod(1+sub_r.*indicator1)*100;
                y_bac_0 = closeprice;
                [v0,v_str0] = curve_static(y_bac_0);
                [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

                [v1,v_str1] = curve_static(y_bac_f);
                [v1,~] = ad_trans_sta_info(v1,v_str1);
                tref_next = yq_methods.get_tradingdate_future(tref{end});
                if length(tref_next)>1
                    tref_next = tref_next{2};
                else
                    tref_next = tref_next{1};
                end
                f_str = containers.Map([1,0,-1],{'做多','平仓','做空'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {'择时信号',tref_next,f_str(indicator0(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {tref_next,f_str(indicator0(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'指数','区间突破择时'},'NumColumns',2,'location','best');
                title(sub_index_info)
                obj_wd.pasteFigure(h,sub_index_info);
                sprintf('%s %d-%d',key_str,index_sel,T_symbol_pool_all)    
                Y_bac_0{index_sel} = y_bac_0;
                Y_bac_f{index_sel} = y_bac_f;
                tref_all{index_sel} = tref;
            end
            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))
            
        end
        
        function [tref_all,Y_bac_0,Y_bac_f] = get_LLT_results_index(obj)
            key_str = 'S38 LLT双向择时';            
            T_symbol_pool_all = length(obj.symbol_pool_all);
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_0;
            for index_sel = 1:T_symbol_pool_all    
                sub_index_code = obj.symbol_pool_all{index_sel};
                sub_index_info = obj.symbol_pool_info{index_sel};
                sql_str = 'select tradeDate,closeIndex from yuqerdata.yq_index where symbol = ''%s'' order by tradeDate';
                x = fetchmysql(sprintf(sql_str,sub_index_code),2);
                tref = x(:,1);
                closeprice = cell2mat(x(:,2));
                indicator1 = [0;obj.llt_indicator(closeprice,30,20,1)];
                %信号延迟一天
                %回测框架1
                %[y_bac_0,y_bac_f] = obj.simuTrail2(tref_num,indicator1,tref_num,closeprice,[],[]); 
                % [props,objH,recurve] = obj.efplot(tref_num,indicator1,y1,y2,[]);
                %回测框架2
                sub_r = zeros(size(closeprice));
                sub_r(2:end)  = closeprice(2:end)./closeprice(1:end-1)-1;
                y_dir2 = indicator1;
                y_dir2(indicator1<1) = -1;
                y_dir2(1) = 0;
                y_bac_f = cumprod(1+sub_r.*y_dir2(1:length(sub_r)))*100;
                y_bac_0 = closeprice/closeprice(1)*100;

                [v0,v_str0] = curve_static(y_bac_0);
                [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

                [v1,v_str1] = curve_static(y_bac_f);
                [v1,~] = ad_trans_sta_info(v1,v_str1);
                tref_next = yq_methods.get_tradingdate_future(tref{end});
                if length(tref_next)>1
                    tref_next = tref_next{2};
                else
                    tref_next = tref_next{1};
                end
                f_str = containers.Map([1,0,-1],{'做多','平仓','做空'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {'择时信号',tref_next,f_str(y_dir2(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {tref_next,f_str(y_dir2(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'指数','LLT择时'},'NumColumns',2,'location','best');
                title(sub_index_info)
                obj_wd.pasteFigure(h,sub_index_info);
                sprintf('%s %d-%d',key_str,index_sel,T_symbol_pool_all)
                
                Y_bac_0{index_sel} = y_bac_0;
                Y_bac_f{index_sel} = y_bac_f; 
                tref_all{index_sel} = tref;
            end

            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))            
            
        end
        function [tref_all,Y_bac_0,Y_bac_f] = get_interval_breakthrough_future(obj)
            key_str = 'S38 区间突破择时-期货';
            para_kurt = 4;%厚尾判断阈值，文献推荐4
            T_symbol_pool_all = length(obj.future_pool_all);
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_f;
            sql_str_data = ['select ticker,tradeDate,openPrice,lowestPrice,highestPrice,closePrice from %s ',...
        'where contractObject = ''%s'' and closePrice is not null and mainCon=1 order by tradeDate'];   
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));

            for index_sel =1:T_symbol_pool_all
                sub_index_code = obj.future_pool_all{index_sel};
                sub_index_info = obj.future_pool_info{index_sel};
                x = fetchmysql(sprintf(sql_str_data,obj.tN_future,sub_index_code),2);
                ticker = x(:,1);
                ticker_code = cellfun(@(x) str2double(x(length(sub_index_code)+1:end)),ticker);
                ticker_change = find(diff(ticker_code))+1; %换约日

                data = cell2mat(x(:,3:end));

                x = x(:,[2,6]);
                tref = x(:,1);
                closeprice = cell2mat(x(:,2));
                %换约修正
                sub_r = zeros(size(closeprice));
                sub_r(2:end) = closeprice(2:end)./closeprice(1:end-1)-1;
                sub_r(ticker_change) = 0;
                sub_r(1) = 0;
                closeprice = cumprod(1+sub_r)*100;
                T_tref = length(data(:,1));  % 行数
                % 定义策略参数
                K1 = 0.9;
                K2 = 0.9;
                N = 30;
                N_range = 2;
                % 计算峰度系数
                % 回测开始
                dataIndex = N + 1;  % 回测起始行数
                indicator1 = zeros(T_tref,1);
                while(dataIndex<=T_tref)
                    % 判断买入还是卖出  
                        % data数据格式：每一行表示一个时间单位（一天、一小时等）内的5个值——open,low,high,close,volume
                    HH = max(data(dataIndex-N_range:dataIndex-1,3));
                    LC = min(data(dataIndex-N_range:dataIndex-1,4));
                    HC = max(data(dataIndex-N_range:dataIndex-1,4));
                    LL = min(data(dataIndex-N_range:dataIndex-1,2));
                    Range = max([HH-LC,HC-LL]);
                    half_Range = Range/2;
                    %BuyLine = data(dataIndex,1) + K1*unifrnd(1,2);  % 买入门限
                    %SellLine = data(dataIndex,1) - K2*unifrnd(1,2); % 卖出门限
                    BuyLine = data(dataIndex,1) + K1*half_Range;
                    SellLine = data(dataIndex,1) - K2*half_Range;
                    price = data(dataIndex-N:dataIndex-1, 4);
                    percentage_change = diff(price)./price(1:end-1);    
                    kurt = kurtosis(percentage_change);

                    if eq(indicator1(dataIndex-1),0)
                        % 没有仓位
                        if( data(dataIndex,3)>BuyLine && kurt>para_kurt)
                            indicator1(dataIndex)=1;  % 开多仓
                        elseif( data(dataIndex,2)<SellLine && kurt>para_kurt)
                            indicator1(dataIndex)=-1;  % 开空仓
                        end
                    else
                        if eq(indicator1(dataIndex-1),1)
                            if data(dataIndex,2)<SellLine
                                indicator1(dataIndex)=-1;
                            end
                        else
                            if( data(dataIndex,3)>BuyLine )
                                indicator1(dataIndex) = 1;
                            end
                        end
                    end
                    dataIndex = dataIndex+1;
                end
                %信号延迟一天执行
                indicator0 = cat(1,0,indicator1);
                indicator1 = indicator0(1:end-1);
                y_bac_f = cumprod(1+sub_r.*indicator1)*100;
                y_bac_0 = closeprice;
                [v0,v_str0] = curve_static(y_bac_0);
                [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

                [v1,v_str1] = curve_static(y_bac_f);
                [v1,~] = ad_trans_sta_info(v1,v_str1);
                tref_next = yq_methods.get_tradingdate_future(tref{end});
                if length(tref_next)>1
                    tref_next = tref_next{2};
                else
                    tref_next = tref_next{1};
                end
                f_str = containers.Map([1,0,-1],{'做多','平仓','做空'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {'择时信号',tref_next,f_str(indicator0(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {tref_next,f_str(indicator0(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'指数','区间突破择时'},'NumColumns',2,'location','best');
                title(sub_index_info)
                obj_wd.pasteFigure(h,sub_index_info);
                sprintf('%s %d-%d',key_str,index_sel,T_symbol_pool_all)    
                Y_bac_0{index_sel} = y_bac_0;
                Y_bac_f{index_sel} = y_bac_f;
                tref_all{index_sel} = tref;
            end
            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))
            
        end
        function [tref_all,Y_bac_0,Y_bac_f] = get_LLT_results_future(obj)
            key_str = 'S38 LLT双向择时-期货';   
            T_symbol_pool_all = length(obj.future_pool_all);
            sql_str_future = ['select ticker,tradeDate,closePrice from %s ',...
                    'where contractObject = ''%s'' and closePrice is not null and mainCon=1 order by tradeDate'];

            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_0;
            for index_sel = 1:T_symbol_pool_all    
                sub_index_code = obj.future_pool_all{index_sel};
                sub_index_info = obj.future_pool_info{index_sel};
                x = fetchmysql(sprintf(sql_str_future,obj.tN_future,sub_index_code),2);
                if size(x,1)<244
                    continue
                end
                ticker = x(:,1);
                ticker_code = cellfun(@(x) str2double(x(length(sub_index_code)+1:end)),ticker);
                ticker_change = find(diff(ticker_code))+1; %换约日
                x = x(:,2:end);
                tref = x(:,1);
                y = cell2mat(x(:,2));
                r = zeros(size(y));
                r(2:end) = y(2:end)./y(1:end-1)-1;
                r(ticker_change) = 0; %换约日的第一天无收益
                closeprice =cumprod(1+r);
                indicator1 = [0;obj.llt_indicator(closeprice,30,20,1)];
                %信号延迟一天
                %回测框架1
                %[y_bac_0,y_bac_f] = obj.simuTrail2(tref_num,indicator1,tref_num,closeprice,[],[]); 
                % [props,objH,recurve] = obj.efplot(tref_num,indicator1,y1,y2,[]);
                %回测框架2
                y_dir2 = indicator1;
                y_dir2(indicator1<1) = -1;
                y_dir2(1) = 0;
                y_bac_f = cumprod(1+r.*y_dir2(1:length(r)))*100;
                y_bac_0 = closeprice/closeprice(1)*100;

                [v0,v_str0] = curve_static(y_bac_0);
                [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

                [v1,v_str1] = curve_static(y_bac_f);
                [v1,~] = ad_trans_sta_info(v1,v_str1);
                tref_next = yq_methods.get_tradingdate_future(tref{end});
                if length(tref_next)>1
                    tref_next = tref_next{2};
                else
                    tref_next = tref_next{1};
                end
                f_str = containers.Map([1,0,-1],{'做多','平仓','做空'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {'择时信号',tref_next,f_str(y_dir2(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-择时']};v1']];
                    signal_info = {tref_next,f_str(y_dir2(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'指数','LLT择时'},'NumColumns',2,'location','best');
                title(sub_index_info)
                obj_wd.pasteFigure(h,sub_index_info);
                sprintf('%s %d-%d',key_str,index_sel,T_symbol_pool_all)
                
                Y_bac_0{index_sel} = y_bac_0;
                Y_bac_f{index_sel} = y_bac_f;   
                tref_all{index_sel} = tref;
            end

            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))            
            
        end
        
        function [tref_all,Y_bac_0,Y_bac_f,sub_signal_update] = get_high_order_result_future(obj)
            key_str = 'S38 高阶矩-期货'; 
            T_symbol_pool_all = length(obj.future_pool_all);
            sql_str_future = ['select ticker,tradeDate,closePrice from %s ',...
                    'where contractObject = ''%s'' and closePrice is not null and mainCon=1 order by tradeDate'];

            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_0;
            for index_sel = 1:T_symbol_pool_all
                sub_index_code = obj.future_pool_all{index_sel};
                sub_index_info = obj.future_pool_info{index_sel};
                x = fetchmysql(sprintf(sql_str_future,obj.tN_future,sub_index_code),2);
                if size(x,1)<244
                    continue
                end
                ticker = x(:,1);
                ticker_code = cellfun(@(x) str2double(x(length(sub_index_code)+1:end)),ticker);
                ticker_change = find(diff(ticker_code))+1; %换约日
                x = x(:,2:end);
                tref = x(:,1);
                y = cell2mat(x(:,2));
                r = zeros(size(y));
                r(2:end) = y(2:end)./y(1:end-1)-1;
                r(ticker_change) = 0; %换约日的第一天无收益
                [h,sub_sta_re,y_bac_0,y_bac_f,sub_signal_update] = obj.get_high_order_signal(tref,r,sub_index_info);
                obj_wd.pasteFigure(h,sub_index_info);
                if eq(index_sel,1)
                    sta_re{index_sel} = sub_sta_re;
                else
                    sta_re{index_sel} = sub_sta_re(:,2:end);
                end   
                Y_bac_0{index_sel} = y_bac_0;
                Y_bac_f{index_sel} = y_bac_f;
                tref_all{index_sel} = tref;
            end
            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,sprintf('%s.csv',fullfile(pn0,file_name)))
        end
        %%%%%%%%%%%%%
        function [tref_all,Y_bac_0,Y_bac_f,sub_signal_update] = get_high_order_result_index(obj)
            
            T_symbol_pool_all = length(obj.symbol_pool_all);
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_0;
            sta_re = cell(T_symbol_pool_all);
            file_name = sprintf('S38 高阶矩择时-指数%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));

            for index_sel = 1:T_symbol_pool_all
                sub_index_code = obj.symbol_pool_all{index_sel};
                sub_index_info = obj.symbol_pool_info{index_sel};                
                %data
                sql_str = ['select tradeDate,closeIndex from yuqerdata.yq_index ',...
                    'where symbol = ''%s'' and closeIndex is not null order by tradeDate'];
                x = fetchmysql(sprintf(sql_str,sub_index_code),2);
                tref = x(:,1);
                %tref_num = datenum(tref);
                y = cell2mat(x(:,2));
                r = zeros(size(y));
                r(2:end) = y(2:end)./y(1:end-1)-1;
                [h,sub_sta_re,y_bac_0,y_bac_f,sub_signal_update] = obj.get_high_order_signal(tref,r,sub_index_info);
                obj_wd.pasteFigure(h,sub_index_info);
                if eq(index_sel,1)
                    sta_re{index_sel} = sub_sta_re;
                else
                    sta_re{index_sel} = sub_sta_re(:,2:end);
                end
                Y_bac_0{index_sel} = y_bac_0;
                Y_bac_f{index_sel} = y_bac_f;
                tref_all{index_sel} = tref;
            end
            obj_wd.CloseWord()
            sta_re = [sta_re{:}]';
            sta_re = cell2table(sta_re);
            writetable(sta_re,fullfile(pn0,sprintf('%s.csv',file_name)))
        end        
        %%%%%%
        %mod1
        %{
        indicator = slope of llt_values
        %}
        %mod2
        %{
            (1) if T day llt_value slope > 0 and 90% of 21 day before 's slope > 0,
        indicator > 0 
            (2) if T day llt_value slope < 0 and max(10%) of 21 day before 's llt_value
        slope >0, indicator <0
            else
            (3) T day llt_value = T-1 day llt_value
            (4) default llt_value(1) = 0
        %}
        function [indicator,llt_value] = llt_indicator(obj,curve_value,llt_window,ma_window,mod)
            if nargin < 5
                mod = 1;
            end
            if nargin < 4
                ma_window = 20;
            end
            if nargin < 3
                llt_window = 30;
            end
            llt_value = obj.get_llt_value(curve_value,llt_window);
            slope_value = zeros(size(curve_value));
            slope_value(2:end) = llt_value(2:end)>llt_value(1:end-1);
            if eq(mod,1)
                indicator = slope_value;
            elseif eq(mod,2)
                indicator = zeros(size(curve_value));
                T = length(indicator);
                for i = ma_window+2:T
                    subwindow = i-ma_window:i;
                    judgeValue = sum(slope_value(subwindow));
                    if slope_value(i)>0 && judgeValue>=fix((ma_window+1)*0.9)
                        indicator(i) = 1;
                    elseif eq(slope_value(i),0) && judgeValue<=fix((ma_window+1)*0.1)
                        indicator(i) = 0;
                    else
                        indicator(i) = indicator(i-1);
                    end
                end 
            else
                sprintf('只能选择模式1或者模式2')
            end
        end
    end
    methods(Static)
        function [h,sta_re,y_bac_0,y_bac_f,sub_signal_update] = get_high_order_signal(tref,r,sub_index_info)
            %参数
            wid_N = 20;
            wid_N2 = 90;
            cut_value = 0.1;%止损
            high_order = 5;
            alpha_pool = 0.05:0.05:0.5;
            T_alpha_pool = length(alpha_pool);
            alpha_wid_N = 120;

            alpha_para = zeros(alpha_wid_N,T_alpha_pool);
            for i = 1:alpha_wid_N
                sub_para = alpha_pool.*(1-alpha_pool).^(i-1);
                alpha_para(i,:) = sub_para;
            end
            alpha_para = flipud(alpha_para);
    
            T_tref = length(tref);    
            %signal
            r1 = r.^high_order;
            y_ref = movmean(r1,[wid_N-1,0]);
            y_ref(1:wid_N-1) = 0;
            %EMA deal
            y_ema = zeros(T_tref,T_alpha_pool);
            num0 = alpha_wid_N+wid_N;
            for i = num0:T_tref
                sub_wid = i-alpha_wid_N+1:i;
                sub_y1 = y_ref(sub_wid);
                sub_y2 = bsxfun(@times,alpha_para,sub_y1);
                sub_y3 = sum(sub_y2);
                y_ema(i,:) = sub_y3;
            end

            signal_all = zeros(T_tref-1,T_alpha_pool);
            signal_all(diff(y_ema)>0) = 1;
            signal_all(diff(y_ema)<0) = -1;
            %信号当天发出，第二天收盘执行（注意diff用法）
            signal_all = signal_all([1,1,1:end],:);
            signal_all(1:2) = 0;
            y = cumprod(1+r.*signal_all(1:end-1,:));
            %利用nan填充快速计算
            alpha_sel = nan(T_tref+1,1);
            alpha_sel(1) = 1;
            for i = wid_N2+1:wid_N2:T_tref+1
                sub_wid = i-wid_N2:i-1;
                sub_y = y(sub_wid,:);
                sub_y = sub_y(end,:)./sub_y(1,:)-1;
                [~,ia] = max(sub_y);
                alpha_sel(i) = ia;
                %signal_f(i) = signal_all(i,ia);
            end
            alpha_sel = fillmissing(alpha_sel,'previous');
            signal_f = zeros(size(signal_all(:,1)));
            for i = 1:length(signal_f)
                signal_f(i) = signal_all(i,alpha_sel(i));
            end
            r(1) = 0;
            %止损步骤
            T_sub_ind = length(r);
            r_cut_marker = 0;%是否触发
            r_cut_marker_his = zeros(size(signal_f));
            r_cut = 1;
            r_cut_dir = signal_f(1);
            sub_signal_update = zeros(size(signal_f));
            sub_signal_update(1) = signal_f(1);
            for i = 2:T_sub_ind+1
                if eq(r_cut_marker,1)
                    if eq(signal_f(i),r_cut_dir)
                        continue
                    else
                        %为了发出第二日信号添加标记
                        if i <=T_sub_ind
                            %重新计数
                            r_cut_marker = 0;
                            r_cut = 1;
                            r_cut_dir = signal_f(i);
                        end
                        sub_signal_update(i) = signal_f(i);
                    end
                else
                    if i<=T_sub_ind
                        sub_sub_r = r(i)*signal_f(i);
                        if eq(signal_f(i),r_cut_dir)
                            r_cut = r_cut*(1+sub_sub_r);
                        else
                            %重新计数
                            r_cut_marker = 0;
                            r_cut = 1;
                            r_cut_dir = signal_f(i);
                        end
                        if 1-r_cut>cut_value
                            r_cut_marker = 1;
                        end
                    end
                    %只要没有触发择时（下一日），继续当前信号
                    sub_signal_update(i) = signal_f(i);
                end   
                r_cut_marker_his(i) = r_cut_marker;
            end

            y_bac_0 = cumprod(1+r);
            y_bac_f = cumprod(1+r.*sub_signal_update(1:T_sub_ind));
            y_bac_0 = y_bac_0/y_bac_0(1)*100;
            y_bac_f = y_bac_f/y_bac_f(1)*100;
            [v0,v_str0] = curve_static(y_bac_0);
            [v0,v_str0] = ad_trans_sta_info(v0,v_str0);

            [v1,v_str1] = curve_static(y_bac_f);
            [v1,~] = ad_trans_sta_info(v1,v_str1);
            tref_next = yq_methods.get_tradingdate_future(tref{end});
            if length(tref_next)>1
                tref_next = tref_next{2};
            else
                tref_next = tref_next{1};
            end
            f_str = containers.Map([1,0,-1],{'做多','平仓','做空'});

            sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-高阶择时']};v1']];
            signal_info = {'择时信号',tref_next,f_str(sub_signal_update(end))};
            sta_re = [sub_sta;signal_info];

            h = figure;
            plot([y_bac_0,y_bac_f],'LineWidth',2)
            set(gca,'xlim',[1,length(r)]);
            set_x_tick(gca,tref)
            setpixelposition(gcf,[223,365,1345,420]);
            legend({'指数','高阶择时'},'NumColumns',2,'location','best');
            title(sub_index_info)
        end
        %paras
        %1信号次数
        %2频率
        %3胜率-曾发出过20次空仓信号，其中18次确实躲跌了，那胜率即为90%。
        %4赔率
        %5闪烁次数
        function [props,objH,recurve] = efplot(tref,indicator,y1,y2,indexName,fig_sel)
            if nargin <6
                fig_sel = 1;
            end
            %tref
            %indicator
            % clear;close all
            % load TestData.mat
            % fee = 0;
            % indexName = [];
            props = zeros(5,1);
            objH = [];

            ind1 = find(eq(indicator,0));
            ind2 = find(~eq(diff(ind1)-1,0));
            ind2 = unique([0;ind2;length(ind1)]);
            xEv = zeros(length(ind2)-1,2);
            for i = 1:size(xEv)
                subind = ind1([ind2(i)+1,ind2(i+1)]);
                xEv(i,:) = subind;
            end
            props(1) = size(xEv,1);
            props(2) = length(indicator)/size(xEv,1);
            %%%
%            [y1,y2] = obj.simuTrail2(tref,indicator,fee,1,indexName);
            y3 = y2./y1;
            y3 = y3/y3(1)*100;

            for i = 1:size(xEv,1)
                if y1(xEv(i,1))>y1(xEv(i,2))%成功躲跌
                    props(3)=props(3)+1;
                end
                if xEv(i,2)-xEv(i,1)<3
                    props(5) = props(5)+1; 
                end
            end
            props(3) = props(3)/size(xEv,1);
            props(4) = median(y2./y1);
            props(5) = props(5)/size(xEv,1);
            props(3:5) = props(3:5)*100;

            recurve = [tref,y1,y2];

            if eq(fig_sel,1)
                objH=figure;
                pos1 = getpixelposition(objH);
                setpixelposition(objH,[pos1(1:2),pos1(3),pos1(4)/3*2])
                plot(tref,[y1,y2,y3],'linewidth',2);
                hold on
                %plot(tref(indicator<1),xtref(indicator<1),'+');
                ylims = get(gca,'ylim');
                for i = 1:size(xEv,1)
                    obj1 = area(tref(xEv(i,:)),ylims([2,2]),ylims(1),...
                        'facecolor',[0.8,0.8,0.8],...
                        'edgecolor','none');
                end
                obj2=plot(tref,[y1,y2,y3],'linewidth',2);
                vsets = [0,0.447,0.741;0.85,0.325,0.098;0.929,0.694,0.125];
                for i = 1:length(obj2)
                    set(obj2(i),'color',vsets(i,:));
                end
                datetick('x','yyyy')
                if ~isempty(indexName)
                    title(indexName)
                end
                legend([obj1;obj2],{'空仓期','指数','多空','多空/指数'},'location','northwest')
            end
            sprintf('发出空仓信号%d次，频率为%%%0.2f,胜率为%%%0.2f，赔率为%%%0.2f，闪烁信号占比%%%0.2f',props)
        end
        %LLT(T)=(α-α^2/4)*PRICE(T)+(α^2/2)*PRICE(T-1)-(α-(3α^2)/4)*PRICE(T-2)+2(1-α)*LLT(T-1)-(1-α)^2*LLT(T-2)        
        function llt_value=get_llt_value(curve_value,window)
            if nargin < 2
                window = 30;
            end
            a=2/(window+1);
            llt_value=zeros(length(curve_value),1);
            llt_value(1:2)=curve_value(1:2);
            for i=3:length(curve_value)    
                llt_value(i)=(a-a^2/4)*curve_value(i)+(a^2/2)*curve_value(i-1)-(a-3*a^2/4)*curve_value(i-2)+2*(1-a)*llt_value(i-1)-(1-a)^2*llt_value(i-2);
            end
        end
        %T日收盘执行多空 %只能做多或清仓
        function [y1,y2] = simuTrail2(tref,indicator,tref0,closeV0,fee,p1)
        %input Test
        if nargin < 5
            fee = [];
        end
        if nargin < 6
            p1 = [];
        end

        if isempty(fee)
            fee = 0;
        end
        if isempty(p1)
            p1 = 1;
        end
        
        [~,ia] = intersect(tref0,tref);
        closeV0 = closeV0(ia,:);
        %openV0 = openV0(ia,:);
        %买卖大盘指数
        M0 = 1e10;
        %持有股票，或者持有金钱
        T = length(tref);
        cash = zeros(T,1);
        shares = zeros(T,1);%手持股数%不变
        cash(1) = M0;%cash现金余额%不变
        y = cash;
        state = 0;
        indicator(1) = 0;
        for i = 2:T
            if eq(indicator(i),0)%空信号
                if  eq(state,0)%状态为空仓
                    %keep，do nothing
                    cash(i) = cash(i-1);
                    shares(i) = shares(i-1);
                else%状态为多
                    %多转空 按照比例
                    M = cash(i-1)+shares(i-1)*closeV0(i);%总金额
                    %按照比例划分
                    %cash
                    %M1 = M*p1;
                    %shares
                    M2 = M*(1-p1);%用于购买share的金额
                    v1 = M2/closeV0(i)/(1+fee);%目标股数
                    %v3 = 0;
                    if v1>shares(i-1)
                        %买入
                        v2 = v1-shares(i-1);%差多少
                        v3 = v2*closeV0(i)*(1+fee);%费用
                        M1 = cash(i-1)-v3;%cash剩余
                    elseif v1<shares(i-1)
                        %卖出
                        v2 = shares(i-1) - v1;
                        v3 = v2*closeV0(i)*(1-fee);%卖出时总共得到的钱
                        M1 = cash(i-1)+v3;
                    else
                        M1 = cash(i-1);
                    end
                    shares(i) = v1;            
                    cash(i) = M1;%交易损失          
                end        
            else%指示下一期为多
                if  eq(state,0)%状态为空仓
                    %空转多 按照比例
                    M = cash(i-1)+shares(i-1)*closeV0(i);
                    %按照比例划分
                    %cash
                    %M1 = M*(1-p1);
                    %shares
                    %M2 = M*p1;
                    M2 = M;
                    v1 = M2/closeV0(i)/(1+fee);%目标股数
                    %v3 = 0;
                    if v1>shares(i-1)
                        %买入
                        v2 = v1-shares(i-1);
                        v3 = v2*closeV0(i)*(1+fee);%买入需要金额
                        M1 = cash(i-1)-v3;
                    elseif v1<shares(i-1)
                        %卖出
                        v2 = shares(i-1) - v1;
                        v3 = v2*closeV0(i)*(1-fee);%卖出得到金额
                        M1 = cash(i-1)+v3;
                    else
                        M1 = cash(i-1);%不变
                    end
                    shares(i) = v1;            
                    cash(i) = M1;%交易损失 
                else%多
                    %keep
                    %do nothing
                    cash(i) = cash(i-1);
                    shares(i) = shares(i-1);            
                end
            end
            state = indicator(i);
            %y(i+1) = cash(i)+shares(i)*closeV0(i+1);  
            y(i) = cash(i)+shares(i)*closeV0(i);  
        end
        %figure;
        y1 = closeV0/closeV0(1)*100;
        y2 = y/y(1)*100;
        %plot(tref,[y1,y2])
        end
        %%%%%%%%
    end
end