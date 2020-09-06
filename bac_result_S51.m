classdef bac_result_S51 < handle
    
    methods
        function get_all_results(obj)
            %升级股票池
            obj.update_signal_p1();
            obj.update_signal_p2();
            obj.update_signal_p3();
            %升级曲线
            obj.bac_S51();
            %计算结果并输出
            [H1,re1] = obj.bac_figure1_3();
            [H2,re2] = obj.bac_figure3_update();
            
            key_str = 'S51 基金重仓股独门股等策略';
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            H = [H1;H2];
            for i = 1:length(H)
                obj_wd.pasteFigure(H(i),' ');
            end
            obj_wd.CloseWord();
            re = [re1;re2];
            yc = re(:,1);
            yc = [yc{:}];
            yt = re(:,2);
            yt = [yt{:}];
            sta_re = obj.curve_static_batch(yc,yt);
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re) 
        end
    end
    
    methods(Static)
        function update_signal_p1()
            dos('python S51_ON_p1_update2.py')
        end
        function update_signal_p2()
            %para
            tN = 'S37.S51_hold_info_p1';
            tn_var_info = {'ticker','reportDate','publishDate','method_info'};
            dn_str = 'S51P2';
            key_str = 'S51P2独门股策略';

            sql_tmp = 'select publishDate from %s where method_info = "%s" order by publishDate desc limit 1';
            t0 = fetchmysql(sprintf(sql_tmp,tN,dn_str),2);
            if ~isempty(t0)
                t0 = t0{1};
            else
                t0 = '2010-01-01';
            end

            tref = yq_methods.get_tradingdate('2010-01-01');
            tref_num = datenum(tref);
            t1 = year(tref_num(1)):year(now);
            t2 = {'03-31','06-30','09-30','12-31'};
            report_date_pool = cell(size(t1));
            for i = 1:length(t1)
                temp = cellfun(@(x) sprintf('%d-%s',t1(i),x),t2,'UniformOutput',false);
                report_date_pool{i} = temp;    
            end
            report_date_pool= [report_date_pool{:}]';
            report_date_pool_num = datenum(report_date_pool);
            publish_date = cell(size(report_date_pool));
            num_cut1 = 16-1;
            for i = 1:length(publish_date)
                if any(eq(month(report_date_pool_num(i)),[3,9]))
                    id = find(tref_num>report_date_pool_num(i),num_cut1);
                    if length(id)==num_cut1
                        publish_date{i} = datestr(tref_num(id(end)),'yyyy-mm-dd');
                    else
                        publish_date{i} = '2099-01-01';
                    end
                elseif eq(month(report_date_pool_num(i)),6)
                    publish_date{i} = datestr(report_date_pool_num(i)+60,'yyyy-mm-dd');
                else
                    publish_date{i} = datestr(report_date_pool_num(i)+90,'yyyy-mm-dd');
                end    
            end

            publish_date_num = datenum(publish_date);
            ind = publish_date_num<=tref_num(end) & publish_date_num>datenum(t0);
            if all(~ind)
                sprintf('%s 股票池已经为最新%s',key_str,t0)
                return
            end
            publish_date = publish_date(ind);
            %publish_date_num = publish_date_num(ind);
            report_date_pool = report_date_pool(ind);
            %report_date_pool_num = report_date_pool_num(ind);

            %股票型和混合型
            var_info = {'secID', 'secShortName', 'category', 'establishDate', ...
                           'expireDate', 'isClass', 'isFof', 'isQdii', ...
                           'indexFund', 'managementFullName'};
            sql_str1 = ['select %s from yuqerdata.FundGet_S51 where category in (%s) and operationMode="O"',...
                ' and secID is not null and establishDate is not null'];
            sql_str1 = sprintf(sql_str1,strjoin(var_info,','),'"E","H"');
            symbol_fund = fetchmysql(sql_str1,3);
            symbol_fund = symbol_fund(eq(symbol_fund.isClass,0) & eq(symbol_fund.isFof,0) ...
                & eq(symbol_fund.isQdii,0) & ~strcmpi(symbol_fund.indexFund,'I') ...
                & ~strcmpi(symbol_fund.indexFund,'EI'),:);

            ind1 = cellfun(@(x) any(contains({'-A','-B','-C'},x(end-1:end))),symbol_fund.secShortName);
            symbol_fund.secShortName2 = symbol_fund.secShortName;
            symbol_fund.secShortName2(ind1) = cellfun(@(x) x(1:end-2),symbol_fund.secShortName2(ind1),'UniformOutput',false);

            [~,ia] = unique(symbol_fund(:,{'category','establishDate','managementFullName','secShortName2'}));
            symbol_fund = symbol_fund(ia,{'secID', 'secShortName', 'category', 'establishDate', 'expireDate',...
                   'managementFullName'});

            %不同时间段的偏股
            T_report_date = length(report_date_pool);
            X = cell(T_report_date,1);
            for t_id = 1:T_report_date
                reportDate= report_date_pool{t_id};
                %偏股
                %select secID from yq_FundAssetsGet_S51 where equityRatioInTa >= 70 and reportDate = '2020-03-31'
                sql_secID_lim = 'select secID from yuqerdata.yq_FundAssetsGet_S51 where equityRatioInTa >= 50 and reportDate = "%s"';
                secID_lim = fetchmysql(sprintf(sql_secID_lim,reportDate),2);
                secID_sub = intersect(secID_lim,symbol_fund.secID);
                %池子
                %select * from yuqerdata.FundHoldingsGet_S51 where ticker = '470028' and
                sql_ticker_hold = ['select secID,holdingTicker,ratioInNa from yuqerdata.FundHoldingsGet_S51 where',...
                                ' reportDate = "%s" and holdingsecType="E" and holdingExchangeCd in ("XSHE","XSHG") '];
                ticker_hold = fetchmysql(sprintf(sql_ticker_hold,reportDate),3);
                %reportDate = '2020-03-31' 池子
                %筛选
                %写入数据库
                %回测
                %找到独门股
                T = length(secID_sub);
                sub_X = cell(T,1);
                parfor i = 1:T
                    sub_ind = strcmp(ticker_hold.secID,secID_sub(i));
                    sub_ticker_hold = ticker_hold(sub_ind,:);
                    ticker_inner = sub_ticker_hold.holdingTicker;
                    ticker_outer = unique(ticker_hold.holdingTicker(~sub_ind));
                    [~,ia] = setdiff(ticker_inner,ticker_outer);
                    if ~isempty(ia)
                        sub_X(i) = {table2cell(sub_ticker_hold(ia,:))'};
                    end    
                    sprintf('%s %d-%d',reportDate,i,T)    
                end
                sub_X = [sub_X{:}]';
                sub_X = sub_X(:,[1,1,1:end]);
                sub_X(:,1) = report_date_pool(t_id);
                sub_X(:,2) = publish_date(t_id);
                X{t_id} = sub_X';
            end
            ticker = [X{:}]';
            re = ticker(:,[4,1,2,2]);
            re(:,end) = {dn_str};
            ind = cell2mat(ticker(:,end))>1;
            re = re(ind,:);
            datainsert_adair(tN,tn_var_info,re)
            sprintf('%s 股票池更新至%s',key_str,report_date_pool{end})
        end
        function update_signal_p3()
            tN = 'S37.S51_hold_info_p1';
            tn_var_info = {'ticker','reportDate','publishDate','method_info'};
            dn_str = 'S51P3';
            key_str = 'S51P2独门股策略';

            sql_tmp = 'select publishDate from %s where method_info = "%s" order by publishDate desc limit 1';
            t0 = fetchmysql(sprintf(sql_tmp,tN,dn_str),2);
            if ~isempty(t0)
                t0 = t0{1};
            else
                t0 = '2010-01-01';
            end

            tref = yq_methods.get_tradingdate('2010-01-01');
            tref_num = datenum(tref);
            t1 = 2010:2020;
            t2 = {'03-31','06-30','09-30','12-31'};
            report_date_pool = cell(size(t1));
            for i = 1:length(t1)
                temp = cellfun(@(x) sprintf('%d-%s',t1(i),x),t2,'UniformOutput',false);
                report_date_pool{i} = temp;    
            end
            report_date_pool= [report_date_pool{:}]';
            report_date_pool_num = datenum(report_date_pool);
            publish_date = cell(size(report_date_pool));
            num_cut1 = 16;
            for i = 1:length(publish_date)
                if any(eq(month(report_date_pool_num(i)),[3,9]))
                    id = find(tref_num>report_date_pool_num(i),num_cut1);
                    if length(id)==num_cut1
                        publish_date{i} = datestr(tref_num(id(end)),'yyyy-mm-dd');
                    else
                        publish_date{i} = '2099-01-01';
                    end
                elseif eq(month(report_date_pool_num(i)),6)
                    publish_date{i} = datestr(report_date_pool_num(i)+60,'yyyy-mm-dd');
                else
                    publish_date{i} = datestr(report_date_pool_num(i)+90,'yyyy-mm-dd');
                end    
            end

            publish_date_num = datenum(publish_date);
            ind = publish_date_num<=tref_num(end) & publish_date_num>datenum(t0);
            if all(~ind)
                sprintf('%s 股票池已经为最新%s',key_str,t0)
                return
            end
            publish_date = publish_date(ind);
            %publish_date_num = publish_date_num(ind);
            report_date_pool = report_date_pool(ind);
            report_date_pool_num = report_date_pool_num(ind);

            %股票型和混合型
            var_info = {'secID', 'secShortName', 'category', 'establishDate', ...
                           'expireDate', 'isClass', 'isFof', 'isQdii', ...
                           'indexFund', 'managementFullName'};
            sql_str1 = ['select %s from yuqerdata.FundGet_S51 where category in (%s) and operationMode="O"',...
                ' and secID is not null and establishDate is not null'];
            sql_str1 = sprintf(sql_str1,strjoin(var_info,','),'"E","H"');
            symbol_fund = fetchmysql(sql_str1,3);
            symbol_fund = symbol_fund(eq(symbol_fund.isClass,0) & eq(symbol_fund.isFof,0) ...
                & eq(symbol_fund.isQdii,0) & ~strcmpi(symbol_fund.indexFund,'I') ...
                & ~strcmpi(symbol_fund.indexFund,'EI'),:);

            ind1 = cellfun(@(x) any(contains({'-A','-B','-C'},x(end-1:end))),symbol_fund.secShortName);
            symbol_fund.secShortName2 = symbol_fund.secShortName;
            symbol_fund.secShortName2(ind1) = cellfun(@(x) x(1:end-2),symbol_fund.secShortName2(ind1),'UniformOutput',false);

            [~,ia] = unique(symbol_fund(:,{'category','establishDate','managementFullName','secShortName2'}));
            symbol_fund = symbol_fund(ia,{'secID', 'secShortName', 'category', 'establishDate', 'expireDate',...
                   'managementFullName'});

            %不同时间段的偏股
            T_report_date = length(report_date_pool);
            X = cell(T_report_date,1);
            parfor t_id = 1:T_report_date
                reportDate= report_date_pool{t_id};
                %偏股
                %select secID from yq_FundAssetsGet_S51 where equityRatioInTa >= 70 and reportDate = '2020-03-31'
                sql_secID_lim = 'select secID from yuqerdata.yq_FundAssetsGet_S51 where equityRatioInTa >= 50 and reportDate = "%s"';
                secID_lim = fetchmysql(sprintf(sql_secID_lim,reportDate),2);
                secID_sub = intersect(secID_lim,symbol_fund.secID);
                %池子
                %select * from yuqerdata.FundHoldingsGet_S51 where ticker = '470028' and
                sql_ticker_hold = ['select secID,holdingTicker,ratioInNa,marketValue from yuqerdata.FundHoldingsGet_S51 where',...
                                ' reportDate = "%s" and holdingsecType="E" and holdingExchangeCd in ("XSHE","XSHG") '];
                ticker_hold = fetchmysql(sprintf(sql_ticker_hold,reportDate),2);
                %reportDate = '2020-03-31' 池子
                %筛选
                %写入数据库
                %回测
                %找到重仓股
                sub_t = tref{find(tref_num<report_date_pool_num(t_id),1,'last')};
                sql_temp = 'select symbol,negMarketValue from yuqerdata.yq_dayprice where tradeDate = "%s"';
                ticker_mv = fetchmysql(sprintf(sql_temp,sub_t),2);

                [sub_ticker,~,ic1] = unique(ticker_hold(:,2));
                [~,ia,ib] = intersect(sub_ticker,ticker_mv(:,1));
                sub_mv = zeros(size(sub_ticker));
                sub_mv(ia) = cell2mat(ticker_mv(ib,2));

                sub_mv2 = sub_mv(ic1);
                r =  cell2mat(ticker_hold(:,end))./sub_mv2;
                r(isinf(r)) = 0;
                %合并
                r1 = zeros(size(sub_ticker));
                for i = 1:length(r1)
                    sub_ind = strcmp(ticker_hold(:,2),sub_ticker(i));
                    r1(i) = sum(r(sub_ind));
                end

                sub_X = [sub_ticker,num2cell(r1)];
                %sub_X = unique(ticker_hold(r>0.05,2));

                sub_X = sub_X(:,[1,1,1,1:end]);
                sub_X(:,1) = report_date_pool(t_id);
                sub_X(:,2) = publish_date(t_id);
                X{t_id} = sub_X';
                sprintf('%d-%d',t_id,T_report_date)
            end
            ticker = [X{:}]';
            re = ticker(:,[4,1,2,2]);
            re(:,end) = {dn_str};
            ind = cell2mat(ticker(:,end))*100>=20;
            re = re(ind,:);
            datainsert_adair(tN,tn_var_info,re)
            sprintf('%s 股票池更新至%s',key_str,report_date_pool{end})
        end
        function bac_S51()
            method_info = containers.Map({'S51P1','S51P2','S51P3'},...
                    {'优秀基金经理的超额收益','独门看好策略','重仓股策略'});
            tN = 'S37.S51_return';
            var_info = {'method_info','tradingdate','r','r300','r500','dr300','dr500'};

            index_symbol = {'000905','000300'};
            for m_num = 1:3
                m_id = method_info.keys;
                m_id = m_id{m_num};
                sql_str = 'select ticker,publishDate from S37.S51_hold_info_p1 where method_info="%s" order by publishDate';
                x = fetchmysql(sprintf(sql_str,m_id),2);
                tref_pub = x(:,2);
                ticker_pool = x(:,1);

                sql_tmp = 'select tradingdate from %s where method_info = "%s" order by tradingdate desc limit 1';
                t0 = fetchmysql(sprintf(sql_tmp,tN,m_id),2);
                fee = 2/1000;
                %ticker_pool =
                %间隔时间
                p_t = unique(tref_pub);
                p_t_id = datenum(p_t);

                if isempty(t0)
                    num0 = 1;
                    t0_num = 0;
                    t0 = p_t{1};
                else
                    t0_num = datenum(t0);
                    num0 = find(p_t_id<=datenum(t0),2,'last');
                    num0 = num0(1);
                    t0 = t0{1};
                end

                p_t = p_t(num0:end);
                p_t_id = p_t(num0:end);

                tref = yq_methods.get_tradingdate(t0);
                tref = tref(2:end);
                if isempty(tref)
                    sprintf('%s 回测数据已经更新至%s，无需更新',method_info(m_id),t0)
                    continue    
                end
                tref_num = datenum(tref);
                T = length(p_t);
                sql_str = ['select symbol,tradeDate,chgPct from yuqerdata.yq_dayprice where symbol ',...
                    'in (%s) and tradeDate > "%s" and tradeDate<= "%s" order by tradeDate'];
                r = cell(T,1);
                tref2 = cell(T,1);
                for i = 1:T
                    sub_t1 = p_t{i};
                    if i < T
                        sub_t2 = p_t{i+1};
                    else
                        sub_t2 = tref{end};
                    end

                    sub_ind = strcmp(tref_pub,p_t(i));
                    sub_ticker = ticker_pool(sub_ind);

                    sub_info = sprintf('"%s"',strjoin(sub_ticker,'","'));

                    sub_r = fetchmysql(sprintf(sql_str,sub_info,sub_t1,sub_t2),3);
                    sub_tref = unique(sub_r.tradeDate);
                    tref2{i} = sub_tref';
                    sub_r = unstack(sub_r,'chgPct','tradeDate');
                    sub_r = table2cell(sub_r)';
                    sub_symbol = sub_r(1,:);

                    [sub_symbol,ia,ib] = intersect(sub_symbol,sub_ticker,'stable');
                    sub_r = sub_r(:,ia);

                    sub_r = cell2mat(sub_r(2:end,:));
                    sub_r(isnan(sub_r)) = 0;
                    %判断是否要手续费
                    if any(strcmp(p_t,sub_t2))
                        sub_r(end) = sub_r(end)-fee;
                    end

                    sub_r_re = mean(sub_r,2);
                    r{i}=sub_r_re';
                    sprintf('%d-%d',i,T)
                end
                tref2 = [tref2{:}]';
                y = [r{:}]';
                sql_str = ['select tradeDate,CloseIndex from yuqerdata.yq_index where symbol = "%s" ',...
                    'and tradeDate>="%s" and tradeDate<="%s"'];
                for i = 1:length(index_symbol)
                    temp = fetchmysql(sprintf(sql_str,index_symbol{i},tref2{1},tref2{end}),2);
                    if i ==1
                        y_ref=temp;
                    else
                        [~,ia,ib] = intersect(y_ref(:,1),temp(:,1));
                        y_ref = cat(2,y_ref(ia,:),temp(ib,2));
                    end
                end
                [tref3,ia,ib] = intersect(tref2,y_ref(:,1));
                y_re = [cumprod(1+y(ia,:)),cell2mat(y_ref(ib,2:end))];
                y_re = bsxfun(@rdivide,y_re,y_re(1,:));
                y_r = zeros(size(y_re));
                y_r(2:end,:) = y_re(2:end,:) ./ y_re(1:end-1,:)-1;
                y_r1 = - bsxfun(@minus,y_r,y_r(:,1));
                y_r1 = y_r1(:,2:end);

                re = [tref3,tref3,num2cell([y_r,y_r1])];
                re(:,1) = {m_id};

                id = datenum(tref3)>datenum(t0);
                re = re(id,:);
                if ~isempty(re)
                    datainsert_adair(tN,var_info,re);
                end
                sprintf('%s 回测数据已经更新至%s',method_info(m_id),tref3{end})
            end
        end
        
        function [H,re] = bac_figure1_3()
            method_info = containers.Map({'S51P1','S51P2','S51P3'},...
                {'优秀基金经理的超额收益','独门看好策略','重仓股策略'});
            tN = 'S37.S51_return';
            var_info = {'method_info','tradingdate','r','r300','r500','dr300','dr500'};
            index_symbol = {'000905','000300'};
            sql_str1 = 'select * from %s where method_info = "%s" order by tradingdate';
            H=zeros(3,1);
            re = cell(3,2);
            for m_num = 1:3
                m_id = method_info.keys;
                m_id = m_id{m_num};
                x = fetchmysql(sprintf(sql_str1,tN,m_id),2);
                tref = x(:,2);
                y_r = cell2mat(x(:,3:5));
                y_r1 = cell2mat(x(:,6:7));

                y_re=cumprod(1+y_r);
                t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),tref,'UniformOutput',false);
                T = length(t_str);
                %cut_v = [0,1,3,5];
                leg_str = ['策略曲线',index_symbol];

                H(m_num) = figure;
                subplot(2,1,1)
                plot(y_re,'LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                setpixelposition(gcf,[223,365,1345,420]);
                legend(leg_str,'Location','best')
                box off
                title(method_info(m_id))

                leg_str2 = cellfun(@(x) ['对冲',x],index_symbol,'UniformOutput',false);
                subplot(2,1,2);
                y_re2 = cumprod(1+y_r1);
                plot(y_re2,'LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                setpixelposition(gcf,[223,365,1345,600]);
                legend(leg_str2,'Location','best')    
                box off

                y_com = [y_re(:,1),y_re2];
                t_com = ['曲线',leg_str2];
                t_com = cellfun(@(x) [m_id,x],t_com,'UniformOutput',false);
                re(m_num,:) = {{y_com(:,1),y_com(:,2),y_com(:,3)},t_com};
            end
        end
        
        function [H,re] = bac_figure3_update()
            sql_tmp = 'select * from S37.S51_return where method_info = "S51P3" order by tradingdate';
            y_re = fetchmysql(sql_tmp,2);
            r_s = cell2mat(y_re(:,3));
            tref_s = y_re(:,2);
            tref_s_num = datenum(tref_s);
            p_t = fetchmysql('select distinct(publishDate) from S37.S51_hold_info_p1 where method_info = "S51P3" order by publishDate',2);
            p_t_id = datenum(p_t);

            sql_str = ['select tradeDate,CloseIndex from yuqerdata.yq_index where symbol = "000300" ',...
                'and tradeDate>="%s" order by tradeDate'];
            y_ref = fetchmysql(sprintf(sql_str,'2001-01-01'),2);
            tref_ref = y_ref(:,1);
            tref_ref_num = datenum(tref_ref);
            r_ref = cell2mat(y_ref(:,2));
            r_ref(2:end) = r_ref(2:end)./r_ref(1:end-1)-1;
            r_ref(1) = 0;

            %
            T  = length(p_t);
            wid = 20;
            x = cell(T,1);
            for i = 1:T
                sub_wid = find(tref_ref_num<=p_t_id(i),20,'last');
                sub_r = r_ref(sub_wid);
                sub_r = cumprod(1+sub_r)-1;
                sub_r = sub_r(end);
                if i <T
                    sub_wid2 = tref_s_num>p_t_id(i)&tref_s_num<=p_t_id(i+1);
                else
                    sub_wid2 = tref_s_num>p_t_id(i);
                end
                if sub_r<0.10       
                    sub_re = [tref_s(sub_wid2),num2cell(r_s(sub_wid2))];
                else
                    sub_wid2 = find(sub_wid2);
                    if length(sub_wid2)<=wid
                        sub_re = [tref_s(sub_wid2),num2cell(r_s(sub_wid2))];
                    else
                        sub_wid2_0 = sub_wid2(1:wid);
                        sub_re_0 = [tref_s(sub_wid2_0),num2cell(r_s(sub_wid2_0))];
                        sub_wid2_1 = sub_wid2(wid+1:end);
                        sub_t = tref_s_num(sub_wid2_1);
                        sub_wid2_3 = tref_ref_num>=min(sub_t) & tref_ref_num<=max(sub_t);
                        sub_re_1 = [tref_ref(sub_wid2_3),num2cell(r_ref(sub_wid2_3))];
                        sub_re = [sub_re_0;sub_re_1];
                    end
                end
                x{i} = sub_re';   
            end
            y=[x{:}]';

            %y_ref2=[y_re(:,[2,end]),cumprod(1+cell2mat(y(:,2)))];
            %plot(y_ref2,'LineWidth',2)
            y_r = cell2mat([y_re(:,3:4),y(:,end)]);
            y_r(1,:) = 0;
            y_ref2 = cumprod(1+y_r);
            t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),y(:,1),'UniformOutput',false);
            T = length(t_str);
            %cut_v = [0,1,3,5];
            leg_str = {'重仓股方法-p3','300指数','重仓股方法择时'};
            H = zeros(2,1);
            H(1) = figure;
            plot(y_ref2,'LineWidth',2);
            set(gca,'xlim',[0,T]);
            set(gca,'XTick',floor(linspace(1,T,15)));
            set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(gcf,[223,365,1345,420]);
            legend(leg_str,'Location','best')
            box off

            H(2) = figure;
            temp = [y_r(:,1)-y_r(:,2),y_r(:,3)-y_r(:,2)];
            %temp = temp(:,[1,3]);
            y_re2 = cumprod(1+temp);
            plot(y_re2,'LineWidth',2);
            set(gca,'xlim',[0,T]);
            set(gca,'XTick',floor(linspace(1,T,15)));
            set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(gcf,[223,365,1345,420]);
            legend({'p3','p3择时'},'Location','best')
            box off
            y_com = {y_ref2(:,3),y_re2(:,2)};
            t_com = {'重仓股方法择时','重仓股方法择时-对冲300'};
            re = {y_com,t_com};
        end
        
        function sta_re = curve_static_batch(yc,title_str)
            if ~iscell(yc)
                temp = cell(size(yc(1,:)));
                for i = 1:size(yc,2)
                    temp{i} = yc(:,i);
                end
                yc = temp;
            end
            sta_re = cell(size(yc));
            for i = 1:length(sta_re)
                [v0,v_str0] = curve_static(yc{i},[]);
                [v,v_str] = ad_trans_sta_info(v0,v_str0);
                if eq(i,1)
                    sub_re = [[{''};v_str'],[title_str(i);v']];
                else
                    sub_re = [title_str(i);v'];
                end
                sta_re{i} = sub_re;
            end
            sta_re = [sta_re{:}]';
        end
    end
    
end