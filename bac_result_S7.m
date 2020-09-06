%{
优矿数据
证券交易所。可选：XSHG，XSHE，CCFX，XDCE，XSGE，XZCE，XHKG。
XSHG表示上海证券交易所，XSHE表示深圳证券交易所，
CCFX表示中国金融期货交易所，
XDCE表示大连商品交易所，
XSGE表示上海期货交易所，
XZCE表示郑州商品交易所，
XHKG表示香港证券交易所。
可同时输入多个证券交易所,可以是列表

akshare数据
dce 大商所
shfe 上商所
czce 郑商所
cffex 中金所
%}
classdef bac_result_S7 < handle
    properties
        obj1=strAdd('蜘蛛网策略综合信号');
        f_str1 = '%s：%s 信号为：  %s';
        f_str2 = containers.Map([-1,0,1],{'做空','平仓','做多'});
        
        tn = 'S37.S7_signal';
        var_info = {'code1','code2','tradingdate','f_val'};
    end
    methods
        function get_all_signal(obj)
            %股指期货信号
            get_stockindex_future_Sim_signal(obj)
            %国债期货信号
            get_all_treasury_signal(obj)
            %郑商所所有期货信号
            get_CZCE_all_signal(obj)
            %大商所和上商所
        	get_DCE_all_signal(obj)
            get_SHFE_all_signal(obj)
            obj.obj1.batch_cell_str(obj.obj1.str1)
        end
        function get_all_results(obj)
            %写入数据库
            obj.update_all_signal();
            %写入word
            file_name = sprintf('S7蜘蛛网择时%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            re = [];
            re = cat(1,re,stockindex_future_Sim_bac(obj,obj_wd));
            re = cat(1,re,all_treasury_signal_bac(obj,obj_wd));
            re = cat(1,re,CZCE_all_bac(obj,obj_wd));
            re = cat(1,re,DCE_all_signal_bac(obj,obj_wd));
            re = cat(1,re,SHFE_all_signal_bac(obj,obj_wd));
            obj_wd.CloseWord()  
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
            
        end
        function update_all_signal(obj)
            %股指期货信号更新
            obj.update_stockindex_future_Sim_signal()
            %国债期货信号
            obj.update_all_treasury_signal()
            %郑商所所有期货信号
            obj.update_CZCE_all_signal()
            %大商所所有期货信号
            obj.update_DCE_all_signal();
            %上商所
            obj.update_SHFE_all_signal();
        end
        %股指期货信号
        function get_stockindex_future_Sim_signal(obj)
            obj.obj1.A('股指期货信号2(核对信号)：')
            index_all = {'IF','IC','IH'};
            index_name = {'沪深300股指期货','中证500股指期货','上证50股指期货'};
            T = length(index_all);
            info = cell(T,1);
            parfor type_sel = 1:T
                [tref,signal1] = obj.get_stock_index_Sim_signal(index_all{type_sel});
                info{type_sel} = sprintf(obj.f_str1,tref{1},index_name{type_sel},obj.f_str2(signal1));                
            end     
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        function update_stockindex_future_Sim_signal(obj)
            obj.obj1.A('股指期货信号2(核对信号)：')
            index_all = {'IF','IC','IH'};
            index_name = {'沪深300股指期货','中证500股指期货','上证50股指期货'};
            T = length(index_all);
            info = cell(T,1);
            for type_sel = 1:T
                [tref,signal1] = obj.get_stock_index_Sim_signal_all(index_all{type_sel});
                info{type_sel} = sprintf(obj.f_str1,tref{end},index_name{type_sel},obj.f_str2(signal1(end)));                
            end     
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        function re = stockindex_future_Sim_bac(obj,obj_wd)
            key_str = '股指期货回测';
            index_all = {'IF','IC','IH'};
            code1 = 'CCFX';
            index_name = {'沪深300股指期货','中证500股指期货','上证50股指期货'};
            T = length(index_all);
            re = cell(T,1);
            for type_sel = 1:T
                [tref,y_bac] = bac_test_sim(obj,code1,index_all{type_sel}); 
                %作图，统计
                title_str = sprintf('%s-%s',key_str,index_name{type_sel});
                h = obj.bac_figure(tref,y_bac);
                title(title_str);
                obj_wd.pasteFigure(h,title_str);
                [v,v_str] = curve_static(y_bac');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(type_sel,1)
                    sub_re =[[{key_str};v_str1'],[index_name{type_sel};v1']];
                else
                    sub_re = [index_name{type_sel};v1'];
                end
                
                re{type_sel} = sub_re;
            end     
            re = [re{:}]';
        end
        %郑商所所有期货信号
        function re = CZCE_all_bac(obj,obj_wd)  
            key_str = '郑商所';
            ECD = 'czce';
            code1 = 'XZCE';
            %获取所有期货类型
            tref0 = obj.get_newest_date(ECD);
            code_all = obj.get_news_code(ECD,tref0{1});
            T = length(code_all);
            re = cell(T,1);
            for i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(tref0{1},code_all{i});                
                if isempty(tickername)
                    tickername = code_all{i};
                else
                    if iscell(tickername)
                        tickername = tickername{1};
                    end
                end
                code2 = code_all{i};
                [tref,y_bac] = bac_test_sim(obj,code1,code2);
                if length(tref)<100
                    continue
                end
                %作图，统计
                h = obj.bac_figure(tref,y_bac);
                title_str = sprintf('%s-%s',key_str,tickername);
                obj_wd.pasteFigure(h,title_str);
                
                [v,v_str] = curve_static(y_bac');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(i,1)
                    sub_re =[[{key_str};v_str1'],[tickername;v1']];
                else
                    sub_re = [tickername;v1'];
                end
                
                re{i} = sub_re;
            end     
            re = [re{:}]';

        end
        
        function re = DCE_all_signal_bac(obj,obj_wd)     
            key_str = '大商所';
            ECD = 'dce';
            code1 = 'XDCE';
            t0 = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,t0{1});
            T = length(code_all);
            re = cell(T,1);
            for i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(t0{1},code_all{i});
                if isempty(tickername)
                    tickername = code_all{i};
                else
                    if iscell(tickername)
                        tickername = tickername{1};
                    end
                end
                code2 = code_all{i};
                [tref,y_bac] = bac_test_sim(obj,code1,code2);
                if length(tref)<100
                    continue
                end
                %作图，统计
                h = obj.bac_figure(tref,y_bac);
                title_str = sprintf('%s-%s',key_str,tickername);
                obj_wd.pasteFigure(h,title_str);
                [v,v_str] = curve_static(y_bac');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(i,1)
                    sub_re =[[{key_str};v_str1'],[tickername;v1']];
                else
                    sub_re = [tickername;v1'];
                end
                
                re{i} = sub_re;
            end     
            re = [re{:}]';
        end
        
        function re = SHFE_all_signal_bac(obj,obj_wd)     
            key_str = '上商所';
            ECD = 'shfe';
            code1 = 'XSGE';
            t0 = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,t0{1});
            T = length(code_all);
            re = cell(T,1);
            for i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(t0{1},code_all{i});
                if isempty(tickername)
                    tickername = code_all{i};
                else
                    if iscell(tickername)
                        tickername = tickername{1};
                    end
                end
                code2 = code_all{i};
                [tref,y_bac] = bac_test_sim(obj,code1,code2);
                if length(tref)<100
                    continue
                end
                %作图，统计
                title_str = sprintf('%s-%s',key_str,tickername);
                h = obj.bac_figure(tref,y_bac);                
                obj_wd.pasteFigure(h,title_str);
                [v,v_str] = curve_static(y_bac');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(i,1)
                    sub_re =[[{key_str};v_str1'],[tickername;v1']];
                else
                    sub_re = [tickername;v1'];
                end
                
                re{i} = sub_re;
            end     
            re = [re{:}]';
        end
        
        %国债期货信号
        function re = all_treasury_signal_bac(obj,obj_wd)
            key_str = '国债';
            code1 = 'CCFX';
            code_all = {'TS','TF','T'};
            code_name = {'2年期国债期货','5年期国债期货','10年期国债期货'};
            T = length(code_all);
            re = cell(T,1);
            for type_sel = 1:T
                [tref,y_bac] = bac_test_sim(obj,code1,code_all{type_sel}); 
                %作图，统计
                h = obj.bac_figure(tref,y_bac);
                title_str = sprintf('%s-%s',key_str,code_name{type_sel});
                obj_wd.pasteFigure(h,title_str);
                
                [v,v_str] = curve_static(y_bac');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(type_sel,1)
                    sub_re =[[{key_str};v_str1'],[code_name{type_sel};v1']];
                else
                    sub_re = [code_name{type_sel};v1'];
                end
                
                re{type_sel} = sub_re;
            end     
            re = [re{:}]';
            
        end
        
        %国债期货信号
        function get_all_treasury_signal(obj)
            code_all = {'TS','TF','T'};
            code_name = {'2年期国债期货','5年期国债期货','10年期国债期货'};
            obj.obj1.A('国债期货信号：');
            T = length(code_name);
            info = cell(T,1);
            parfor i = 1:T
                index_sel = code_all{i};
                [tref,signal1] = obj.get_spyder_treasury_signal(index_sel);
                info{i} = sprintf(obj.f_str1,tref{1},code_name{i},obj.f_str2(signal1));
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        %国债期货信号
        function update_all_treasury_signal(obj)
            code_all = {'TS','TF','T'};
            code_name = {'2年期国债期货','5年期国债期货','10年期国债期货'};
            obj.obj1.A('国债期货信号：');
            T = length(code_name);
            info = cell(T,1);
            for i = 1:T
                index_sel = code_all{i};
                [tref,signal1] = obj.get_spyder_treasury_signal_all(index_sel,code_name{i});
                info{i} = sprintf(obj.f_str1,tref{end},code_name{i},obj.f_str2(signal1(end)));
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        %大商所
        function update_DCE_all_signal(obj)     
            obj.obj1.A('大商所期货信号：');
            ECD = 'dce';
            t0 = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,t0{1});
            T = length(code_all);
            info = cell(T,1);
            for i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(t0{1},code_all{i});
                if isempty(tickername)
                    continue
                end
                %合约对应名称                
                [ind_signal,sub_type_sel_str] = obj.get_shfe_dce_signal_all(ECD,code_all{i},tickername{1});
                if ~isnan(ind_signal(end))
                    info{i} = sprintf(obj.f_str1,t0{end},'大商所',sub_type_sel_str,obj.f_str2(ind_signal(end)));
                else
                    info{i} = sprintf(obj.f_str1,t0{end},'大商所',sub_type_sel_str,'无数据');
                end
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        %上商所
        function update_SHFE_all_signal(obj)     
            obj.obj1.A('上商所期货信号：');
            ECD = 'shfe';
            t0 = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,t0{1});
            T = length(code_all);
            info = cell(T,1);
            for i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(t0{1},code_all{i});
                if isempty(tickername)
                    continue
                end
                if iscell(tickername)
                    tickername = tickername{1};
                end
                %合约对应名称                
                [ind_signal,sub_type_sel_str] = obj.get_shfe_dce_signal_all2(ECD,code_all{i},tickername);
                if ~isnan(ind_signal(end))
                    info{i} = sprintf(obj.f_str1,t0{end},'上商所',sub_type_sel_str,obj.f_str2(ind_signal(end)));
                else
                    info{i} = sprintf(obj.f_str1,t0{end},'上商所',sub_type_sel_str,'无数据');
                end
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        %郑商所所有期货信号
        function update_CZCE_all_signal(obj)     
            obj.obj1.A('郑商所期货信号：');
            ECD = 'czce';
            tref = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,tref{1});
            T = length(code_all);
            info = cell(T,1);
            for i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(tref{1},code_all{i});
                if isempty(tickername)
                    continue
                end
                %合约对应名称                
                [ind_signal,sub_type_sel_str] = obj.get_spyder_czce_signal_all(ECD,code_all{i},tickername{1});
                if ~isnan(ind_signal)
                    info{i} = sprintf(obj.f_str1,tref{end},'郑商所',sub_type_sel_str,obj.f_str2(ind_signal(end)));
                else
                    info{i} = sprintf(obj.f_str1,tref{end},'郑商所',sub_type_sel_str,'无数据');
                end
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        
        %郑商所所有期货信号
        function get_CZCE_all_signal(obj)     
            obj.obj1.A('郑商所期货信号：');
            ECD = 'czce';
            tref = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,tref{1});
            T = length(code_all);
            info = cell(T,1);
            parfor i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(tref{1},code_all{i});
                if isempty(tickername)
                    continue
                end
                %合约对应名称                
                [ind_signal,sub_type_sel_str] = obj.get_spyder_czce_signal(ECD,code_all{i},tickername{1},tref);
                if ~isnan(ind_signal)
                    info{i} = sprintf(obj.f_str1,tref{1},'郑商所',sub_type_sel_str,obj.f_str2(ind_signal));
                else
                    info{i} = sprintf(obj.f_str1,tref{1},'郑商所',sub_type_sel_str,'无数据');
                end
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        %大商所和上商所
        function get_DCE_all_signal(obj)     
            obj.obj1.A('大商所期货信号：');
            ECD = 'dce';
            tref = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,tref{1});
            T = length(code_all);
            info = cell(T,1);
            parfor i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(tref{1},code_all{i});
                if isempty(tickername)
                    continue
                end
                %合约对应名称                
                [ind_signal,sub_type_sel_str] = obj.get_shfe_dce_signal(ECD,code_all{i},tickername{1},tref);
                if ~isnan(ind_signal)
                    info{i} = sprintf(obj.f_str1,tref{1},'大商所',sub_type_sel_str,obj.f_str2(ind_signal));
                else
                    info{i} = sprintf(obj.f_str1,tref{1},'大商所',sub_type_sel_str,'无数据');
                end
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
        %%%%%%%%%%
        function get_SHFE_all_signal(obj)     
            obj.obj1.A('上商所期货信号：');
            ECD = 'shfe';
            tref = obj.get_newest_date(ECD);
            %获取所有期货类型
            code_all = obj.get_news_code(ECD,tref{1});
            T = length(code_all);
            info = cell(T,1);
            parfor i = 1:T
                %主力合约
                [~,tickername] = obj.get_main_tick(tref{1},code_all{i});
                if isempty(tickername)
                    continue
                end
                %合约对应名称                
                [ind_signal,sub_type_sel_str] = obj.get_shfe_dce_signal(ECD,code_all{i},tickername{1},tref);
                if ~isnan(ind_signal)
                    info{i} = sprintf(obj.f_str1,tref{1},'上商所',sub_type_sel_str,obj.f_str2(ind_signal));
                else
                    info{i} = sprintf(obj.f_str1,tref{1},'上商所',sub_type_sel_str,'无数据');
                end
            end
            for i = 1:T
                obj.obj1.A(info{i});
            end
        end
    end
    methods
        %写入数据库版本
        function [tref,index,re] = get_stock_index_Sim_signal_all(obj,index_sel)
            db_long = 'yuqerdata.yq_MktFutMLRGet';
            db_short = 'yuqerdata.yq_MktFutMSRGet';
            %tref
            sql_str = ['select tradeDate from %s where exchangeCD=''CCFX'' ',...
                'and ticker like ''%s%%'' order by tradeDate'];
            tref1 = fetchmysql(sprintf(sql_str,db_long,index_sel),2);
            tref2 = fetchmysql(sprintf(sql_str,db_short,index_sel),2);
            tref = intersect(tref1,tref2);
            code1 = 'CCFX';
            code2 = index_sel;
            t0 = obj.get_t0(code1,code2);
            if isempty(t0)
                num0 = 0;
            else
                num0 = find(strcmp(tref,t0));
            end
            %step1 合成信号
            %   data
            sql_str = ['select sum(CHG) from %s where exchangeCD=''CCFX'' ',...
                ' and ticker like ''%s%%'' and tradeDate =''%s''']';
            index = zeros(size(tref));
            T = length(tref);
            parfor i = max(num0,1):T
                sub_t = tref{i};
                %获取成交量数据
                data_ITS_UTS_Price = zeros(1,2);
                data_ITS_UTS_Price(1,1)=fetchmysql(sprintf(sql_str,db_long,index_sel,sub_t));
                data_ITS_UTS_Price(1,2)=fetchmysql(sprintf(sql_str,db_short,index_sel,sub_t));

                if data_ITS_UTS_Price(:,1)>0&&data_ITS_UTS_Price(:,2)<0
                    index(i) = 1;
                elseif data_ITS_UTS_Price(:,1)<0&&data_ITS_UTS_Price(:,2)>0
                    index(i) = -1;
                end
                sprintf('股指期货信号计算 %d-%d',i,T)
            end
            re = [tref,tref,tref,num2cell(index)];
            re(:,1) = {'CCFX'};
            re(:,2) = {index_sel};
            re = re(num0+1:end,:);
            obj.insert_S7_data(re);
        end
        %国债期货信号
        function  [tref,ind_signal] = get_spyder_treasury_signal_all(obj,index_sel,index_name)
            code1 = 'CCFX';
            code2 = index_sel;
            db_vol = 'yuqerdata.yq_MktFutMTRGet';
            db_long = 'yuqerdata.yq_MktFutMLRGet';
            db_short = 'yuqerdata.yq_MktFutMSRGet';
            %tref
            sql_str = ['select distinct(tradeDate) from %s where exchangeCD=''CCFX'' ',...
                'and secShortName like ''%s%%'' order by tradeDate'];
            tref = fetchmysql(sprintf(sql_str,db_long,index_name),2);
            %获取主力合约名称
            sql_ticker = ['select ticker from yuqerdata.yq_MktMFutdGet where ',...
                'tradeDate = ''%s'' and contractObject=''%s'' and mainCon=1'];
            sql_total = ['select turnoverVol from  %s ',...
                'where exchangeCD=''CCFX'' and tradeDate = ''%s'' and ticker =''%s'' order by rank'];
            sql_long = ['select longVol,CHG from  %s ',...
                'where exchangeCD=''CCFX'' and tradeDate = ''%s'' and ticker =''%s'' order by rank'];
            sql_short = ['select shortVol,CHG from  %s ',...
                'where exchangeCD=''CCFX'' and tradeDate = ''%s'' and ticker =''%s'' order by rank'];
            T = length(tref);
            t0 = obj.get_t0(code1,code2);
            if isempty(t0)
                num0 = 0;
            else
                num0 = find(strcmp(tref,t0));
            end
            
            data_process = cell(T,1);
            parfor i = max(num0,1):T            
                sub_t = tref{i};
                %sub_t = '2019-04-15';
                %%%%%%%%%%%%%%%%%%                
                ticker = fetchmysql(sprintf(sql_ticker,sub_t,index_sel),2);
                %%%%%%%%%%%%%%
                if isempty(ticker)
                    data_process{i} = zeros(6,1);
                    continue
                end
                sub_vol_turnover = fetchmysql(sprintf(sql_total,db_vol,sub_t,ticker{1}));
                sub_vol_total = sum(sub_vol_turnover);

                sub_long=fetchmysql(sprintf(sql_long,db_long,sub_t,ticker{1}));

                sub_short=fetchmysql(sprintf(sql_short,db_short,sub_t,ticker{1}));

                m = [size(sub_vol_turnover,1),size(sub_long,1),size(sub_short,1)];
                sub_x_d = zeros(max(m),5);
                sub_x_d(1:m(1),1) = sub_vol_turnover;
                sub_x_d(1:m(2),2:3) = sub_long;
                sub_x_d(1:m(2),4:5) = sub_short;
                %data_process = zeros(T,6);
                %1dB,2dS,3Nvol,4Nbuy,5Nsell,6Rvol(成交量占比)

                %1'volume',2'volume_buy',3'd_volume_buy',4'volume_sail',5'd_volume_sail'
                dB = sum(sub_x_d(:,3));
                dS = sum(sub_x_d(:,5));
                NV = sum(~eq(sub_x_d(:,1),0));
                NVb = sum(~eq(sub_x_d(:,2),0));
                NVs = sum(~eq(sub_x_d(:,4),0));
                RV = sum(sub_x_d(:,1))/sub_vol_total;
                %保存
                data_process{i} = [dB,dS,NV,NVb,NVs,RV]';
                sprintf('国债期货信号%d-%d',i,T)
            end
            data_process = [data_process{:}]';
            % 计算信号
            ind_signal = zeros(T,1);
            ind_signal(data_process(:,1)-data_process(:,2)>0) = 1;
            ind_signal(data_process(:,1)-data_process(:,2)<0) = -1;
            % 过滤信号1
            ind_signal(data_process(:,3)<20|data_process(:,4)<20|data_process(:,5)<20) = 0;
            % 过滤信号2
            ind_signal(data_process(:,6)<0.71) = 0;
            % 过滤信号3
            
            re = [tref,tref,tref,num2cell(ind_signal)];
            re(:,1) = {code1};
            re(:,2) = {index_sel};
            re = re(num0+1:end,:);
            obj.insert_S7_data(re);            
        end
        %%%%%%%%%%
        function [ind,sub_type_sel_str] = get_spyder_czce_signal_all(obj,index_sel,type_commodity_sel,tickername)
            code1 = 'XZCE';
            code2 = type_commodity_sel;
            sub_type_sel_str = tickername;
            db_name = 'futuredata';
            tb_name_d = sprintf('%s_data',index_sel);
            tn_all = sprintf('%s.%s',db_name,tb_name_d);
            sql_str = 'select distinct(tradingdate) from %s where codename = ''%s'' order by tradingdate';
            tref = fetchmysql(sprintf(sql_str,tn_all,type_commodity_sel),2);
            T = length(tref);
            t0 = obj.get_t0(code1,code2);
            if isempty(t0)
                num0 = 0;
            else
                num0 = find(strcmp(tref,t0));
            end
            
            ind = zeros(size(tref));
            parfor i = max(1,num0):T
                ind(i) = obj.get_spyder_czce_signal(index_sel,type_commodity_sel,tickername,tref(i));
                sprintf('S7郑商所数据更新 %s：%d-%d',type_commodity_sel, i,T)
            end
            re = [tref,tref,tref,num2cell(ind)];
            re(:,1) = {code1};
            re(:,2) = {code2};
            re = re(num0+1:end,:);
            obj.insert_S7_data(re);   
        end
        
        
        function insert_S7_data(obj,re)
            if ~isempty(re)
               datainsert_adair(obj.tn,obj.var_info,re); 
            end
        end
        function t0 = get_t0(obj,code1,code2)
            sql_str = ['select tradingdate from %s where code1 = ''%s'' ',...
                'and code2 = ''%s'' order by tradingdate desc limit 1'];
            t0 = fetchmysql(sprintf(sql_str,obj.tn,code1,code2),2);
        end
        function [tref,y_bac] = bac_test_sim(obj,code1,code2)
            sql_str = ['select ticker,tradeDate,settlePrice/preSettlePrice-1 ',...
                'from yuqerdata.yq_MktMFutdGet where exchangeCD=''%s'' ',...
                'and contractObject = ''%s'' and mainCon=1 order by tradeDate'];
            x = fetchmysql(sprintf(sql_str,code1,code2),2);
            sql_str2 = 'select tradingdate,f_val from %s where code1=''%s'' and code2=''%s'' order by tradingdate';
            y = fetchmysql(sprintf(sql_str2,obj.tn,code1,code2),2);
            if isempty(x) || isempty(y)
                tref = [];
                y_bac = [];
                return
            end
            [tref,ia,ib] = intersect(x(:,2),y(:,1));
            ticker = x(ia,1);
            x = cell2mat(x(ia,3));
            y = cell2mat(y(ib,2));
            y(2:end) = y(1:end-1);
            %换约修正
            for i = 2:length(ticker)
                if ~strcmp(ticker(i),ticker(i-1))
                    x(i) = 0;
                end
            end            
            y_bac = 1+cumsum(y.*x);
            %y_bac = cumprod(1+y.*x);
            
        end
        function [ind,sub_type_sel_str] = get_shfe_dce_signal_all(obj,index_sel,type_commodity_sel,tickername)
           
            code1 = 'XDCE';
            code2 = type_commodity_sel;
            sub_type_sel_str = tickername;
            db_name = 'futuredata';
            tb_name_d = sprintf('%s_data',index_sel);
            tn_all = sprintf('%s.%s',db_name,tb_name_d);
            sql_str = 'select distinct(tradingdate) from %s where variety = ''%s'' order by tradingdate';
            tref = fetchmysql(sprintf(sql_str,tn_all,type_commodity_sel),2);
            T = length(tref);
            t0 = obj.get_t0(code1,code2);
            if isempty(t0)
                num0 = 0;
            else
                num0 = find(strcmp(tref,t0));
            end
            
            ind = zeros(size(tref));
            parfor i = max(1,num0):T
                ind(i) = obj.get_shfe_dce_signal(index_sel,type_commodity_sel,tickername,tref(i));
                sprintf('S7大商所数据更新 %s：%d-%d',type_commodity_sel, i,T)
            end
            re = [tref,tref,tref,num2cell(ind)];
            re(:,1) = {code1};
            re(:,2) = {code2};
            re = re(num0+1:end,:);
            obj.insert_S7_data(re);
        end
        
        function [ind,sub_type_sel_str] = get_shfe_dce_signal_all2(obj,index_sel,type_commodity_sel,tickername)
           
            code1 = 'XSGE';
            code2 = type_commodity_sel;
            sub_type_sel_str = tickername;
            db_name = 'futuredata';
            tb_name_d = sprintf('%s_data',index_sel);
            tn_all = sprintf('%s.%s',db_name,tb_name_d);
            sql_str = 'select distinct(tradingdate) from %s where variety = ''%s'' order by tradingdate';
            tref = fetchmysql(sprintf(sql_str,tn_all,type_commodity_sel),2);
            T = length(tref);
            t0 = obj.get_t0(code1,code2);
            if isempty(t0)
                num0 = 0;
            else
                num0 = find(strcmp(tref,t0));
            end
            
            ind = zeros(size(tref));
            parfor i = max(1,num0):T
                ind(i) = obj.get_shfe_dce_signal(index_sel,type_commodity_sel,tickername,tref(i));
                sprintf('S7上商所数据更新 %s：%d-%d',type_commodity_sel, i,T)
            end
            re = [tref,tref,tref,num2cell(ind)];
            re(:,1) = {code1};
            re(:,2) = {code2};
            re = re(num0+1:end,:);
            obj.insert_S7_data(re);
        end
        
    end
    methods(Static)
        function [ind_signal,sub_type_sel_str] = get_shfe_dce_signal(index_sel,type_commodity_sel,tickername,tref)
            db_name = 'futuredata';      
            tb_name_d = sprintf('%s_data',index_sel);
            sub_type_sel_str = tickername;
            
            var_d_sel = strjoin({'vol_party_name','long_party_name', 'short_party_name','vol', 'vol_chg','long_openIntr',...
            'long_openIntr_chg', 'short_openIntr','short_openIntr_chg'},',');

            if isempty(tref)
                ind_signal = 0;
                tref = '1900-01-01';
                return
            end
            T = length(tref);

            sql_str_detail = 'select %s from %s.%s where tradingdate = ''%s'' and variety = ''%s''';
            data_process = zeros(T,2);
            %1B,2S,3V,4dB,5dS,
            %1ITS,2,UTS,3openprice,4closeprice
            i=1;
            sub_t = tref{i};
            %获取所有合约成交量数据
            sql_str2 = sprintf(sql_str_detail,var_d_sel,db_name,tb_name_d,sub_t,type_commodity_sel);
            sub_x_d = fetchmysql(sql_str2,2);    
            sub_x_d(strcmp(sub_x_d(:,1),'null'),:) = [];
            %sub_x_d_company_name = sub_x_d(:,1:3);
            sub_x_d_data = cell2mat(sub_x_d(:,4:end));
            %1'volume',2'd_volume',3'volume_buy',4'd_volume_buy',5'volume_sail',6'd_volume_sail'
            if ~isempty(sub_x_d_data)
                d_m = sum(sub_x_d_data(:,[4,6]),1);
                data_process(i,:) = d_m;
            end
            ind_signal = zeros(T,1);
            ind_signal(data_process(:,1)>0&data_process(:,2)<0) = 1;
            ind_signal(data_process(:,1)<0&data_process(:,2)>0) = -1;
        end
        %%%%%%%%%%
        function [ind_signal,sub_type_sel_str] = get_spyder_czce_signal(index_sel,type_commodity_sel,tickername,tref)
            db_name = 'futuredata';
            tb_name_d = sprintf('%s_data',index_sel);
            sub_type_sel_str = tickername;
            var_d_sel = strjoin({'vol_party_name','long_party_name', 'short_party_name','vol', 'vol_chg','long_openIntr',...
            'long_openIntr_chg', 'short_openIntr','short_openIntr_chg'},',');
            T = length(tref);
            sql_str_detail = 'select %s from %s.%s where tradingdate = ''%s'' and variety = ''%s'' and rank < 999';
            data_process = zeros(T,2);
            %1B,2S,3V,4dB,5dS,
            %1ITS,2,UTS,3openprice,4closeprice
            i=1;
            %获取当日数据开盘价、收盘价
            sub_t = tref{i};
            %获取所有合约成交量数据
            sql_str2 = sprintf(sql_str_detail,var_d_sel,db_name,tb_name_d,sub_t,type_commodity_sel);
            sub_x_d = fetchmysql(sql_str2,2);    
            sub_x_d(strcmp(sub_x_d(:,1),'null'),:) = [];
            %sub_x_d_company_name = sub_x_d(:,1:3);
            sub_x_d_data = cell2mat(sub_x_d(:,4:end));
            %1'volume',2'd_volume',3'volume_buy',4'd_volume_buy',5'volume_sail',6'd_volume_sail'
            if ~isempty(sub_x_d_data)
                d_m = sum(sub_x_d_data(:,[4,6]),1);
                data_process(i,:) = d_m;
            end
            ind_signal = zeros(T,1);
            ind_signal(data_process(:,1)>0&data_process(:,2)<0) = 1;
            ind_signal(data_process(:,1)<0&data_process(:,2)>0) = -1;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%
        function [ticker,tickername] = get_main_tick(sub_t,index_sel)
            sql_ticker = ['select ticker,secShortName from yuqerdata.yq_MktMFutdGet where ',...
                'tradeDate = ''%s'' and contractObject=''%s'' and mainCon=1'];
            temp = fetchmysql(sprintf(sql_ticker,sub_t,index_sel),2);
            if eq(length(temp),2)
                ticker= temp(1);
                tickername = temp(2);
            else
                ticker=[];
                tickername=[];
            end
            
        end
        function code_all = get_news_code(ECD,sub_t)
            sql_str = ['select distinct(variety) from futuredata.%s_data ',...
                'where tradingdate=''%s'''];
            code_all = fetchmysql(sprintf(sql_str,ECD,sub_t),2);
        end
        function tref = get_newest_date(ECD)
            tref = fetchmysql(sprintf(['select tradingdate from futuredata.%s_data ',...
                'order by tradingdate desc limit 1'],ECD),2);
        end        
                
        function [tref,index] = get_stock_index_Sim_signal(index_sel)
            db_long = 'yuqerdata.yq_MktFutMLRGet';
            db_short = 'yuqerdata.yq_MktFutMSRGet';
            %tref
            sql_str = ['select tradeDate from %s where exchangeCD=''CCFX'' ',...
                'and ticker like ''%s%%'' order by tradeDate desc limit 1'];
            tref1 = fetchmysql(sprintf(sql_str,db_long,index_sel),2);
            tref2 = fetchmysql(sprintf(sql_str,db_short,index_sel),2);
            tref = [tref1,tref2];
            [~,ia] = sort(datenum(tref));
            tref = tref(ia(1));
            %step1 合成信号
            %   data
            sql_str = ['select sum(CHG) from %s where exchangeCD=''CCFX'' ',...
                ' and ticker like ''%s%%'' and tradeDate =''%s''']';
            i = 1;
            %
            sub_t = tref{i};
            %获取成交量数据
            data_ITS_UTS_Price(1,1)=fetchmysql(sprintf(sql_str,db_long,index_sel,sub_t));
            data_ITS_UTS_Price(1,2)=fetchmysql(sprintf(sql_str,db_short,index_sel,sub_t));
            
            index = zeros(size(tref));
            index(data_ITS_UTS_Price(:,1)>0&data_ITS_UTS_Price(:,2)<0)=1;
            index(data_ITS_UTS_Price(:,1)<0&data_ITS_UTS_Price(:,2)>0)=-1;
        end
        %国债期货信号
        function  [tref,ind_signal] = get_spyder_treasury_signal(index_sel)
            db_vol = 'yuqerdata.yq_MktFutMTRGet';
            db_long = 'yuqerdata.yq_MktFutMLRGet';
            db_short = 'yuqerdata.yq_MktFutMSRGet';
            %tref
            sql_str = ['select tradeDate from %s where exchangeCD=''CCFX'' ',...
                'and ticker like ''%s%%'' order by tradeDate desc limit 1'];
            tref1 = fetchmysql(sprintf(sql_str,db_long,index_sel),2);
            tref2 = fetchmysql(sprintf(sql_str,db_short,index_sel),2);
            tref3 = fetchmysql(sprintf(sql_str,db_vol,index_sel),2);
            tref = [tref1,tref2,tref3];
            [~,ia] = sort(datenum(tref));
            tref = tref(ia(1));
            T = length(tref);
            sub_t = tref{1};
            %sub_t = '2019-04-15';
            %%%%%%%%%%%%%%%%%%
            %获取主力合约名称
            sql_ticker = ['select ticker from yuqerdata.yq_MktMFutdGet where ',...
                'tradeDate = ''%s'' and contractObject=''%s'' and mainCon=1'];
            ticker = fetchmysql(sprintf(sql_ticker,sub_t,index_sel),2);
            %%%%%%%%%%%%%%
            sql_total = ['select turnoverVol from  %s ',...
                'where exchangeCD=''CCFX'' and tradeDate = ''%s'' and ticker =''%s'' order by rank'];
            sub_vol_turnover = fetchmysql(sprintf(sql_total,db_vol,sub_t,ticker{1}));
            sub_vol_total = sum(sub_vol_turnover);
            sql_long = ['select longVol,CHG from  %s ',...
                'where exchangeCD=''CCFX'' and tradeDate = ''%s'' and ticker =''%s'' order by rank'];
            sub_long=fetchmysql(sprintf(sql_long,db_long,sub_t,ticker{1}));
            sql_short = ['select shortVol,CHG from  %s ',...
                'where exchangeCD=''CCFX'' and tradeDate = ''%s'' and ticker =''%s'' order by rank'];
            sub_short=fetchmysql(sprintf(sql_short,db_short,sub_t,ticker{1}));
            
            m = [size(sub_vol_turnover,1),size(sub_long,1),size(sub_short,1)];
            sub_x_d = zeros(max(m),5);
            sub_x_d(1:m(1),1) = sub_vol_turnover;
            sub_x_d(1:m(2),2:3) = sub_long;
            sub_x_d(1:m(2),4:5) = sub_short;
            %data_process = zeros(T,6);
            %1dB,2dS,3Nvol,4Nbuy,5Nsell,6Rvol(成交量占比)
            
            %1'volume',2'volume_buy',3'd_volume_buy',4'volume_sail',5'd_volume_sail'
            dB = sum(sub_x_d(:,3));
            dS = sum(sub_x_d(:,5));
            NV = sum(~eq(sub_x_d(:,1),0));
            NVb = sum(~eq(sub_x_d(:,2),0));
            NVs = sum(~eq(sub_x_d(:,4),0));
            RV = sum(sub_x_d(:,1))/sub_vol_total;
            %保存
            data_process(1,:) = [dB,dS,NV,NVb,NVs,RV];

            % 计算信号
            ind_signal = zeros(T,1);
            ind_signal(data_process(:,1)-data_process(:,2)>0) = 1;
            ind_signal(data_process(:,1)-data_process(:,2)<0) = -1;
            % 过滤信号1
            ind_signal(data_process(:,3)<20|data_process(:,4)<20|data_process(:,5)<20) = 0;
            % 过滤信号2
            ind_signal(data_process(:,6)<0.71) = 0;
            % 过滤信号3
        end
        function h = bac_figure(tref,y,obj_wd)
            h = bpcure_plot_updateV2(tref,y);
            setpixelposition(h,[223,365,1345,420]);
            if nargin>2
                obj_wd.pasteFigure(h,title_str);
            end
        end
        %%%%%%%%%%%%
    end
end

function h = bpcure_plot_updateV2(t,x,str,lstr,sel)
h = figure;
%3/1
if nargin < 5
    sel = 2;%两种图都画
end
if nargin < 4
    lstr = [];
end
if nargin < 3
    str = [];
end
if nargin < 2
    x = t(:,2);
    t = t(:,1); 
end

if isnumeric(t)
    t = cellstr(datestr(t,'yyyymmdd'));
end

if eq(sel,2)
%     hold on
%     ylims1 = [min(min(x)),max(max(x))];
%     pic_lim = [-diff(ylims1)/100,diff(ylims1)/100];
%     ylims1 = ylims1+pic_lim;
%     ylims1(1) = ylims1(1)-diff(ylims1)/3;
%     ylim(ylims1)

    v = getdrawdown(x)*100;
    %subplot(1,2,2);
    yyaxis right
    %bar(t,v)
    %plot(t,v);
    %myplot(t,v);
    obj_L = mybar(v,[0.5,0.5,0.5]);
%    lims = axis(gca);
%     plot(lims(1:2),[0,0],'linewidth',2)
    datetick('x','yyyy');

%     ylims1 = [min(min(v)),max(max(v))];
%     pic_lim = [-diff(ylims1)/100,diff(ylims1)/100];
%     ylims1 = ylims1+pic_lim;
%     ylims1(2) = ylims1(2)+3*diff(ylims1);
%     ylim(ylims1)
    xlim([1,length(v)]+[-1,1]);
    
    if  ~isempty(lstr)
        legend(obj_L,lstr,'location','best');
    end
    ylabel('drawdown');
    ah=gca;
    ah.YColor=[0.5,0.5,0.5];
end

%subplot(1,2,1)
x = bsxfun(@rdivide,x*100,x(1,:));
if eq(sel,2)
    yyaxis left
end
obj_L = myplot(x);
if ~isempty(str)
    title(str)
end
%legend({'ref',strjoin(indicatorName0,'\r\n')},'location','best')
if ~eq(sel,2)&&~isempty(lstr)
    legend(obj_L,lstr,'location','best');
end
xlim([1,length(v)]+[-1,1]);
ylabel('bac curve');
set(gca,'linewidth',2);
ah=gca;
ah.YColor='r';

set(gca,'XTickLabelRotation',90);
set(gca,'XTick',floor(linspace(1,length(v),40)),'xlim',[1,length(v)]);
set(gca,'XTickLabel',t(floor(linspace(1,length(t),40))));
%datetick('x','yyyymmdd','keeplimits');
set(gca,'fontsize',12);

end

function obj_L=myplot(y)
    T = size(y,2);
    obj_L = zeros(T,1);
    %C = linspecer(T);
    hold on
    for i = 1:T
        obj_L(i) = plot(y(:,i),'r-','linewidth',2,'Marker','none');
    end

end

function obj_L=mybar(y,c_val)
%     T = size(y,2);
%     obj_L = zeros(T,1);
%     C = linspecer(T);
%     hold on
%     for i = 1:T
%         obj_L(i) = plot(x,y(:,i),'-','color',C(i,:),'linewidth',2,'Marker','none');
%     end
    obj_L = area(y,'FaceAlpha',0.5,'FaceColor',c_val,'EdgeColor','none');
end

function v = getdrawdown(x)
    v = zeros(size(x));
    for i = 1:size(x,2)
        v(:,i) = x(:,i)./cummax(x(:,i))-1;
    end
end