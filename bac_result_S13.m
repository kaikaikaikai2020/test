classdef bac_result_S13 <handle
    properties
        data_source = 'S13_data.xlsx';
    end
    methods
        function get_all_results(obj)
            file_name = sprintf('S13低开现象半仓策略表现%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            
            re2 = obj.get_ETF_results(obj_wd);
            re3 = obj.get_fushare_result(obj_wd);
            re4 = obj.get_indicator_result(obj_wd);
            re1 = obj.get_astock_result(obj_wd);
            obj_wd.CloseWord()
            re = [re2;re3;re4;re1];
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
        end
        
        
        function re = get_ETF_results(obj,obj_wd)
            keystr = 'ETFT0半仓策略验证';
            [~,~,info] = xlsread(obj.data_source,'sheet3');
            index_name_pool = cellfun(@(x,y) [x,y],info(:,2),info(:,3),'UniformOutput',false);
            index_code_pool = cellfun(@(x) x(1:6),info(:,1),'UniformOutput',false);
            T_index = length(index_code_pool);

            sql_str_f1 = ['select tradedate,openprice*accumAdjFactor,closeprice*accumAdjFactor from yuqerdata.MktFunddGet ',...
                'where ticker = ''%s'' and tradeDate>=''%s'' order by tradeDate'];
            re = cell(T_index,1);
            for index_sel = 1:T_index
                sub_index_name = index_name_pool{index_sel};
                sub_index_code = index_code_pool{index_sel};
                sub_t0 = '2000-01-01';
                index_data = fetchmysql(sprintf(sql_str_f1,sub_index_code,sub_t0),2);

                tref_str = index_data(:,1);
                tref = datenum(tref_str);
                o_c_price = cell2mat(index_data(:,2:3));
                open_price = o_c_price(:,1);
                close_price = o_c_price(:,2);
                
                g_jump_new = [0;close_price(2:end)./open_price(1:end-1)-1];
                g_jump_new(isinf(g_jump_new)) = 0;

                %leg_str = {'无手续费','手续费万三','手续费万五','手续费千一','基准'};
                %fee_all = [0,3,5,10]./10000;
                
                leg_str = {'无手续费','手续费万四'};
                fee_all = [0,4]./10000;
                
                V = zeros(length(tref),length(fee_all)+1);
                V(:,end) = close_price./close_price(1);
                for i = 1:length(fee_all)
                    V(:,i) = get_etf_half_r(g_jump_new,fee_all(i));
                end
                colors = [0.6392,0.0784,0.1804;0.93,0.69,0.13;ones(1,3)*0.65;ones(1,3)*0.5; 0.3020,0.7490,0.9294];
                sub_obj = zeros(size(fee_all));
                h = figure;
                for i = 1:length(sub_obj)
                    sub_obj(i) = plot(tref,V(:,i),'LineWidth',2,'color',colors(i,:));
                    if eq(i,1)
                        hold on
                    end
                end
                set(gca,'XTickLabelRotation',90);
                set(gca,'XTick',tref(floor(linspace(1,length(tref),20))),'xlim',tref([1,end]));
                datetick('x','yyyymmdd','keepticks');
                set(gca,'fontsize',12);
                box off
                set(gca,'linewidth',1.5);
                legend(sub_obj,leg_str,'Location','northwest',...
                    'NumColumns',length(sub_obj),'location','best')
                legend('boxoff')
                title(sub_index_name)
                setpixelposition(h,[223,365,1345,420]);
                obj_wd.pasteFigure(h,' ');
                %统计参数
                [v0,v_str0] = curve_static(V(:,2));
                [v,v_str] = ad_trans_sta_info(v0,v_str0); 
                temp = [[{sprintf('%s万3',keystr)};v_str'],[{sub_index_name};v']];
                if eq(index_sel,1)
                    re{index_sel} = temp;
                else
                    re{index_sel} = temp(:,2);
                end                
            end
            re = [re{:}]';
        end
        %
        function re = get_astock_result(obj,obj_wd)
            key_str = 'S13股票低开验证';
            [~,~,info] = xlsread(obj.data_source,'sheet1');
            symbol = info(:,1);
            %shortname = info(:,2);
            T_symbol = length(symbol);
            sql_str_f1 = ['select tradeDate,openprice,closeprice from yuqerdata.yq_dayprice',...
                ' where symbol=''%s'' order by tradeDate'];
            sql_str_f2 = ['select tradeDate,accumAdjFactor from yuqerdata.MktEqudAdjAfGet ',...
                'where ticker = ''%s'' order by tradeDate'];
            sql_str_f3 = 'select secShortName from yuqerdata.EquGet where ticker = ''%s'' limit 1';
            h=zeros(size(symbol));
            re2 = cell(size(symbol));
            re = cell(size(symbol));
            parfor astock_sel = 1:length(symbol)

                sub_info = symbol{astock_sel};
                sub_index_name = sprintf('S%sSE.%s',sub_info(end),sub_info(1:6));
                sub_info=strsplit(sub_info,'.');
                sub_info = sub_info{1};
                shortname = fetchmysql(sprintf(sql_str_f3,sub_info),2);

                sub_x1 = fetchmysql(sprintf(sql_str_f1,sub_info),2);
                sub_x2 = fetchmysql(sprintf(sql_str_f2,sub_info),2);
                [~,ia,ib] = intersect(sub_x1(:,1),sub_x2(:,1));

                sub_x1 = sub_x1(ia,:);
                sub_x2 = sub_x2(ib,:);
                sub_x3 = bsxfun(@times,cell2mat(sub_x1(:,2:end)),cell2mat(sub_x2(:,end)));
                index_data = [sub_x1(:,1),num2cell(sub_x3)];

                tref_str = index_data(:,1);
                tref = datenum(tref_str);
                o_c_price = cell2mat(index_data(:,2:3));
                open_price = o_c_price(:,1);
                close_price = o_c_price(:,2);
                %
                g_jump_new = [0;close_price(2:end)./open_price(1:end-1)-1];
                
                
                fee_all = [0,15]./10000;                
                %fee_all = [0,3,6,10]./10000;
                V = zeros(length(tref),length(fee_all)+1);
                V(:,end) = close_price./close_price(1);
                for i = 1:length(fee_all)
                    V(:,i) = get_half_r_astock(g_jump_new,fee_all(i));
                end
                
                re2{astock_sel} = {tref,V,sub_index_name};
                Y = V;
                [v0,v_str0] = curve_static(Y(:,end-1));
                [v,v_str] = ad_trans_sta_info(v0,v_str0); 
                temp = [[{sprintf('%s千一点五',key_str)};v_str'],[{sub_index_name};v']];
                if eq(astock_sel,1)
                    re{astock_sel} = temp;
                else
                    re{astock_sel} = temp(:,2);
                end
                sprintf('%s:%d-%d',key_str,astock_sel,T_symbol)
            end
            re = [re{:}]';
            for i = 1:length(symbol)
                %leg_str = {'无手续费','手续费万三','手续费万六','手续费千一','基准'};
                leg_str = {'无手续费','手续费万十五','基准'};
                temp = re2{i};
                tref = temp{1};
                V = temp{2};
                sub_index_name = temp{3};
                colors = [0.6392,0.0784,0.1804;0.93,0.69,0.13;ones(1,3)*0.65;ones(1,3)*0.5; 0.3020,0.7490,0.9294];
                sub_obj = zeros(size(leg_str));
                h1 = figure;
                for j = 1:length(sub_obj)
                    sub_obj(j) = plot(V(:,j),'LineWidth',2,'color',colors(j,:));
                    if eq(j,1)
                        hold on
                    end
                end
                setpixelposition(h1,[223,365,1345,420]);
            
                set(gca,'XTickLabelRotation',90);
                set(gca,'XTick',floor(linspace(1,length(tref),40)),'xlim',[1,length(tref)]);
                set(gca,'XTickLabel',cellstr(datestr(tref(floor(linspace(1,length(tref),40))),'yyyymmdd')));
                set(gca,'fontsize',12);            
                box off
                set(gca,'linewidth',1.5);
                legend(sub_obj,leg_str,'Location','northwest',...
                    'NumColumns',length(sub_obj),'location','best')
                legend('boxoff')
                title(sub_index_name)
                obj_wd.pasteFigure(h1,' ');
            end
            %sta_re = [sta_re{:}]';
            %gui_result(sta_re,'S13A股低开半仓策略收益统计',title_str)
            %sta_re1 = [title_str;sta_re];
        end
        %
        
        %
        
    end
    methods(Static)
        function re = get_fushare_result(obj_wd)
            %股指数据
            key_str = '股指期货高开T0验证';
            index_name_pool = {'沪深300股指期货','上证50股指期货','中证500股指期货'};
            index_code = {'IF','IH','IC'};    
            T_index = length(index_name_pool);
            re = cell(T_index,1);
            for index_sel = 1:T_index

                sub_index_name = index_name_pool{index_sel};
                t0 = cell(size(index_name_pool));
                t0{1} = '2014-05-01';

                sql_str_f1 = ['select tradeDate,ticker,openprice,closeprice from yuqerdata.yq_MktMFutdGet  ',...
                    'where contractObject = ''%s''  and mainCon=1 and tradeDate>=''%s'' order by tradedate'];

                sql_str_f2 = ['select tradeDate,ticker,openprice,closeprice from yuqerdata.yq_MktMFutdGet  ',...
                    'where contractObject = ''%s''  and mainCon=1 order by tradedate'];

                if isempty(t0{index_sel})
                    x = fetchmysql(sprintf(sql_str_f2,index_code{index_sel}),2);
                else
                    x = fetchmysql(sprintf(sql_str_f1,index_code{index_sel},t0{index_sel}),2);
                end

                index_contracts_num = cellfun(@(x) str2double(x(length(index_code{index_sel})+1:end)),x(:,2));
                index_contracts_num = [0;diff(index_contracts_num)];
                index_contracts_num = ~eq(index_contracts_num,0);
                index_data= x(:,[1,3,4]);


                tref_str = index_data(:,1);
                tref = datenum(tref_str);
                o_c_price = cell2mat(index_data(:,2:3));
                open_price = o_c_price(:,1);
                close_price = o_c_price(:,2);
                %g_cum; g_jump g_inner %累计收益，跳价收益，日内收益
                %几何收益率
                g_cum = [0;log(close_price(2:end)./close_price(1:end-1))];
                g_jump = [0;log(open_price(2:end)./close_price(1:end-1))];

                g_cum(index_contracts_num) = 0;
                g_jump(index_contracts_num) = 0;


                fee = [1.5/10000,3/10000];
                g1 = g_jump;
                g1(~index_contracts_num) = g1(~index_contracts_num)-fee(1)*2;
                g2 = g_jump;
                g2(~index_contracts_num) = g2(~index_contracts_num)-fee(2)*2;
                colors = [0.64,0.78,0.18;0.93,0.69,0.13;ones(1,3)*0.65];
                g_info = {'无手续费','手续费万一点五','手续费万三','基准'};
                h1=figure;
                sub_obj = plot(tref,1+cumsum([g_jump,g1,g2,g_cum]),'-','linewidth',2);
                sub_obj(1).Color = 'r';
                sub_obj(end).Color = colors(3,:);

                set(gca,'XTickLabelRotation',90);
                set(gca,'XTick',tref(floor(linspace(1,length(tref),40))),'xlim',tref([1,end]));
                datetick('x','yyyymmdd','keepticks');
                set(gca,'fontsize',12);
                box off
                set(gca,'linewidth',1.5);
                legend(sub_obj,g_info,'Location','northwest',...
                    'NumColumns',length(sub_obj),'location','northwest')
                legend('boxoff')
                title(sub_index_name)
                setpixelposition(h1,[223,365,1345,420]);
                obj_wd.pasteFigure(h1,' ');   
                
                V = 1+cumsum(g2);
                [v0,v_str0] = curve_static(V);
                [v,v_str] = ad_trans_sta_info(v0,v_str0); 
                temp = [[{sprintf('%s万三几何收益',key_str)};v_str'],[{sub_index_name};v']];
                if eq(index_sel,1)
                    re{index_sel} = temp;
                else
                    re{index_sel} = temp(:,2);
                end
                             
            end
            re = [re{:}]';
        end
        %
        function re = get_indicator_result(obj_wd)
            key_str = '指数低开T0策略验证';
            index_name_pool = {'沪深300','上证指数','上证50','中证500','深证成指',...
                '创业板指','中小板指','中证1000',...
                    '深次新股','中证流通'};
            T_index = length(index_name_pool);
            re = cell(T_index,1);
            for index_sel = 1:T_index    
                sub_index_name = index_name_pool{index_sel};
                %指数数据
                t0 = '2005-01-01';
                [index_data,~] = get_index_data_yuqer(sub_index_name,t0);
                tref_str = index_data(:,1);
                tref = datenum(tref_str);
                o_c_price = cell2mat(index_data(:,2:3));
                open_price = o_c_price(:,1);
                close_price = o_c_price(:,2);
                
                g_jump_new = [0;close_price(2:end)./open_price(1:end-1)-1];
                g_jump_new(isnan(g_jump_new)) = 0;

                leg_str = {'无手续费','手续费万三','手续费万五','基准'};
                fee_all = [0,3,5]./10000;
                V = zeros(length(tref),4);
                V(:,end) = close_price./close_price(1);
                for i = 1:length(fee_all)
                    V(:,i) = get_half_r_indicator(g_jump_new,fee_all(i));
                end
                h1=figure;
                colors = [0.6392,0.0784,0.1804;0.93,0.69,0.13;ones(1,3)*0.65;ones(1,3)*0.5];
                sub_obj = zeros(4,1);
                for i = 1:length(sub_obj)
                    sub_obj(i) = plot(tref,V(:,i),'LineWidth',2,'color',colors(i,:));
                    if eq(i,1)
                        hold on
                    end
                end
                set(gca,'XTickLabelRotation',45);
                set(gca,'XTick',tref(floor(linspace(1,length(tref),20))),'xlim',tref([1,end]));
                datetick('x','yyyymmdd','keepticks');
                set(gca,'fontsize',12);

                box off
                set(gca,'linewidth',1.5);
                legend(sub_obj,leg_str,'Location','northwest',...
                    'NumColumns',length(sub_obj),'location','best')
                legend('boxoff')
                title(sub_index_name)
                setpixelposition(h1,[223,365,1345,420]);
                obj_wd.pasteFigure(h1,' '); 
                
                
                [v0,v_str0] = curve_static(V(:,2));
                [v,v_str] = ad_trans_sta_info(v0,v_str0); 
                temp = [[{sprintf('%s万三几何收益',key_str)};v_str'],[{sub_index_name};v']];
                if eq(index_sel,1)
                    re{index_sel} = temp;
                else
                    re{index_sel} = temp(:,2);
                end
                
            end
            re = [re{:}]';
        end
    end
end

function c_new = get_etf_half_r(g_jump_new,fee)
if nargin < 2
    fee = 0;
end
g_r_1 = zeros(size(g_jump_new)); %相当于间隔一天的两个半仓策略
g_r_2 = g_r_1;
g_r_1(2:2:end) = g_jump_new(2:2:end);
g_r_1 = g_r_1 - fee;
g_r_2(3:2:end) = g_jump_new(3:2:end);
g_r_2(2:end) = g_r_2(2:end)-fee;

c_new = cumprod(1+g_r_1)*0.5+cumprod(1+g_r_2)*0.5;

end

function c_new = get_half_r_astock(g_jump_new,fee)
    if nargin < 2
        fee = 0;
    end
    g_r_1 = zeros(size(g_jump_new)); %相当于间隔一天的两个半仓策略
    g_r_2 = g_r_1;
    g_r_1(2:2:end) = g_jump_new(2:2:end);
    g_r_1 = g_r_1 - fee;
    g_r_2(3:2:end) = g_jump_new(3:2:end);
    g_r_2(2:end) = g_r_2(2:end)-fee;

    c_new = cumprod(1+g_r_1)*0.5+cumprod(1+g_r_2)*0.5;
    %c_new = cumprod(1+g_r_1*0.5)+cumprod(1+g_r_2*0.5);
end

function[v,v_str] = cal_para_math(y,N)
% y = cumprod(1+rand(1000,1)/1000);
%(AC3277/100)^(244/COUNT(AC120:AC3277))-1
%1年化收益率
v_str{1} = '年化收益率';
v(1) = (y(end)/y(1))^(365/N)-1;
end

function c_new = get_half_r_indicator(g_jump_new,fee)
if nargin < 2
    fee = 0;
end
g_r_1 = zeros(size(g_jump_new)); %相当于间隔一天的两个半仓策略
g_r_2 = g_r_1;
g_r_1(2:2:end) = g_jump_new(2:2:end);
g_r_1 = g_r_1 - fee;
g_r_2(3:2:end) = g_jump_new(3:2:end);
g_r_2(2:end) = g_r_2(2:end)-fee;

c_new = cumprod(1+g_r_1)*0.5+cumprod(1+g_r_2)*0.5;

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