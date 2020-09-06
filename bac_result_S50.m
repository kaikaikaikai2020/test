classdef bac_result_S50 < handle
    methods
        function get_all_results(obj)
            %
            obj.createtable_S50()
            %数据
            %如果是其它商品期货，合成指数部分只要扩展下，将其余标的引入就可以了
            obj.com_future_index();
            obj.com_us_future_index_update();
            %基差信号1需要标的数据
            h1 = obj.validation_JC();
            %收益
            [h2,yp_c_all] = obj.validation_BAC();
            
            key_str = 'S50股指期货基差择时';
            file_name = sprintf('%s%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            obj_wd.pasteFigure(h1,'S50多维度择时下累积基差收益');
            obj_wd.pasteFigure(h2,'基差择时对冲收益率');   
            obj_wd.CloseWord();
            %curve_static_batch
            sta_re = obj.curve_static_batch(yp_c_all{1},yp_c_all{2});
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re)            
        end
        %回测结果
        function [h,yp_c_all]=validation_BAC(obj)
            key_str = 'S50 验证';
            dN = 'S50';
            tn = 'index_com';
            tN_f = sprintf('%s.%s',dN,tn);            
            sprintf('%s',key_str)
            
            ticker_p = {'IF','IC','IH','ES','NQ'};
            ticker_targ_p = {'000300','000905','000016','SPX2','NDX2'};
            T_ticker_p = length(ticker_p);
            sql_str1 = 'select tradeDate,index_a,index_future from %s where ticker = "%s" order by tradeDate';
            
            yp_c_all = cell(T_ticker_p,1);
            for ticker_sel = 1:T_ticker_p
                ticker= ticker_p{ticker_sel};
                ticker_targ = ticker_targ_p{ticker_sel};
                index_com = fetchmysql(sprintf(sql_str1,tN_f,ticker),2);
                %index_com

                tref = index_com(:,1);                
                tref_month = yq_methods.get_month_data();
                [~,month_num] = intersect(tref,tref_month); 
                index_com = index_com(month_num,:);
                tref = index_com(:,1);

                y = cell2mat(index_com(:,2:end));
                y_future = y(:,2);
                y = [y(:,1),y(:,1)-y(:,2)];

                y_delta = y(:,2);
                y_index = y(:,1);

                window_num = 6;
                signal1 = obj.S50_signal1(y_index);
                signal2 = obj.S50_signal2(y_delta,window_num);
                signal3 = obj.S50_signal3(y_delta);

                signal = signal1+signal2+signal3;

                %y_c = [0;diff(y_delta)];
                %yp_c = signal.*y_c;
                %yp = yp_c>0;
                %yp = yp(window_num+1:end);
                %sprintf('%s : 预测正确次数%d\n预测错误次数%d',ticker,sum(yp),sum(yp==0))

                tref = tref(window_num:end);

                y_index_r = zeros(size(y_index));
                y_index_r(2:end) = y_index(2:end)./y_index(1:end-1)-1;

                y_future_r = zeros(size(y_delta));
                y_future_r(2:end) = y_future(2:end)./y_future(1:end-1)-1;

                %y_index = y_index(window_num:end);
                %y_delta = y_delta(window_num:end);
                %y_future = y_future(window_num:end);

                y_index_r = y_index_r(window_num:end);
                y_future_r = y_future_r(window_num:end);

                signal = signal(window_num:end);
                signal(1) = -1;

                signal = signal>0;
                %ind_fee = (~eq(diff(signal),0));
                r_com = signal.*y_index_r-signal.*y_future_r;
                %r_com(ind_fee) = r_com(ind_fee)-1.5/1000*0.5-1.5/100000*0.5;
                yp_c = cumprod(1+r_com);

                t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),tref,'UniformOutput',false);
                if eq(ticker_sel,1)
                    h = figure;
                end
                subplot(5,1,ticker_sel)
                plot(yp_c,'LineWidth',2)
                set(gca,'XLim',[1,length(t_str)]);
                set(gca,'XTickLabelRotation',90);
                set(gca,'XTick',floor(linspace(1,length(t_str),30)),'xlim',[1,length(t_str)]);
                set(gca,'XTickLabel',t_str(floor(linspace(1,length(t_str),30))));
                title(sprintf('%s基差择时对冲收益率',ticker_targ))
                
                yp_c_all(ticker_sel) = {yp_c};
            end
            yp_c_all = {yp_c_all,ticker_targ_p};
            setpixelposition(gcf,[749,279,916,889])
        end
        %验证累积基差
        function h=validation_JC(obj)
            key_str = 'S50 综合信号基差收益验证';
            dN = 'S50';
            tn = 'index_com';
            tN_f = sprintf('%s.%s',dN,tn);
            
            sprintf('%s',key_str)
            ticker_p = {'IF','IC','IH','ES','NQ'};
            ticker_targ_p = {'000300','000905','000016','SPX2','NDX2'};
            T_ticker_p = length(ticker_p);
            sql_str1 = 'select tradeDate,index_a,index_future from %s where ticker = "%s" order by tradeDate';
            for ticker_sel = 1:T_ticker_p
                ticker= ticker_p{ticker_sel};
                ticker_targ = ticker_targ_p{ticker_sel};
                index_com = fetchmysql(sprintf(sql_str1,tN_f,ticker),2);
                tref = index_com(:,1);
                tref_month = yq_methods.get_month_data();
                [~,month_num] = intersect(tref,tref_month); 
                index_com = index_com(month_num,:);
                tref = index_com(:,1);

                y = cell2mat(index_com(:,2:end));
                y = [y(:,1),y(:,1)-y(:,2)];

                y_delta = y(:,2);
                y_index = y(:,1);

                window_num = 6;
                signal1 = obj.S50_signal1(y_index);
                signal2 = obj.S50_signal2(y_delta,window_num);
                signal3 = obj.S50_signal3(y_delta);

                signal = signal1+signal2+signal3;

                y_c = [0;diff(y_delta)];
                yp_c = signal.*y_c;
                yp = yp_c>0;
                yp = yp(window_num+1:end);
                sprintf('%s : 综合信号预测基差 正确次数%d 预测错误次数%d',ticker,sum(yp),sum(yp==0))

                tref = tref(window_num:end);
                yp_c = yp_c(window_num:end);
                yp_c(1) = 0;
                yp_c = cumsum(yp_c);

                t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),tref,'UniformOutput',false);
                if eq(ticker_sel,1)
                    h = figure;
                end
                subplot(5,1,ticker_sel)
                plot(yp_c,'LineWidth',2)
                set(gca,'XLim',[1,length(t_str)]);
                set(gca,'XTickLabelRotation',90);
                set(gca,'XTick',floor(linspace(1,length(t_str),30)),'xlim',[1,length(t_str)]);
                set(gca,'XTickLabel',t_str(floor(linspace(1,length(t_str),30))));
                title(sprintf('%s累积基差收益',ticker_targ))
            end
            setpixelposition(gcf,[749,279,916,889])
        end        
    end
    
    
    methods(Static)
        function createtable_S50()
            dN = 'S50';
            tn = 'index_com';
            var_info = {'ticker','tradeDate','index_a','index_future'};
            var_type = {'varchar(10)','date','float','float'};
            key_var = 'ticker,tradeDate';
            create_table_adair(dN,tn,var_info,var_type,key_var);
        end
        %com index
        function com_future_index()
            key_str = 'S50合成股指期货指数';
            sprintf('%s',key_str)
            dN = 'S50';
            tn = 'index_com';
            tN_f = sprintf('%s.%s',dN,tn);
            var_info = {'ticker','tradeDate','index_a','index_future'};

            ticker_p = {'IF','IH','IC'};
            ticker_targ_p = {'000300','000016','000905'};
            T_ticker_p = length(ticker_p);
            
            for ticker_sel = 1:T_ticker_p
                ticker= ticker_p{ticker_sel};
                ticker_targ = ticker_targ_p{ticker_sel};

                t0  = fetchmysql(sprintf('select tradeDate from %s where ticker = "%s" order by tradeDate desc limit 1',tN_f,ticker),2);
                if isempty(t0)
                    t0 = '2010-01-01';
                else
                    t0 = t0{1};
                end
                fields_str = 'tradeDate,contractObject,openPrice,highestPrice,lowestPrice,closePrice,settlePrice,openInt';
                tn = 'yuqerdata.yq_MktMFutdGet';

                tref = 'select distinct(tradeDate) from %s where contractObject="%s" and tradeDate>"%s" order by tradeDate';
                tref = fetchmysql(sprintf(tref,tn,ticker,t0),2);
                if isempty(tref)
                    continue
                end

                sql_temp = 'select %s from %s where contractObject= "%s" and tradeDate >="%s" and tradeDate<="%s"';
                X0 = fetchmysql(sprintf(sql_temp,fields_str,tn,ticker,tref{1},tref{end}),2);
                X_t = X0(:,1);
                X_v = cell2mat(X0(:,3:end));
                T = length(tref);
                Y = cell(T,1);
                for i = 1:T
                    sub_t = tref{i};
                    sub_ind = strcmp(X_t,sub_t);
                    sub_x = X_v(sub_ind,:);
                    sub_w = sub_x(:,end);
                    sub_w = sub_w ./sum(sub_w);
                    sub_y = sub_w'*sub_x(:,1:end-1);
                    Y{i} = sub_y';
                    %if eq(mod(i,100),0)
                    %    sprintf('%s 合成指数 %d-%d',key_str,i,T)
                    %end
                end
                Y = [Y{:}]';

                %载入指数数据
                sql_temp =[ 'select tradeDate,closeIndex from yuqerdata.yq_index ',...
                    'where symbol = "%s" and tradeDate >= "2010-04-30" order by tradeDate'];
                Y1 = fetchmysql(sprintf(sql_temp,ticker_targ),2);
                [~,ia,ib] = intersect(tref,Y1(:,1));

                Y3 = [Y1(ib,:),num2cell(Y(ia,end-1))];
                Y4 = cell2mat(Y3(:,2:end));
                %Y4 = movmean(Y4,[21,0]);
                %Y5 = Y4(:,1)-Y4(:,end); %基差
                index_com = [Y3(:,1),num2cell(Y4)];
                %save(sprintf('index_com%s.mat',ticker),'index_com');
                mysql_re = index_com(:,[1,1:end]);
                mysql_re(:,1) = {ticker};
                datainsert_adair(tN_f,var_info,mysql_re);
            end
        end
        %america future index
        function com_us_future_index()
            key_str = 'S50合成股指期货指数_USfuture';
            sprintf('%s',key_str)
            dN = 'S50';
            tn = 'index_com';
            tN_f = sprintf('%s.%s',dN,tn);
            var_info = {'ticker','tradeDate','index_a','index_future'};

            ticker_p = {'ES','NQ'};
            ticker_targ_p = {'SPX2','NDX2'};
            T_ticker_p = length(ticker_p);
            
            for ticker_sel = 1:T_ticker_p
                ticker= ticker_p{ticker_sel};
                ticker_targ = ticker_targ_p{ticker_sel};

                t0  = fetchmysql(sprintf('select tradeDate from %s where ticker = "%s" order by tradeDate desc limit 1',tN_f,ticker),2);
                if isempty(t0)
                    t0 = '2010-01-01';
                else
                    t0 = t0{1};
                end
                fields_str = 'tradeDate,mark4,openPrice,highestPrice,lowestPrice,settlePrice,settlePrice,volume';
                tn = 'S50.us_futures';

                tref = 'select distinct(tradeDate) from %s where mark4="%s" and tradeDate>"%s" order by tradeDate';
                tref = fetchmysql(sprintf(tref,tn,ticker,t0),2);
                if isempty(tref)
                    continue
                end

                sql_temp = 'select %s from %s where mark4= "%s" and tradeDate >="%s" and tradeDate<="%s"';
                X0 = fetchmysql(sprintf(sql_temp,fields_str,tn,ticker,tref{1},tref{end}),2);
                X_t = X0(:,1);
                X_v = cell2mat(X0(:,3:end));
                T = length(tref);
                Y = cell(T,1);
                for i = 1:T
                    sub_t = tref{i};
                    sub_ind = strcmp(X_t,sub_t);
                    sub_x = X_v(sub_ind,:);
                    sub_w = sub_x(:,end);
                    sub_w = sub_w ./sum(sub_w);
                    if any(isnan(sub_w))
                        sub_w(1:end) = 1/length(sub_w);
                    end
                    sub_y = sub_w'*sub_x(:,1:end-1);
                    Y{i} = sub_y';
                    %if eq(mod(i,100),0)
                    %    sprintf('%s 合成指数 %d-%d',key_str,i,T)
                    %end
                end
                Y = [Y{:}]';

                %载入指数数据
                sql_temp =[ 'select tradeDate,closeIndex from S50.usindex ',...
                    'where ticker = "%s" and tradeDate >= "2010-01-01" order by tradeDate'];
                Y1 = fetchmysql(sprintf(sql_temp,ticker_targ),2);
                [~,ia,ib] = intersect(tref,Y1(:,1));

                Y3 = [Y1(ib,:),num2cell(Y(ia,end-1))];
                Y4 = cell2mat(Y3(:,2:end));
                %Y4 = movmean(Y4,[21,0]);
                %Y5 = Y4(:,1)-Y4(:,end); %基差
                index_com = [Y3(:,1),num2cell(Y4)];
                %save(sprintf('index_com%s.mat',ticker),'index_com');
                mysql_re = index_com(:,[1,1:end]);
                mysql_re(:,1) = {ticker};
                datainsert_adair(tN_f,var_info,mysql_re);
            end
        end
        %对接数据升级
        function com_us_future_index_update()
            key_str = 'S50合成股指期货指数_USfuture';
            sprintf('%s',key_str)
            dN = 'S50';
            tn = 'index_com';
            tN_f = sprintf('%s.%s',dN,tn);
            var_info = {'ticker','tradeDate','index_a','index_future'};

            ticker_p = {'ES','NQ'};
            ticker_targ_p = {'SPX','NDX'};
            T_ticker_p = length(ticker_p);
            
            for ticker_sel = 1:T_ticker_p
                ticker= ticker_p{ticker_sel};
                ticker_targ = ticker_targ_p{ticker_sel};
                t0  = fetchmysql(sprintf('select tradeDate from %s where ticker = "%s" order by tradeDate desc limit 1',tN_f,ticker),2);
                if isempty(t0)
                    t0 = '2010-01-01';
                else
                    t0 = t0{1};
                end
                fields_str =[ 'tradeDate,contractObject,openPrice,highestPrice,',...
                    ' lowestPrice,settlePrice,settlePrice,preOpenInt'];
                tn = 'yuqerdata.MktCmeFutdGet_S50';

                tref = 'select distinct(tradeDate) from %s where contractObject="%s" and tradeDate>"%s" order by tradeDate';
                tref = fetchmysql(sprintf(tref,tn,ticker,t0),2);
                if isempty(tref)
                    continue
                end

                sql_temp = 'select %s from %s where contractObject= "%s" and tradeDate >="%s" and tradeDate<="%s"  and settlePrice is not null and settlePrice>0';
                X0 = fetchmysql(sprintf(sql_temp,fields_str,tn,ticker,tref{1},tref{end}),2);
                X_t = X0(:,1);
                X_v = cell2mat(X0(:,3:end));
                T = length(tref);
                Y = cell(T,1);
                for i = 1:T
                    sub_t = tref{i};
                    sub_ind = strcmp(X_t,sub_t);
                    sub_x = X_v(sub_ind,:);
                    sub_w = sub_x(:,end);
                    sub_w = sub_w ./sum(sub_w);
                    if any(isnan(sub_w))
                        sub_w(1:end) = 1/length(sub_w);
                    end
                    sub_y = sub_w'*sub_x(:,1:end-1);
                    Y{i} = sub_y';
                    %if eq(mod(i,100),0)
                    %    sprintf('%s 合成指数 %d-%d',key_str,i,T)
                    %end
                end
                Y = [Y{:}]';

                %载入指数数据
                sql_temp =[ 'select tradeDate,closeIndex from S50.index_sina ',...
                    'where ticker = "%s" and tradeDate >= "2010-01-01" order by tradeDate'];
                Y1 = fetchmysql(sprintf(sql_temp,ticker_targ),2);
                [~,ia,ib] = intersect(tref,Y1(:,1));

                Y3 = [Y1(ib,:),num2cell(Y(ia,end-1))];
                Y4 = cell2mat(Y3(:,2:end));
                %Y4 = movmean(Y4,[21,0]);
                %Y5 = Y4(:,1)-Y4(:,end); %基差
                index_com = [Y3(:,1),num2cell(Y4)];
                %save(sprintf('index_com%s.mat',ticker),'index_com');
                mysql_re = index_com(:,[1,1:end]);
                mysql_re(:,1) = {ticker};
                datainsert_adair(tN_f,var_info,mysql_re);
            end
        end
        
        function signal1 = S50_signal1(y_index)
            T = length(y_index);
            signal1 = nan(T,1);
            for i = 2:T-1   
                sub_x = y_index(i)-y_index(i-1);
                if sub_x>0
                    signal1(i+1) = -1;
                else
                    signal1(i+1) = 1;
                end
            end
        end
        %%%%%%%%%%%%
        function signal2 = S50_signal2(y_delta,window_num)
            T = length(y_delta);
            signal2 = nan(T,1);
            for i = window_num:T-1
                sub_ind = i-window_num+1:i;

                sub_x = y_delta(sub_ind);
                %fit
                sub_p = polyfit((1:6)',sub_x,1);
                sub_x_v = polyval(sub_p,(1:6));

                if sub_x(end)-sub_x_v(end)<0
                    signal2(i+1) = 1;
                else
                    signal2(i+1) = -1;
                end    
            end
        end
        %%%%%%%%%%%%%%%%%%%
        function [signal3,re] = S50_signal3(y_delta)
            T = length(y_delta);
            signal3 = nan(T,1);
            y_dir = signal3;
            t_cirle = 1; %ini
            t_dir = 0;

            y_dir(1) = 0;
            y_circle = signal3;
            y_circle(1) = t_cirle;
            torf = signal3;
            for i = 2:T-1
                if y_delta(i)>y_delta(i-1)
                    y_dir(i) = 1;
                else
                    y_dir(i) = -1;
                end
                %周期计算
                if eq(y_dir(i),t_dir)
                    t_cirle = t_cirle-1;
                    %yp(i) = 1;%Yes
                    torf(i)=true;
                    if eq(t_cirle,0)
                        %更新方向
                        t_dir=-y_dir(i);
                        %更新周期
                        temp = flipud(y_dir(1:i));
                        temp = eq(temp,temp(1));
                        temp1 = find(~temp,1);
                        if ~isempty(temp1)
                            t_cirle = sum(temp(1:temp1-1));
                        else
                            t_cirle = sum(temp);
                        end
                    end        
                else
                    t_dir=-y_dir(i);
                    %更新周期
                    temp = flipud(y_dir(1:i));
                    temp = eq(temp,temp(1));
                    temp1 = find(~temp,1);
                    if ~isempty(temp1)
                        t_cirle = sum(temp(1:temp1-1));
                    else
                        t_cirle = sum(temp);
                    end
                    %yp(i) = 0;
                    torf(i) = false;
                end
                y_circle(i) = t_cirle;
                signal3(i+1) = t_dir;
            end
            re = num2cell([y_delta,torf,y_dir,signal3,y_circle]);
            re = cell2table(re,'VariableNames',{'dy','torf','ydir_real','ydir_pred','circle'});    
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
                [v0,v_str0] = curve_static(yc{i},12);
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