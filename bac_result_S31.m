classdef bac_result_S31 < handle
    methods 
        function get_all_results(obj)
            
            file_name = sprintf('S31Easy择时%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));  
            re = [];
            re1 = obj.get_etf_signal_S31(obj_wd)
            re = cat(1,re,obj.get_etf_signal_S31(obj_wd));
            re = cat(1,re,obj.get_future_signal(obj_wd));
            re = cat(1,re,obj.get_com_signal(obj_wd));
            obj_wd.CloseWord()  
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
            
        end
    end
    methods(Static)
        function re = get_etf_signal_S31(obj_wd)
            key_str = 'S31ETF双因子择时';
            signal_type = 'P1_5';
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});

            window_p1 = 38;
            print_sel = false;

            sql_str1 = ['select (closeprice-iopv)/iopv,volume from ',...
                'S31.adj_data where date(tradingdate) = ''%s'' and symbol = ''%s'' order by tradingdate'];

            tN = 'S31.adj_data';
            code_pool = {'510050','510300','510500'};
            code_name_pool = {'etf50_min','etf300_min','etf500_min'};
            %var_info = {'symbol','tradingdate','iopv','openprice','closeprice','volume'};
            %tref = fetchmysql('select distinct(tradingdate) from S31.adj_data where tradingdate>=''2017-01-13'' order by tradingdate desc',2);
            tref = yq_methods.get_tradingdate('2017-01-13',datestr(now,'yyyy-mm-dd'));
            tref_f = yq_methods.get_tradingdate_future(tref{end});
            tref_f = [tref;tref_f(2)];
            T_tref = length(tref);
            sql_str_a1 =[ 'select tradingdate,f_val from S31.S31_signal where signal_type=''%s'' ',...
                'and symbol =''%s'' order by tradingdate'];
            re = cell(3,1);
            for code_id = 1:3
                code_sel = code_pool{code_id};
                %sub_t = zeros(245,1);
                %y = nan(245,T_tref);
                signal_val = zeros(T_tref+1,1);
                x0 = fetchmysql(sprintf(sql_str_a1,signal_type,code_sel),2);
                if isempty(x0)
                    t0 = datenum(1990,1,1);
                    num0 = 1;
                else
                    t0 = datenum(x0(end,1));
                    num0 = find(eq(datenum(tref_f),t0));
                    signal_val(1:num0) = cell2mat(x0(:,2));
                end

                for i = num0:T_tref

                    sub_x = fetchmysql(sprintf(sql_str1,tref{i},code_sel));

                    sub_x_open = mean(sub_x(:,1));
                    sub_x_close = mean(sub_x(end-window_p1+1:end,1));

                    sub_x1 = sub_x(1:end-1,:);
                    sub_x2 = sub_x(2:end,:);

                    sub_v1 = sum(sub_x2(sub_x2(:,1)>sub_x1(:,1),2));
                    sub_v2 = sum(sub_x2(sub_x2(:,1)<sub_x1(:,1),2));

                    if sub_v1>sub_v2 && sub_x_close>sub_x_open
                        signal_val(i+1) = 1;
                    else
                        signal_val(i+1) = 0;
                    end
                    if print_sel
                        sprintf('%d-%d',i,T_tref)
                    end
                end
                %backtest
                sql_str = 'select tradedate,openprice*accumAdjFactor from yuqerdata.MktFunddGet where ticker = ''%s'' order by tradedate';
                r = fetchmysql(sprintf(sql_str,code_sel),2);
                temp_r_v = cell2mat(r(:,2:end));
                r = [r(2:end,1),num2cell(temp_r_v(2:end,1)./temp_r_v(1:end-1,1)-1)];
                sub_info = signal_str(signal_val(end));
                y_r = bac_testS31_etf(tref,signal_val,r);
                y_c =cumprod(1+y_r);

                h=figure;
                plot(y_c,'LineWidth',3)
                t_str = tref;
                T=length(t_str);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));

                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                legend(code_name_pool{code_id},'Location','best');
                box off
                title_str = sprintf('%s-%s:%s',tref{end},code_name_pool{code_id},sub_info);
                title(title_str)
                
                setpixelposition(gcf,[223,365,1345,420]);
                obj_wd.pasteFigure(h,title_str);
                
                sub_re = [];
                [v,v_str] = curve_static(y_c');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(code_id,1)
                    sub_re =cat(2,sub_re,[[{key_str};v_str1'],[code_name_pool{code_id};v1']]);
                else
                    sub_re = cat(2,sub_re,[code_name_pool{code_id};v1']);
                end
                
                re{code_id} = sub_re;
            end   
            re = [re{:}]';
        end
        function re = get_future_signal(obj_wd)
            key_str = '股指期货三因子择时';
            signal_type = 'P2_5';

            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            window_p1 = 28;
            %window_p1 = 50;
            %window_p1 = 10;
            print_sel = true;

            sql_str1 = ['select (closeprice-iopv)/iopv,volume from ',...
                'S31.adj_data where date(tradingdate) = ''%s'' and symbol = ''%s'' order by tradingdate'];

            code_pool = {'510050','510300','510500'};
            code_name_pool = {'etf50_min','etf300_min','etf500_min'};
            code_indicator = {'IH','IF','IC'};

            sql_str_a1 =[ 'select tradingdate,f_val from S31.S31_signal where signal_type=''%s'' ',...
                'and symbol =''%s'' order by tradingdate'];
            re = cell(size(code_indicator));
            for code_id = 1:3
                tref = yq_methods.get_tradingdate('2017-01-13',datestr(now,'yyyy-mm-dd'));
                tref_f = yq_methods.get_tradingdate_future(tref{end});
                tref_f = [tref;tref_f(2)];
                T_tref = length(tref);
                code_sel = code_pool{code_id};
                code_indicator_sel = code_indicator{code_id};
                %sub_t = zeros(245,1);
                %y = nan(245,T_tref);
                signal_val = zeros(T_tref+1,1);

                x0 = fetchmysql(sprintf(sql_str_a1,signal_type,code_indicator_sel),2);
                if isempty(x0)
                    t0 = datenum(1990,1,1);
                    num0 = 1;
                else
                    t0 = datenum(x0(end,1));
                    num0 = find(eq(datenum(tref_f),t0));
                    signal_val(1:num0) = cell2mat(x0(:,2));
                end

                sql_str_check =[ 'select ticker from yuqerdata.yq_MktMFutdGet ',...
                    'where contractObject = ''%s'' and mainCon=1 and tradedate>=''%s'' and tradedate<=''%s'' ',...
                    'order by tradedate';];
                sql_str_check2 =[ 'select tradedate,ticker from yuqerdata.yq_MktMFutdGet ',...
                    'where contractObject = ''%s'' and mainCon=1 order by tradedate';];
                tickers = fetchmysql(sprintf(sql_str_check2,code_indicator_sel),2);       

                parfor i = num0:T_tref
                    %第二天是不是股指切换日期
                    %sub_ticker = fetchmysql(sprintf(sql_str_check,code_indicator_sel,tref{i+1},tref{i+2}),2);
                    sub_id = find(strcmp(tickers(:,1),tref(i)));
                    sub_ticker = tickers(sub_id-1:sub_id,2);
                    if ~strcmp(sub_ticker(1),sub_ticker(2))
                        signal_val(i+1) = 0;
                        continue
                    end
                    sub_x = fetchmysql(sprintf(sql_str1,tref{i},code_sel));

                    sub_x_open1 = mean(sub_x(:,1));
                    sub_x_open2 = mean(sub_x(1:window_p1,1));
                    sub_x_close = mean(sub_x(end-window_p1+1:end,1));

                    sub_x1 = sub_x(1:end-1,:);
                    sub_x2 = sub_x(2:end,:);

                    sub_v1 = sum(sub_x2(sub_x2(:,1)>sub_x1(:,1),2));
                    sub_v2 = sum(sub_x2(sub_x2(:,1)<sub_x1(:,1),2));

                    if sub_v1>sub_v2 && sub_x_close>max(sub_x_open1,sub_x_open2)
                        signal_val(i+1) = 1;
                    elseif sub_v1<sub_v2 && sub_x_close<min(sub_x_open1,sub_x_open2)
                        signal_val(i+1) = -1;
                    else
                        signal_val(i+1) = 0;
                    end
                    if print_sel
                        sprintf('%d-%d',i,T_tref)
                    end
                end
                %signal_val = -signal_val;
                %backtest
                sub_info = signal_str(signal_val(end));
                sql_str = 'select tradedate,openprice from yuqerdata.yq_MktMFutdGet where contractObject = ''%s'' and mainCon=1 order by tradedate';
                r = fetchmysql(sprintf(sql_str,code_indicator_sel),2);
                r_v = cell2mat(r(:,2));
                r = [r(2:end,1),num2cell(r_v(2:end)./r_v(1:end-1)-1)];

                y_r = bac_testS31_indexfuture(tref,signal_val,r);

                y_c = cumprod(1+y_r);
                h = figure;
                plot(y_c,'LineWidth',3)
                t_str = tref;
                T=length(t_str);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                legend(code_indicator_sel,'Location','best');
                box off
                title_str = sprintf('%s-%s:%s',tref{end},code_indicator_sel,sub_info);
                title(title_str)
                setpixelposition(gcf,[223,365,1345,420]);
                obj_wd.pasteFigure(h,title_str);
                
                sub_re = [];
                [v,v_str] = curve_static(y_c');
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(code_id,1)
                    sub_re =cat(2,sub_re,[[{key_str};v_str1'],[code_indicator_sel;v1']]);
                else
                    sub_re = cat(2,sub_re,[code_indicator_sel;v1']);
                end                
                re{code_id} = sub_re;
            end   
            re = [re{:}]';
        end
        function re = get_com_signal(obj_wd)
            key_str = 'S31easy择时三方信号综合回测结果';
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            p1 = 0.01;p2 = 1.1;
            window_p1 = 28;
            %window_p1 = 50;
            %window_p1 = 10;
            print_sel = false;

            sql_str1 = ['select (closeprice-iopv)/iopv,volume from ',...
                'S31.adj_data where date(tradingdate) = ''%s'' and symbol = ''%s'' order by tradingdate'];

            tN = 'S31.adj_data';
            symbol = {'000016','399300','000905'};
            symbol_info = {'上证50','沪深300','中正500'};
            code_pool = {'510050','510300','510500'};
            code_name_pool = {'etf50_min','etf300_min','etf500_min'};
            code_indicator = {'IH','IF','IC'};

            %code_id = 3;
            re_sta = [];
            y_c = cell(3,1);
            re = cell(size(code_pool));

            for code_id = 1:3
                tref = yq_methods.get_tradingdate('2014-01-13',datestr(now,'yyyy-mm-dd'));
                tref_f = yq_methods.get_tradingdate_future(tref{end});
                tref_f = [tref;tref_f(2)];
                signal_final = zeros(length(tref_f),3);

                tref_num = datenum(tref_f);
                tref_week = weekday(tref_num);
                code_sel = code_pool{code_id};
                code_indicator_sel = code_indicator{code_id};
                symbol_sel = symbol{code_id};

                [tref1,signal_val1,tref_f1] = get_signal1_update(code_id);
                [~,ia,ib] = intersect(tref_f,tref_f1);
                signal_final(ia,1) = signal_val1(ib);
                %signal 2
                sql_str = ['select tradedate,closeIndex/openIndex-1,turnoverVol,chgpct from yuqerdata.yq_index where ',...
                    'symbol = ''%s'' and tradedate>=''2014-01-13''   order by tradedate '];
                x = fetchmysql(sprintf(sql_str,symbol{code_id}),2);
                tref_f2 = yq_methods.get_tradingdate_future(x{1,end});
                tref_f2 = [x(:,1);tref_f2(2)];
                %temp = cell2mat(x(:,2));
                %x = [x(2:end,1),num2cell(temp(2:end)./temp(1:end-1)-1),x(2:end,3)];    
                y = cell2mat(x(:,2:end));
                vol_chg = [0;y(2:end,2)./y(1:end-1,2)];
                y(:,2) = vol_chg;

                ind = find(y(:,1)>=p1 & y(:,2)>=p2);
                ind(ind>=size(y,1)) = [];
                ind = ind + 1;
                signal_val2 = zeros(size(x(:,1)));
                signal_val2(ind) = 1;

                ind = find(y(:,1)>=p1 & y(:,2)>=p2);
                ind = ind + 1;
                sub_signal_val2 = zeros(size(x,1)+1,1);
                sub_signal_val2(ind) = 1;
                [~,ia,ib] = intersect(tref_f,tref_f2);
                signal_final(ia,2) = sub_signal_val2(ib);

                %signal 3
                signal_val3 = zeros(size(x,1)+1,1);
                signal_val3(eq(tref_week,2)) = 1;
                signal_val3(eq(tref_week,5)) = -1;
                [~,ia,ib] = intersect(tref_f,tref_f2);
                signal_final(ia,3) = signal_val3(ib);

                signal_val3 = signal_val3(1:end-1);
                temp = [signal_val2,signal_val3];

                temp1 = zeros(size(temp(:,1)));
                [~,ia,ib] = intersect(tref,tref1);
                temp1(ia) = signal_val1(ib);
                temp = [temp,temp1];

                signal_val = zeros(size(signal_val2));
                % signal_val(sum(abs(temp),2)>1 & sum(temp,2)>0) = 1;
                % signal_val(sum(abs(temp),2)>1 & sum(temp,2)<0) = -1;

                %signal_val = signal_val3;
                signal_val(sum(temp,2)>0) = 1;
                signal_val(sum(temp,2)<0) = -1;

                signal_valf = zeros(size(signal_final));
                signal_valf(sum(signal_final,2)>0) = 1;
                signal_valf(sum(signal_final,2)<0) = -1;
                sub_info = signal_str(signal_valf(end));
                %backtest
                %sql_str = 'select tradedate,openprice from yuqerdata.MktMFutdGet where contractObject = ''%s'' and mainCon=1 order by tradedate';
                %r = fetchmysql(sprintf(sql_str,code_indicator_sel),2);

                sql_str = 'select tradedate,closeIndex/openIndex-1 from yuqerdata.yq_index where symbol = ''%s'' order by tradedate';
                r = fetchmysql(sprintf(sql_str,symbol_sel),2);
                [~,ia,ib] = intersect(tref,r(:,1));

                temp = [signal_val(ia),cell2mat(r(ib,2))];
                temp = temp(:,1).*temp(:,2);
                y = zeros(size(temp));
                y(temp>0) = 1;
                y(temp<0) = -1;
                y_c{code_id} = cumprod(1+temp);

                temp = [signal_val2(ia),cell2mat(r(ib,2))];
                temp = temp(:,1).*temp(:,2);
                y2 = zeros(size(temp));
                y2(temp>0) = 1;
                y2(temp<0) = -1;

                temp = [signal_val3(ia),cell2mat(r(ib,2))];
                temp = temp(:,1).*temp(:,2);
                y3 = zeros(size(temp));
                y3(temp>0) = 1;
                y3(temp<0) = -1;

                [v1,v_str] = curve_static(y_c{code_id});
                %v2 = curve_static(y2,12);
                %v3 = curve_static(y3,12);
                re_sta = [re_sta;v1];
                h = figure;
                plot(y_c{code_id},'LineWidth',2);
                t_str = tref;
                T=length(t_str);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));

                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                %title(symbol_info{code_id});
                title_str = sprintf('%s-%s:%s',tref_f{end},symbol_info{code_id},sub_info);
                title(title_str)
                %setpixelposition(gcf,[223,365,1345,420]);
                box off
                setpixelposition(gcf,[223,365,1345,420]);
                obj_wd.pasteFigure(h,title_str);
                
                sub_re = [];
                [v,v_str] = curve_static(y_c{code_id});
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(code_id,1)
                    sub_re =cat(2,sub_re,[[{key_str};v_str1'],[symbol_info{code_id};v1']]);
                else
                    sub_re = cat(2,sub_re,[symbol_info{code_id};v1']);
                end                
                re{code_id} = sub_re;
            end   
            re = [re{:}]';
        end
    end
end


%股指期货回测框架
%tref signal_val 时间和信号
%r每日的开盘收益率
function y_r = bac_testS31_etf(tref,signal_val,r,fee)
    if nargin < 4
        fee = 0;
    end
    T_tref = length(tref);
    y_r = zeros(size(T_tref));
    for i = 2:T_tref
        sub_r = cell2mat(r(strcmp(r(:,1),tref(i)),2));
        if eq(signal_val(i),0)
            if eq(signal_val(i-1),1) %清仓
                y_r(i) = sub_r-fee;
            else
                y_r(i) = 0;
            end
        else
            if eq(signal_val(i-1),0) %建仓
                y_r(i) = 0-fee;
            else
                y_r(i) = sub_r;
            end
        end

    end

end

%股指期货回测框架
%tref signal_val 时间和信号
%r每日的开盘收益率
function y_r = bac_testS31_indexfuture(tref,signal_val,r,fee)
    if nargin < 4
        fee = 0;
    end
    T_tref = length(tref);
    y_r = zeros(T_tref,1);
    for i = 2:T_tref
        sub_r = cell2mat(r(strcmp(r(:,1),tref(i)),2));
        if eq(signal_val(i),-1)
            if ~eq(signal_val(i-1),-1) %做空,开始
                y_r(i) = sub_r*signal_val(i-1)-fee;
            else
                y_r(i) = sub_r*signal_val(i); %继续做空
            end
        elseif eq(signal_val(i),1)
            if ~eq(signal_val(i-1),1) %做多，开始建仓
                y_r(i) = sub_r*signal_val(i-1)-fee;
            else
                y_r(i) = sub_r*signal_val(i); %继续做多
            end
        else
            if ~eq(signal_val(i-1),0)
                y_r(i) = sub_r*signal_val(i-1)-fee;
            else
                y_r(i) = 0;
            end
        end

    end

end
%对接入数据库
function [tref,signal_val,tref_f] = get_signal1_update(code_id)
window_p1 = 28;
%window_p1 = 50;
%window_p1 = 10;
print_sel = false;

sql_str1 = ['select (closeprice-iopv)/iopv,volume from ',...
    'S31.adj_data where date(tradingdate) = ''%s'' and symbol = ''%s'' order by tradingdate'];

tN = 'S31.adj_data';
code_pool = {'510050','510300','510500'};
code_name_pool = {'etf50_min','etf300_min','etf500_min'};
code_indicator = {'IH','IF','IC'};


tref = yq_methods.get_tradingdate('2017-01-13',datestr(now,'yyyy-mm-dd'));
tref_f = yq_methods.get_tradingdate_future(tref{end});
tref_f = [tref;tref_f(2)];
T_tref = length(tref);
code_sel = code_pool{code_id};
code_indicator_sel = code_indicator{code_id};
%sub_t = zeros(245,1);
%y = nan(245,T_tref);
signal_val = zeros(T_tref+1,1);
tn = 'S31.S31_signal';
var_info = {'signal_type','symbol','tradingdate','f_val'};
signal_type = 'Pcom3';
sql_str_a1 =[ 'select tradingdate,f_val from S31.S31_signal where signal_type=''%s'' ',...
    'and symbol =''%s'' order by tradingdate'];
x0 = fetchmysql(sprintf(sql_str_a1,signal_type,code_indicator_sel),2);
if isempty(x0)
    t0 = datenum(1990,1,1);
    num0 = 1;
else
    t0 = datenum(x0(end,1));
    num0 = find(eq(datenum(tref_f),t0));
    signal_val(1:num0) = cell2mat(x0(:,2));
end


sql_str_check =[ 'select ticker from yuqerdata.yq_MktMFutdGet ',...
    'where contractObject = ''%s'' and mainCon=1 and tradedate>=''%s'' and tradedate<=''%s'' ',...
    'order by tradedate';];
sql_str_check2 =[ 'select tradedate,ticker from yuqerdata.yq_MktMFutdGet ',...
    'where contractObject = ''%s'' and mainCon=1 order by tradedate';];
tickers = fetchmysql(sprintf(sql_str_check2,code_indicator_sel),2);

parfor i = num0:T_tref
    %第二天是不是股指切换日期
    %sub_ticker = fetchmysql(sprintf(sql_str_check,code_indicator_sel,tref{i+1},tref{i+2}),2);
    sub_id = find(strcmp(tickers(:,1),tref(i)));
    sub_ticker = tickers(sub_id-1:sub_id,2);
    if ~strcmp(sub_ticker(1),sub_ticker(2))
        signal_val(i+1) = 0;
        continue
    end

    sub_x = fetchmysql(sprintf(sql_str1,tref{i},code_sel));

    sub_x_open1 = mean(sub_x(:,1));
    sub_x_open2 = mean(sub_x(1:window_p1,1));
    sub_x_close = mean(sub_x(end-window_p1+1:end,1));

    sub_x1 = sub_x(1:end-1,:);
    sub_x2 = sub_x(2:end,:);

    sub_v1 = sum(sub_x2(sub_x2(:,1)>sub_x1(:,1),2));
    sub_v2 = sum(sub_x2(sub_x2(:,1)<sub_x1(:,1),2));

    if sub_v1>sub_v2 && sub_x_close>max(sub_x_open1,sub_x_open2)
        signal_val(i+1) = 1;
    elseif sub_v1<sub_v2 && sub_x_close<min(sub_x_open1,sub_x_open2)
        signal_val(i+1) = -1;
    else
        signal_val(i+1) = 0;
    end
    if print_sel
        sprintf('%d-%d',i,T_tref)
    end
end

end