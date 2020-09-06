classdef bac_result_S52 <handle
    methods
        function get_all_results(obj)
            %update position
            obj.update_pos();
            %update chg
            obj.update_chg_p1();            
            obj.update_chg_p2();            
            %作图并给出结果
            [H1,re1] = obj.get_curve_p2();
            [H2,re2] = obj.get_curve_p1();
            
            key_str = 'S52 动态情景多因子和筹码分布Alpha';
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
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re) 
            
        end
    end
    methods(Static)        
        function update_pos()
            dos('python S52_bac_tool_P1.py');
            sprintf('开始更新S52P2股票池，月初更新需要10分钟左右')
            dos('python S52_bac_tool_P2_update.py');
            sprintf('完成更新S52P2股票池')
        end     
        
        function update_chg_p2()
            key_str = 'S52P2计算收益';
            %index_symbol = {'000905','000300'};
            symbol_pool =  '000985';
            m_pool = fetchmysql('select distinct(method_n) from S37.symbol_pool_S52P2',2);
            %re= cell(size(m_pool));
            key_str1 = 'P2';
            t0_ini = '2012-12-01';
            tN = 'S37.S52_return';
            var_info = {'method_info','tradingdate','r'};
            sql_t0 = 'select tradingdate from %s where method_info = "%s" order by tradingdate desc limit 1';

            chg_re = cell(size(m_pool));
            for i0 = 1:length(m_pool)
                m_id = m_pool{i0};
                sub_method = sprintf('%s-%s',key_str1,m_id);
                t0 = fetchmysql(sprintf(sql_t0,tN,sub_method),2);
                if isempty(t0)
                    t0 =t0_ini;
                    t02=t0;
                else
                    t0 = t0{1};
                    t02 = datenum(t0)-35;
                    if t02 >= datenum(t0_ini)
                        t02 = datestr(t02,'yyyy-mm-dd');
                    else
                        t02 = t0_ini;
                    end
                end

                sql_str = 'select distinct(publishDate) from S37.symbol_pool_S52P2 where method_n="%s" and publishDate>="%s" order by publishDate';
                p_t = fetchmysql(sprintf(sql_str,m_id,t02),2);
                %sql_tmp = 'select tradingdate from %s where method_info = "%s" order by tradingdate desc limit 1';
                fee = 2/1000;
                %间隔时间
                %p_t_id = datenum(p_t);

                tref = yq_methods.get_tradingdate(p_t{1},datestr(now,'yyyy-mm-dd'));
                tref_num = datenum(tref);
                if all(tref_num<=datenum(t0))
                    continue
                end
                T = length(p_t);
                sql_str = ['select symbol,tradeDate,chgPct from yuqerdata.yq_dayprice where symbol ',...
                    'in (%s) and tradeDate > "%s" and tradeDate<= "%s" order by tradeDate'];
                sql_str0 = 'select ticker,alpha from S37.symbol_pool_S52P2 where method_n = "%s" and publishDate = "%s"';
                r = cell(T,1);
                tref2 = cell(T,1);
                parfor i = 1:T
                    sub_t1 = p_t{i};
                    if i < T
                        sub_t2 = p_t{i+1};
                    else
                        sub_t2 = tref{end};
                    end

                    %sub_ind = strcmp(tref_pub,p_t(i));
                    sub_ticker =fetchmysql(sprintf(sql_str0,m_id,sub_t1),2);
                    %股票池限制
                    sub_ticker_limit = yq_methods.get_index_pool(symbol_pool,sub_t1);
                    [~,ia] = intersect(sub_ticker(:,1),sub_ticker_limit);
                    sub_ticker = sub_ticker(ia,:);
                    f = cell2mat(sub_ticker(:,2));
                    [~,ia]=sort(f,'descend');

                    sub_ticker1 = sub_ticker(ia(1:floor(length(sub_ticker)*0.2)),1);
                    sub_ticker2 = sub_ticker(ia(end-floor(length(sub_ticker)*0.2)+1:end),1);
                    sub_ticker = [sub_ticker1;sub_ticker2];

                    sub_info = sprintf('"%s"',strjoin(sub_ticker,'","'));    
                    sub_r = fetchmysql(sprintf(sql_str,sub_info,sub_t1,sub_t2),3);
                    if isempty(sub_r)
                        continue
                    end
                    sub_tref = unique(sub_r.tradeDate);
                    tref2{i} = sub_tref';
                    sub_r = unstack(sub_r,'chgPct','tradeDate');
                    sub_r = table2cell(sub_r)';
                    sub_symbol = sub_r(1,:);

                    [~,ia,ib] = intersect(sub_symbol,sub_ticker,'stable');
                    sub_r0 = cell(size(sub_r,1),length(sub_ticker));
                    sub_r0(:,ib) = sub_r(:,ia);

                    sub_r = cell2mat(sub_r0(2:end,:));
                    sub_r(isnan(sub_r)) = 0;
                    %拆分
                    ia = length(sub_ticker1);
                    sub_r1 = sub_r(:,1:ia);
                    sub_r2 = sub_r(:,ia+1:end);
                    sub_r1 = mean(sub_r1,2);
                    sub_r2 = mean(sub_r2,2);
                    sub_r_re = sub_r1-sub_r2;
                    sub_r_re(end) = sub_r_re(end)-fee;
                    %sub_r(end) = sub_r(1)-fee;
                    %sub_r(1) = -fee;
                    %sub_r_re = mean(sub_r,2);
                    r{i}=sub_r_re';
                    sprintf('%s %s %d-%d',key_str,m_id,i,T)
                end
                tref2 = [tref2{:}]';
                y = [r{:}]';
                sub_chg = [tref2,tref2,num2cell(y)];

                sub_chg(:,1) = {sub_method};
                ind = datenum(tref2)>datenum(t0);    
                chg_re{i0} = sub_chg(ind,:)';
            end

            chg_re_f = [chg_re{:}]';
            if ~isempty(chg_re_f)
                sprintf('%s 写入数据库',key_str)
                datainsert_adair(tN,var_info,chg_re_f)
            end
        end
        
        function [h,sta_re] = get_curve_p2()
            %key_str = 'S52P2计算收益';
            %index_symbol = {'000905','000300'};
            symbol_pool =  '000985';
            m_pool = fetchmysql('select distinct(method_n) from S37.symbol_pool_S52P2',2);            
            key_str1 = 'P2';
            tN = 'S37.S52_return';
            sql_r = 'select tradingdate,r from %s where method_info = "%s" order by tradingdate';
            for i = 1:length(m_pool)
                m_id = m_pool{i};
                sub_method = sprintf('%s-%s',key_str1,m_id);
                sub_r = fetchmysql(sprintf(sql_r,tN,sub_method),2);

                if eq(i,1)
                    chg_re = sub_r;
                else
                    [~,ia,ib] = intersect(chg_re(:,1),sub_r(:,1));
                    chg_re = cat(2,chg_re(ia,:),sub_r(ib,2:end));
                end
            end

            y_re = cell2mat(chg_re(:,2:end));
            y_re(1,:) = 0;
            y_re = cumprod(1+y_re);

            t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),chg_re(:,1),'UniformOutput',false);
            T = length(t_str);
            leg_str = cellfun(@(x) ['S52P2:', replace(x,'_','-')],m_pool,'UniformOutput',false);   
            h=figure;
            plot(y_re,'LineWidth',2);
            set(gca,'xlim',[0,T]);
            set(gca,'XTick',floor(linspace(1,T,15)));
            set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(gcf,[223,365,1345,420]);
            legend(leg_str,'Location','best')
            title(symbol_pool)
            box off
            sta_re = curve_static_batch(y_re,leg_str);
            
        end
        function [h,sta_re] = get_curve_p1()
            key_str = 'S52P1回测曲线';
            %symbol_pool = 'A';
            index_symbol = {'000906','000905'};
            m_pool = {'CYQ','Gain','Loss','CYQ_reform'};
            m_pool = m_pool(end);
            %re= cell(size(m_pool));
            tN_2 = 'S37.S52_return';
            key_str1 = 'P1';
            %%%%
            sql_str = ['select tradeDate,CloseIndex from yuqerdata.yq_index where symbol = "%s" ',...
                    'order by tradeDate'];
            for i = 1:length(index_symbol)
                temp = fetchmysql(sprintf(sql_str,index_symbol{i}),2);
                if i ==1
                    y_ref=temp;
                else
                    [~,ia,ib] = intersect(y_ref(:,1),temp(:,1));
                    y_ref = cat(2,y_ref(ia,:),temp(ib,2));
                end
            end

            sql_str_r = 'select tradingdate,r from %s where method_info = "%s" order by tradingdate';
            for i0 = 1:length(m_pool)
                m_id = m_pool{i0};
                sub_method = sprintf('%s-%s',key_str1,m_id);
                sub_r = fetchmysql(sprintf(sql_str_r,tN_2,sub_method),2);

                tref2 = sub_r(:,1);
                y=cell2mat(sub_r(:,2));

                [tref3,ia,ib] = intersect(tref2,y_ref(:,1));
                y_re = [cumprod(1+y(ia,:)),cell2mat(y_ref(ib,2:end))];
                y_re = bsxfun(@rdivide,y_re,y_re(1,:));
                t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),tref3,'UniformOutput',false);
                T = length(t_str);

                leg_str = ['策略曲线',index_symbol];
                h = figure;
                subplot(2,1,1)
                plot(y_re,'LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                %setpixelposition(gcf,[223,365,1345,420]);
                legend(leg_str,'Location','best')
                box off

                title(replace(sub_method,'_','-'))
                leg_str2 = cellfun(@(x) ['对冲',x],index_symbol,'UniformOutput',false);
                subplot(2,1,2)
                y_r = zeros(size(y_re));
                y_r(2:end,:) = y_re(2:end,:) ./ y_re(1:end-1,:)-1;
                y_r1 = - bsxfun(@minus,y_r,y_r(:,1));
                y_r1 = y_r1(:,2:end);
                y_re2 = cumprod(1+y_r1);
                plot(y_re2,'LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                %setpixelposition(gcf,[223,365,1345,420]);
                legend(leg_str2,'Location','best')
                box off
                setpixelposition(h,[455,305,1127,520]);
                sub_y_re = [y_re,y_re2];
                sta_re = curve_static_batch(sub_y_re,[leg_str,leg_str2]);
            end
            sprintf('%s 完成',key_str)
        end
        
        function update_chg_p1()
            key_str = 'S52P1更新收益';
            symbol_pool = 'A';
            m_pool = {'CYQ','Gain','Loss','CYQ_reform'};
            m_pool = m_pool(end);
            re= cell(size(m_pool));
            tN = 'symbol_pool_S52P1M';

            key_str1 = 'P1';
            t0_ini = '2007-01-31';
            tN_2 = 'S37.S52_return';
            var_info = {'method_info','tradingdate','r'};
            sql_t0 = 'select tradingdate from %s where method_info = "%s" order by tradingdate desc limit 1';

            chg_re = cell(size(m_pool));
            for i0 = 1:length(m_pool)
                m_id = m_pool{i0};    
                sub_method = sprintf('%s-%s',key_str1,m_id);
                t0 = fetchmysql(sprintf(sql_t0,tN_2,sub_method),2);
                if isempty(t0)
                    t0 =t0_ini;
                    t02=t0;
                else
                    t0 = t0{1};
                    t02 = datenum(t0)-35;
                    if t02 >= datenum(t0_ini)
                        t02 = datestr(t02,'yyyy-mm-dd');
                    else
                        t02 = t0_ini;
                    end
                end

                sql_str = 'select distinct(tradeDate) from S37.%s where tradeDate>="%s" order by tradeDate';
                p_t = fetchmysql(sprintf(sql_str,tN,t02),2);
                %sql_tmp = 'select tradingdate from %s where method_info = "%s" order by tradingdate desc limit 1';
                fee = 2/1000;
                %fee = 0;
                %间隔时间
                %p_t_id = datenum(p_t);
                tref = yq_methods.get_tradingdate(p_t{1});
                tref_num = datenum(tref);
                if all(tref_num<=datenum(t0))
                    continue
                end
                T = length(p_t);
                sql_str = ['select symbol,tradeDate,chgPct from yuqerdata.yq_dayprice where symbol ',...
                    'in (%s) and tradeDate > "%s" and tradeDate<= "%s" order by tradeDate'];
                sql_str0 = 'select ticker,%s from S37.%s where tradeDate = "%s"';
                r = cell(T,1);
                tref2 = cell(T,1);
                parfor i = 1:T
                    sub_t1 = p_t{i};
                    if i < T
                        sub_t2 = p_t{i+1};
                    else
                        sub_t2 = tref{end};
                    end

                    %sub_ind = strcmp(tref_pub,p_t(i));
                    sub_ticker =fetchmysql(sprintf(sql_str0,m_id,tN,sub_t1),2);
                    %股票池限制
                    if eq(length(symbol_pool),6)
                        sub_ticker_limit = yq_methods.get_index_pool(symbol_pool,sub_t1);
                    else
                        sub_ticker_limit = sub_ticker(:,1);
                    end
                    [~,ia] = intersect(sub_ticker(:,1),sub_ticker_limit);
                    sub_ticker = sub_ticker(ia,:);
                    %st pt delete
                    symbol_stpt = yq_methods.get_stpt_symbol(sub_t1);
                    [~,ia] = intersect(sub_ticker(:,1),symbol_stpt);
                    sub_ticker(ia,:) = [];
                    %上市限制
                    symbol_old = list_datelimit(sub_t1,250);
                    [~,ia] = intersect(sub_ticker(:,1),symbol_old);
                    sub_ticker = sub_ticker(ia,:);

                    f = cell2mat(sub_ticker(:,2));
                    [~,ia]=sort(f);

                    sub_ticker1 = sub_ticker(ia(1:floor(length(sub_ticker)*0.1)),1);
                    sub_ticker2 = sub_ticker(ia(end-floor(length(sub_ticker)*0.1)+1:end),1);
                    sub_ticker = [sub_ticker1;sub_ticker2];

                    sub_info = sprintf('"%s"',strjoin(sub_ticker,'","'));    
                    sub_r = fetchmysql(sprintf(sql_str,sub_info,sub_t1,sub_t2),3);
                    sub_tref = unique(sub_r.tradeDate);
                    tref2{i} = sub_tref';
                    sub_r = unstack(sub_r,'chgPct','tradeDate');
                    sub_r = table2cell(sub_r)';
                    sub_symbol = sub_r(1,:);

                    [~,ia,ib] = intersect(sub_symbol,sub_ticker,'stable');
                    sub_r0 = cell(size(sub_r,1),length(sub_ticker));
                    sub_r0(:,ib) = sub_r(:,ia);

                    sub_r = cell2mat(sub_r0(2:end,:));
                    sub_r(isnan(sub_r)) = 0;
                    %拆分
                    ia = length(sub_ticker1);
                    sub_r1 = sub_r(:,1:ia);
                    sub_r2 = sub_r(:,ia+1:end);
                    sub_r1 = mean(sub_r1,2);
                    sub_r2 = mean(sub_r2,2);
                    sub_r_re = sub_r1-0;
                    sub_r_re(end) = sub_r_re(end)-fee;
                    %sub_r(end) = sub_r(1)-fee;
                    %sub_r(1) = -fee;
                    %sub_r_re = mean(sub_r,2);
                    r{i}=sub_r_re';
                    sprintf('%d-%d',i,T)
                end
                tref2 = [tref2{:}]';
                y = [r{:}]';

                sub_chg = [tref2,tref2,num2cell(y)];    
                sub_chg(:,1) = {sub_method};
                ind = datenum(tref2)>datenum(t0);    
                chg_re{i0} = sub_chg(ind,:)';
            end

            chg_re_f = [chg_re{:}]';
            if ~isempty(chg_re_f)
                sprintf('%s 写入数据库',key_str)
                datainsert_adair(tN_2,var_info,chg_re_f)
            end

        end
    end
    
    
    
end