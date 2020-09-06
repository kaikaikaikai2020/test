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
            %��ȡƷ��
            sql_str_type = ['select secShortName,contractObject from %s where ',...
                'tradeDate = ''%s'' and mainCon=1'];
            future_type = fetchmysql(sprintf(sql_str_type,obj.tN_future,tt{1}),2);
            [~,ia] = unique(future_type(:,2));
            future_type = future_type(ia,:);
            obj.future_pool_all = future_type(:,2);
            obj.future_pool_info = future_type(:,1);
            
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
            key_str = 'S38 ����ʱƽ��';      
            T_symbol_pool_all = length(obj.symbol_pool_all);
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s-ָ��%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                end
                sta_re{index_sel} = sub_sta;
                %figure
                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'ָ��','�ۺ���ʱ'},'NumColumns',2,'location','best');
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
            key_str = 'S38 ����ʱƽ��';
            T_symbol_pool_all = length(obj.future_pool_all);
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s-�ڻ�%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                end
                sta_re{index_sel} = sub_sta;
                %figure
                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'ָ��','�ۺ���ʱ'},'NumColumns',2,'location','best');
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
            key_str = 'S38 ����ͻ����ʱ-ָ��';
            para_kurt = 4;%��β�ж���ֵ�������Ƽ�4
            T_symbol_pool_all = length(obj.symbol_pool_all);
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_0;
            sql_str_data = 'select tradeDate,openIndex,lowestIndex,highestIndex,closeIndex from yuqerdata.yq_index where symbol = ''%s'' order by tradeDate';  
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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

                T_tref = length(data(:,1));  % ����

                % ������Բ���
                K1 = 0.9;
                K2 = 0.9;
                N = 30;
                N_range = 2;
                % ������ϵ��
                % �ز⿪ʼ
                dataIndex = N + 1;  % �ز���ʼ����
                indicator1 = zeros(T_tref,1);
                while(dataIndex<=T_tref)
                    % �ж����뻹������  
                        % data���ݸ�ʽ��ÿһ�б�ʾһ��ʱ�䵥λ��һ�졢һСʱ�ȣ��ڵ�5��ֵ����open,low,high,close,volume
                    HH = max(data(dataIndex-N_range:dataIndex-1,3));
                    LC = min(data(dataIndex-N_range:dataIndex-1,4));
                    HC = max(data(dataIndex-N_range:dataIndex-1,4));
                    LL = min(data(dataIndex-N_range:dataIndex-1,2));
                    Range = max([HH-LC,HC-LL]);
                    half_Range = Range/2;
                    %BuyLine = data(dataIndex,1) + K1*unifrnd(1,2);  % ��������
                    %SellLine = data(dataIndex,1) - K2*unifrnd(1,2); % ��������
                    BuyLine = data(dataIndex,1) + K1*half_Range;
                    SellLine = data(dataIndex,1) - K2*half_Range;
                    price = data(dataIndex-N:dataIndex-1, 4);
                    percentage_change = diff(price)./price(1:end-1);    
                    kurt = kurtosis(percentage_change);

                    if eq(indicator1(dataIndex-1),0)
                        % û�в�λ
                        if( data(dataIndex,3)>BuyLine && kurt>para_kurt)
                            indicator1(dataIndex)=1;  % �����
                        elseif( data(dataIndex,2)<SellLine && kurt>para_kurt)
                            indicator1(dataIndex)=-1;  % ���ղ�
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
                %�ź��ӳ�һ��ִ��
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
                f_str = containers.Map([1,0,-1],{'����','ƽ��','����'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {'��ʱ�ź�',tref_next,f_str(indicator0(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {tref_next,f_str(indicator0(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'ָ��','����ͻ����ʱ'},'NumColumns',2,'location','best');
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
            key_str = 'S38 LLT˫����ʱ';            
            T_symbol_pool_all = length(obj.symbol_pool_all);
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                %�ź��ӳ�һ��
                %�ز���1
                %[y_bac_0,y_bac_f] = obj.simuTrail2(tref_num,indicator1,tref_num,closeprice,[],[]); 
                % [props,objH,recurve] = obj.efplot(tref_num,indicator1,y1,y2,[]);
                %�ز���2
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
                f_str = containers.Map([1,0,-1],{'����','ƽ��','����'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {'��ʱ�ź�',tref_next,f_str(y_dir2(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {tref_next,f_str(y_dir2(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'ָ��','LLT��ʱ'},'NumColumns',2,'location','best');
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
            key_str = 'S38 ����ͻ����ʱ-�ڻ�';
            para_kurt = 4;%��β�ж���ֵ�������Ƽ�4
            T_symbol_pool_all = length(obj.future_pool_all);
            Y_bac_0 = cell(T_symbol_pool_all,1);
            Y_bac_f = Y_bac_0;
            tref_all = Y_bac_f;
            sql_str_data = ['select ticker,tradeDate,openPrice,lowestPrice,highestPrice,closePrice from %s ',...
        'where contractObject = ''%s'' and closePrice is not null and mainCon=1 order by tradeDate'];   
            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                ticker_change = find(diff(ticker_code))+1; %��Լ��

                data = cell2mat(x(:,3:end));

                x = x(:,[2,6]);
                tref = x(:,1);
                closeprice = cell2mat(x(:,2));
                %��Լ����
                sub_r = zeros(size(closeprice));
                sub_r(2:end) = closeprice(2:end)./closeprice(1:end-1)-1;
                sub_r(ticker_change) = 0;
                sub_r(1) = 0;
                closeprice = cumprod(1+sub_r)*100;
                T_tref = length(data(:,1));  % ����
                % ������Բ���
                K1 = 0.9;
                K2 = 0.9;
                N = 30;
                N_range = 2;
                % ������ϵ��
                % �ز⿪ʼ
                dataIndex = N + 1;  % �ز���ʼ����
                indicator1 = zeros(T_tref,1);
                while(dataIndex<=T_tref)
                    % �ж����뻹������  
                        % data���ݸ�ʽ��ÿһ�б�ʾһ��ʱ�䵥λ��һ�졢һСʱ�ȣ��ڵ�5��ֵ����open,low,high,close,volume
                    HH = max(data(dataIndex-N_range:dataIndex-1,3));
                    LC = min(data(dataIndex-N_range:dataIndex-1,4));
                    HC = max(data(dataIndex-N_range:dataIndex-1,4));
                    LL = min(data(dataIndex-N_range:dataIndex-1,2));
                    Range = max([HH-LC,HC-LL]);
                    half_Range = Range/2;
                    %BuyLine = data(dataIndex,1) + K1*unifrnd(1,2);  % ��������
                    %SellLine = data(dataIndex,1) - K2*unifrnd(1,2); % ��������
                    BuyLine = data(dataIndex,1) + K1*half_Range;
                    SellLine = data(dataIndex,1) - K2*half_Range;
                    price = data(dataIndex-N:dataIndex-1, 4);
                    percentage_change = diff(price)./price(1:end-1);    
                    kurt = kurtosis(percentage_change);

                    if eq(indicator1(dataIndex-1),0)
                        % û�в�λ
                        if( data(dataIndex,3)>BuyLine && kurt>para_kurt)
                            indicator1(dataIndex)=1;  % �����
                        elseif( data(dataIndex,2)<SellLine && kurt>para_kurt)
                            indicator1(dataIndex)=-1;  % ���ղ�
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
                %�ź��ӳ�һ��ִ��
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
                f_str = containers.Map([1,0,-1],{'����','ƽ��','����'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {'��ʱ�ź�',tref_next,f_str(indicator0(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {tref_next,f_str(indicator0(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'ָ��','����ͻ����ʱ'},'NumColumns',2,'location','best');
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
            key_str = 'S38 LLT˫����ʱ-�ڻ�';   
            T_symbol_pool_all = length(obj.future_pool_all);
            sql_str_future = ['select ticker,tradeDate,closePrice from %s ',...
                    'where contractObject = ''%s'' and closePrice is not null and mainCon=1 order by tradeDate'];

            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                ticker_change = find(diff(ticker_code))+1; %��Լ��
                x = x(:,2:end);
                tref = x(:,1);
                y = cell2mat(x(:,2));
                r = zeros(size(y));
                r(2:end) = y(2:end)./y(1:end-1)-1;
                r(ticker_change) = 0; %��Լ�յĵ�һ��������
                closeprice =cumprod(1+r);
                indicator1 = [0;obj.llt_indicator(closeprice,30,20,1)];
                %�ź��ӳ�һ��
                %�ز���1
                %[y_bac_0,y_bac_f] = obj.simuTrail2(tref_num,indicator1,tref_num,closeprice,[],[]); 
                % [props,objH,recurve] = obj.efplot(tref_num,indicator1,y1,y2,[]);
                %�ز���2
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
                f_str = containers.Map([1,0,-1],{'����','ƽ��','����'});
                
                if eq(index_sel,1)
                    sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {'��ʱ�ź�',tref_next,f_str(y_dir2(end))};
                else
                    sub_sta = [[{sub_index_info};v0'],[{[sub_index_info,'-��ʱ']};v1']];
                    signal_info = {tref_next,f_str(y_dir2(end))};
                end
                sta_re{index_sel} = [sub_sta;signal_info];

                h = figure;
                plot([y_bac_0,y_bac_f],'LineWidth',2)
                set(gca,'xlim',[1,length(tref)]);
                set_x_tick(gca,tref)
                setpixelposition(gcf,[223,365,1345,420]);
                legend({'ָ��','LLT��ʱ'},'NumColumns',2,'location','best');
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
            key_str = 'S38 �߽׾�-�ڻ�'; 
            T_symbol_pool_all = length(obj.future_pool_all);
            sql_str_future = ['select ticker,tradeDate,closePrice from %s ',...
                    'where contractObject = ''%s'' and closePrice is not null and mainCon=1 order by tradeDate'];

            sta_re = cell(T_symbol_pool_all,1);
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                ticker_change = find(diff(ticker_code))+1; %��Լ��
                x = x(:,2:end);
                tref = x(:,1);
                y = cell2mat(x(:,2));
                r = zeros(size(y));
                r(2:end) = y(2:end)./y(1:end-1)-1;
                r(ticker_change) = 0; %��Լ�յĵ�һ��������
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
            file_name = sprintf('S38 �߽׾���ʱ-ָ��%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
                sprintf('ֻ��ѡ��ģʽ1����ģʽ2')
            end
        end
    end
    methods(Static)
        function [h,sta_re,y_bac_0,y_bac_f,sub_signal_update] = get_high_order_signal(tref,r,sub_index_info)
            %����
            wid_N = 20;
            wid_N2 = 90;
            cut_value = 0.1;%ֹ��
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
            %�źŵ��췢�����ڶ�������ִ�У�ע��diff�÷���
            signal_all = signal_all([1,1,1:end],:);
            signal_all(1:2) = 0;
            y = cumprod(1+r.*signal_all(1:end-1,:));
            %����nan�����ټ���
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
            %ֹ����
            T_sub_ind = length(r);
            r_cut_marker = 0;%�Ƿ񴥷�
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
                        %Ϊ�˷����ڶ����ź���ӱ��
                        if i <=T_sub_ind
                            %���¼���
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
                            %���¼���
                            r_cut_marker = 0;
                            r_cut = 1;
                            r_cut_dir = signal_f(i);
                        end
                        if 1-r_cut>cut_value
                            r_cut_marker = 1;
                        end
                    end
                    %ֻҪû�д�����ʱ����һ�գ���������ǰ�ź�
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
            f_str = containers.Map([1,0,-1],{'����','ƽ��','����'});

            sub_sta = [[{''};v_str0'],[{sub_index_info};v0'],[{[sub_index_info,'-�߽���ʱ']};v1']];
            signal_info = {'��ʱ�ź�',tref_next,f_str(sub_signal_update(end))};
            sta_re = [sub_sta;signal_info];

            h = figure;
            plot([y_bac_0,y_bac_f],'LineWidth',2)
            set(gca,'xlim',[1,length(r)]);
            set_x_tick(gca,tref)
            setpixelposition(gcf,[223,365,1345,420]);
            legend({'ָ��','�߽���ʱ'},'NumColumns',2,'location','best');
            title(sub_index_info)
        end
        %paras
        %1�źŴ���
        %2Ƶ��
        %3ʤ��-��������20�οղ��źţ�����18��ȷʵ����ˣ���ʤ�ʼ�Ϊ90%��
        %4����
        %5��˸����
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
                if y1(xEv(i,1))>y1(xEv(i,2))%�ɹ����
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
                legend([obj1;obj2],{'�ղ���','ָ��','���','���/ָ��'},'location','northwest')
            end
            sprintf('�����ղ��ź�%d�Σ�Ƶ��Ϊ%%%0.2f,ʤ��Ϊ%%%0.2f������Ϊ%%%0.2f����˸�ź�ռ��%%%0.2f',props)
        end
        %LLT(T)=(��-��^2/4)*PRICE(T)+(��^2/2)*PRICE(T-1)-(��-(3��^2)/4)*PRICE(T-2)+2(1-��)*LLT(T-1)-(1-��)^2*LLT(T-2)        
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
        %T������ִ�ж�� %ֻ����������
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
        %��������ָ��
        M0 = 1e10;
        %���й�Ʊ�����߳��н�Ǯ
        T = length(tref);
        cash = zeros(T,1);
        shares = zeros(T,1);%�ֳֹ���%����
        cash(1) = M0;%cash�ֽ����%����
        y = cash;
        state = 0;
        indicator(1) = 0;
        for i = 2:T
            if eq(indicator(i),0)%���ź�
                if  eq(state,0)%״̬Ϊ�ղ�
                    %keep��do nothing
                    cash(i) = cash(i-1);
                    shares(i) = shares(i-1);
                else%״̬Ϊ��
                    %��ת�� ���ձ���
                    M = cash(i-1)+shares(i-1)*closeV0(i);%�ܽ��
                    %���ձ�������
                    %cash
                    %M1 = M*p1;
                    %shares
                    M2 = M*(1-p1);%���ڹ���share�Ľ��
                    v1 = M2/closeV0(i)/(1+fee);%Ŀ�����
                    %v3 = 0;
                    if v1>shares(i-1)
                        %����
                        v2 = v1-shares(i-1);%�����
                        v3 = v2*closeV0(i)*(1+fee);%����
                        M1 = cash(i-1)-v3;%cashʣ��
                    elseif v1<shares(i-1)
                        %����
                        v2 = shares(i-1) - v1;
                        v3 = v2*closeV0(i)*(1-fee);%����ʱ�ܹ��õ���Ǯ
                        M1 = cash(i-1)+v3;
                    else
                        M1 = cash(i-1);
                    end
                    shares(i) = v1;            
                    cash(i) = M1;%������ʧ          
                end        
            else%ָʾ��һ��Ϊ��
                if  eq(state,0)%״̬Ϊ�ղ�
                    %��ת�� ���ձ���
                    M = cash(i-1)+shares(i-1)*closeV0(i);
                    %���ձ�������
                    %cash
                    %M1 = M*(1-p1);
                    %shares
                    %M2 = M*p1;
                    M2 = M;
                    v1 = M2/closeV0(i)/(1+fee);%Ŀ�����
                    %v3 = 0;
                    if v1>shares(i-1)
                        %����
                        v2 = v1-shares(i-1);
                        v3 = v2*closeV0(i)*(1+fee);%������Ҫ���
                        M1 = cash(i-1)-v3;
                    elseif v1<shares(i-1)
                        %����
                        v2 = shares(i-1) - v1;
                        v3 = v2*closeV0(i)*(1-fee);%�����õ����
                        M1 = cash(i-1)+v3;
                    else
                        M1 = cash(i-1);%����
                    end
                    shares(i) = v1;            
                    cash(i) = M1;%������ʧ 
                else%��
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