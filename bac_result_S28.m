classdef bac_result_S28 < handle
    methods
        function get_all_results(obj)
            file_name = sprintf('S28日内收益分布%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));  
            re = [];
            re = cat(1,re,obj.get_rule21_signal(obj_wd));
            re = cat(1,re,obj.get_rule22_signal(obj_wd));
            re = cat(1,re,obj.get_rule23_signal(obj_wd));
            re = cat(1,re,obj.get_rule24_signal(obj_wd));
            re1 = obj.get_com_2factor(obj_wd)
            re = cat(1,re,obj.get_com_2factor(obj_wd));
            [sub_re,Y_re] = obj.get_com_3factor(obj_wd);
            re = cat(1,re,sub_re);  
            obj_wd.CloseWord()
                      
            Y_re = [{'时间','IF','IH','IC'};Y_re];
            [~,n] = size(re);
            [m1,n1] = size(Y_re);
            temp = cell(m1,n);
            temp(:,1:n1) = Y_re;
            re = [re;temp];
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
            
        end
    end
    methods(Static)
        function re = get_rule21_signal(obj_wd)
            key_str = '收盘折溢价因子结果';
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            sql_str  =['select tradingdate,t_hour*100+t_minute,price from pytdx_data.%s_tdx_min ',...
                'where price is not null and price>0 order by tradingdate,t_hour,t_minute'];
            sql_str_2 = ['SELECT tradeDate,ticker,closeprice-settlePrice FROM ',...
                'yuqerdata.yq_MktMFutdGet where contractObject=''%s'' and mainCon=1 order by tradedate'];
            cut_time = [930,1000];
            cut_str = {'多头净值','多空净值'};

            dns = {'IF','IH','IC'};
            T_dns = length(dns);
            re = cell(size(dns));
            for i0 = 1:T_dns
                sub_str = dns{i0};
                sub_str_l = length(sub_str);
                x = fetchmysql(sprintf(sql_str,sub_str),2);
                sub_code = fetchmysql(sprintf(sql_str_2,sub_str),2);
                tref_all = x(:,1);
                tref = unique(tref_all);
                [tref,~,ia] = intersect(tref,sub_code(:,1),'stable');
                sub_signal = cell2mat(sub_code(ia,3));
                sub_code = sub_code(ia,2);
                sub_code = cellfun(@(x) str2double(x(sub_str_l+1:end)),sub_code);
                sub_code_ind = find(diff(sub_code))+1;
                t_min = cell2mat(x(:,2));
                x = cell2mat(x(:,3));
                x = [0;x(2:end)./x(1:end-1)-1];
                T = length(tref);
                y = zeros(T,2);

                y_temp = cell(T,1);
                for i = 2:T
                    sub_y = zeros(1,2);
                    sub_sub_signal = sub_signal(i-1);
                    sub_ind = strcmp(tref_all,tref(i));        
                    sub_x = x(sub_ind);
                    sub_t = t_min(sub_ind);

                    sub_sub_ind = sub_t>=cut_time(1) &sub_t<=cut_time(2);
                    temp0 = sub_x(sub_sub_ind);
                    if any(eq(sub_code_ind,i))
                        temp0(1) = 0;
                        temp = cumprod(1+temp0)-1;
                    else
                        temp = cumprod(1+temp0)-1;
                    end
                    if sub_sub_signal<0
                        sub_y(1) = temp(end);
                        sub_y(2) = temp(end);
                    else
                        sub_y(2) = -temp(end);
                    end
                    y_temp{i} = sub_y;
                    sprintf('%d-%d',i,T)
                end
                for i = 2:T
                    y(i,:) = y_temp{i};
                end
                y_re = cumprod(1+y);
                if sub_signal(end)<0
                    test_v = 1;
                elseif sub_signal(end)>0
                    test_v = -1;
                else
                    test_v = 0;
                end
                sub_info = signal_str(test_v);
                h = figure;
                plot(y_re*100,'LineWidth',2);
                legend(cut_str,'NumColumns',3,'Location','northwest')
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                t_str = tref(floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str);
                set(gca,'XTickLabelRotation',90)
                title(sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info))
                box off
                setpixelposition(gcf,[223,365,1345,420]);
                obj_wd.pasteFigure(h,sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info));
                
                V = y_re;
                [v,v_str] = curve_static(V(:,1));
                [v1,v_str1] = ad_trans_sta_info(v,v_str);
                [v,v_str] = curve_static(V(:,2));
                [v2,~] = ad_trans_sta_info(v,v_str);                
                if eq(i0,1)
                    sub_re =[ [{key_str};v_str1'],[sprintf('%s%s',sub_str,cut_str{1});v1'],...
                        [sprintf('%s%s',sub_str,cut_str{2});v2']];
                else
                    sub_re =[[sprintf('%s%s',sub_str,cut_str{1});v1'],...
                    [sprintf('%s%s',sub_str,cut_str{2});v2']];
                end
                re{i0} = sub_re;

            end
            re = [re{:}]';
        end
        function re = get_rule22_signal(obj_wd)
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            key_str ='买卖单不平衡度度结果';
            f_type = 2;
            tn_f = 'S28.comfactors';
            var_info = {'symbol','tradingdate','f_type','f_val'};

            sql_str  =['select tradingdate,t_hour*100+t_minute,price from pytdx_data.%s_tdx_min ',...
                'where price is not null and price>0 and tradingdate>=''2016-12-29'' order by tradingdate,t_hour,t_minute'];

            sql_str_2 = ['SELECT tradeDate,ticker,closeprice-settlePrice FROM ',...
                'yuqerdata.yq_MktMFutdGet where contractObject=''%s'' and mainCon=1 order by tradedate'];
            cut_time = [930,1000];
            cut_str = {'多头净值','多空净值'};

            f0 = fetchmysql(sprintf('select %s from %s where f_type = %d order by tradingdate',...
                strjoin(var_info,','),tn_f,f_type),2);

            dns = {'IF','IH','IC'};
            T_dns = length(dns);
            re = cell(size(dns));
            for i0 = 1:T_dns
                sub_str = dns{i0};
                sub_str_l = length(sub_str);
                x = fetchmysql(sprintf(sql_str,sub_str),2);
                sub_code = fetchmysql(sprintf(sql_str_2,sub_str),2);

                f = f0(strcmp(f0(:,1),sub_str),[2,4]);

                [~,ia,ib] = intersect(sub_code(:,1),f(:,1),'stable');
                sub_code = [sub_code(ia,1:2),f(ib,end)];
                tref_all = x(:,1);
                tref = unique(tref_all);
                [tref,~,ia] = intersect(tref,sub_code(:,1),'stable');

                sub_signal = cell2mat(sub_code(ia,3));
                sub_code = sub_code(ia,2);
                sub_code = cellfun(@(x) str2double(x(sub_str_l+1:end)),sub_code);
                sub_code_ind = find(diff(sub_code))+1;
                t_min = cell2mat(x(:,2));
                x = cell2mat(x(:,3));
                x = [0;x(2:end)./x(1:end-1)-1];
                T = length(tref);
                y = zeros(T,2);

                y_temp = cell(T,1);
                for i = 2:T
                    sub_y = zeros(1,2);
                    sub_sub_signal = sub_signal(i-1);
                    sub_ind = strcmp(tref_all,tref(i));        
                    sub_x = x(sub_ind);
                    sub_t = t_min(sub_ind);

                    sub_sub_ind = sub_t>=cut_time(1) &sub_t<=cut_time(2);
                    temp0 = sub_x(sub_sub_ind);
                    if any(eq(sub_code_ind,i))
                        temp0(1) = 0;
                        temp = cumprod(1+temp0)-1;
                    else
                        temp = cumprod(1+temp0)-1;
                    end
                    if sub_sub_signal<0
                        sub_y(1) = temp(end);
                        sub_y(2) = temp(end);
                    else
                        sub_y(2) = -temp(end);
                    end
                    y_temp{i} = sub_y;
                    sprintf('%d-%d',i,T)
                end
                for i = 2:T
                    y(i,:) = y_temp{i};
                end
                y_re = cumprod(1+y);
                if sub_signal(end)<0
                    test_v = 1;
                elseif sub_signal(end)>0
                    test_v = -1;
                else
                    test_v = 0;
                end
                sub_info = signal_str(test_v);
                %y_re = cumsum(y)+1;
                h = figure;
                plot(y_re*100,'LineWidth',2);
                legend(cut_str,'NumColumns',3,'Location','northwest')
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                t_str = tref(floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str);
                set(gca,'XTickLabelRotation',90)
                title(sprintf('%s:%s-%s:%s',key_str,tref{end},sub_str,sub_info))
                setpixelposition(gcf,[223,365,1345,420]);
                box off
                obj_wd.pasteFigure(h,sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info));
                V = y_re;
                [v,v_str] = curve_static(V(:,1));
                [v1,v_str1] = ad_trans_sta_info(v,v_str);
                [v,v_str] = curve_static(V(:,2));
                [v2,~] = ad_trans_sta_info(v,v_str);                
                if eq(i0,1)
                    sub_re =[ [{key_str};v_str1'],[sprintf('%s%s',sub_str,cut_str{1});v1'],...
                        [sprintf('%s%s',sub_str,cut_str{2});v2']];
                else
                    sub_re =[[sprintf('%s%s',sub_str,cut_str{1});v1'],...
                    [sprintf('%s%s',sub_str,cut_str{2});v2']];
                end
                re{i0} = sub_re;
            end
            re = [re{:}]';
        end
        function re = get_rule23_signal(obj_wd)
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            key_str ='尾盘涨幅因子';
            f_type = 3;
            tn_f = 'S28.comfactors';
            var_info = {'symbol','tradingdate','f_type','f_val','f_val2'};

            sql_str  =['select tradingdate,t_hour*100+t_minute,price from pytdx_data.%s_tdx_min ',...
                'where price is not null and price>0 and tradingdate>=''2016-12-29'' order by tradingdate,t_hour,t_minute'];
            sql_str_2 = ['SELECT tradeDate,ticker,closeprice-settlePrice FROM ',...
                'yuqerdata.yq_MktMFutdGet where contractObject=''%s'' and mainCon=1 order by tradedate'];
            cut_time = [930,1000];
            cut_str = {'多头净值15','多空净值15','多头净值30','多空净值30'};

            dns = {'IF','IH','IC'};
            T_dns = length(dns);
            re  = cell(size(dns));
            f0 = fetchmysql(sprintf('select %s from %s where f_type = %d order by tradingdate',...
                strjoin(var_info,','),tn_f,f_type),2);
            for i0 = 1:T_dns

                y1 = [];
                for i1 = 1:2
                    sub_str = dns{i0};
                    sub_str_l = length(sub_str);
                    x = fetchmysql(sprintf(sql_str,sub_str),2);
                    sub_code = fetchmysql(sprintf(sql_str_2,sub_str),2);
                    f = f0(strcmp(f0(:,1),sub_str),:);
                    if eq(i1,1)
                        f = f(:,[2,4]);
                    else
                        f = f(:,[2,4,5]);
                    end
                    [~,ia,ib] = intersect(sub_code(:,1),f(:,1),'stable');
                    sub_code = [sub_code(ia,1:2),f(ib,end)];
                    tref_all = x(:,1);
                    tref = unique(tref_all);
                    [tref,~,ia] = intersect(tref,sub_code(:,1),'stable');
                    sub_signal = cell2mat(sub_code(ia,3));
                    sub_code = sub_code(ia,2);
                    sub_code = cellfun(@(x) str2double(x(sub_str_l+1:end)),sub_code);
                    sub_code_ind = find(diff(sub_code))+1;
                    t_min = cell2mat(x(:,2));
                    x = cell2mat(x(:,3));
                    x = [0;x(2:end)./x(1:end-1)-1];

                    T = length(tref);
                    y = zeros(T,2);

                    y_temp = cell(T,1);
                    %为了并行，做了调整
                    parfor i = 2:T
                        sub_y = zeros(1,2);
                        sub_sub_signal = sub_signal(i-1);
                        sub_ind = strcmp(tref_all,tref(i));        
                        sub_x = x(sub_ind);
                        sub_t = t_min(sub_ind);

                        sub_sub_ind = sub_t>=cut_time(1) &sub_t<=cut_time(2);
                        temp0 = sub_x(sub_sub_ind);
                        if any(eq(sub_code_ind,i))
                            temp0(1) = 0;
                            temp = cumprod(1+temp0)-1;
                        else
                            temp = cumprod(1+temp0)-1;
                        end
                        if sub_sub_signal<0
                            sub_y(1) = temp(end);
                            sub_y(2) = temp(end);
                        else
                            sub_y(2) = -temp(end);
                        end
                        y_temp{i} = sub_y;
                        sprintf('%d-%d',i,T)
                    end
                    for i = 2:T
                        y(i,:) = y_temp{i};
                    end
                    y1 = cat(2,y1,y);
                end

                y_re = cumprod(1+y1);
                if sub_signal(end)<0
                    test_v = 1;
                elseif sub_signal(end)>0
                    test_v = -1;
                else
                    test_v = 0;
                end
                sub_info = signal_str(test_v);
                h = figure;
                T = length(tref);
                plot(y_re*100,'LineWidth',2);
                legend(cut_str,'NumColumns',3,'Location','northwest')
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                t_str = tref(floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str);
                set(gca,'XTickLabelRotation',90)
                title(sprintf('%s:%s-%s:%s',key_str,tref{end},sub_str,sub_info))
                setpixelposition(gcf,[223,365,1345,420]);
                box off
                obj_wd.pasteFigure(h,sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info));
                V = y_re;
                sub_re = [];
                for i = 1:length(cut_str)
                    [v,v_str] = curve_static(V(:,i));
                    [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                    if eq(i0,1) && eq(i,1)
                        sub_re =cat(2,sub_re,[[{key_str};v_str1'],[sprintf('%s%s',sub_str,cut_str{i});v1']]);
                    else
                        sub_re = cat(2,sub_re,[sprintf('%s%s',sub_str,cut_str{i});v1']);
                    end
                end
                re{i0} = sub_re;
            end
            re = [re{:}]';
        end
        function re = get_rule24_signal(obj_wd)
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            key_str ='尾盘基差变化结果';
            f_type = 4;
            tn_f = 'S28.comfactors';
            var_info = {'symbol','tradingdate','f_type','f_val'};

            sql_str  =['select tradingdate,t_hour*100+t_minute,price from pytdx_data.%s_tdx_min ',...
                'where price is not null and price>0 and tradingdate>=''2016-12-29'' order by tradingdate,t_hour,t_minute'];

            sql_str_2 = ['SELECT tradeDate,ticker,closeprice-settlePrice FROM ',...
                'yuqerdata.yq_MktMFutdGet where contractObject=''%s'' and mainCon=1 order by tradedate'];
            cut_time = [930,1000];
            cut_str = {'多头净值','多空净值'};

            f0 = fetchmysql(sprintf('select %s from %s where f_type = %d order by tradingdate',...
                strjoin(var_info,','),tn_f,f_type),2);

            dns = {'IF','IH','IC'};
            T_dns = length(dns);
            re = cell(size(dns));
            
            for i0 = 1:T_dns
                sub_str = dns{i0};
                sub_str_l = length(sub_str);
                x = fetchmysql(sprintf(sql_str,sub_str),2);
                sub_code = fetchmysql(sprintf(sql_str_2,sub_str),2);

                f = f0(strcmp(f0(:,1),sub_str),[2,4]);

                [~,ia,ib] = intersect(sub_code(:,1),f(:,1),'stable');
                sub_code = [sub_code(ia,1:2),f(ib,end)];
                tref_all = x(:,1);
                tref = unique(tref_all);
                [tref,~,ia] = intersect(tref,sub_code(:,1),'stable');
                sub_code = sub_code(ia,:);
                sub_signal = cell2mat(sub_code(ia,3));
                sub_code = sub_code(ia,2);
                sub_code = cellfun(@(x) str2double(x(sub_str_l+1:end)),sub_code);
                sub_code_ind = find(diff(sub_code))+1;
                t_min = cell2mat(x(:,2));
                x = cell2mat(x(:,3));
                x = [0;x(2:end)./x(1:end-1)-1];
                T = length(tref);
                y = zeros(T,2);

                y_temp = cell(T,1);
                for i = 2:T
                    sub_y = zeros(1,2);
                    sub_sub_signal = sub_signal(i-1);
                    sub_ind = strcmp(tref_all,tref(i));        
                    sub_x = x(sub_ind);
                    sub_t = t_min(sub_ind);

                    sub_sub_ind = sub_t>=cut_time(1) &sub_t<=cut_time(2);
                    temp0 = sub_x(sub_sub_ind);
                    if any(eq(sub_code_ind,i))
                        temp0(1) = 0;
                        temp = cumprod(1+temp0)-1;
                    else
                        temp = cumprod(1+temp0)-1;
                    end
                    if sub_sub_signal<0
                        sub_y(1) = temp(end);
                        sub_y(2) = temp(end);
                    else
                        sub_y(2) = -temp(end);
                    end
                    y_temp{i} = sub_y;
                    sprintf('%d-%d',i,T)
                end
                for i = 2:T
                    y(i,:) = y_temp{i};
                end
                y_re = cumprod(1+y);
                if sub_signal(end)<0
                    test_v = 1;
                elseif sub_signal(end)>0
                    test_v = -1;
                else
                    test_v = 0;
                end
                sub_info = signal_str(test_v);

                h = figure;
                plot(y_re*100,'LineWidth',2);
                legend(cut_str,'NumColumns',3,'Location','northwest')
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                t_str = tref(floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str);
                set(gca,'XTickLabelRotation',90)
                title(sprintf('%s:%s-%s:%s',key_str,tref{end},sub_str,sub_info))
                setpixelposition(gcf,[223,365,1345,420]);
                box off
                obj_wd.pasteFigure(h,sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info));
                
                V = y_re;
                sub_re = [];
                for i = 1:length(cut_str)
                    [v,v_str] = curve_static(V(:,i));
                    [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                    if eq(i0,1) && eq(i,1)
                        sub_re =cat(2,sub_re,[[{key_str};v_str1'],[sprintf('%s%s',sub_str,cut_str{i});v1']]);
                    else
                        sub_re = cat(2,sub_re,[sprintf('%s%s',sub_str,cut_str{i});v1']);
                    end
                end
                re{i0} = sub_re;
                
            end
            re =[re{:}]';
            
        end
        function re = get_com_2factor(obj_wd)
            key_str = 'S28双因子';
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});
            sql_str_2 = ['SELECT tradeDate,ticker,closeprice-settlePrice FROM ',...
                'yuqerdata.yq_MktMFutdGet where contractObject=''%s'' and mainCon=1 order by tradedate'];

            cut_time = [930,1000];
            cut_str = {'多头净值','多空净值'};

            dns = {'IF','IH','IC'};
            T_dns = length(dns);
            Y_re = [];
            re = cell(dns);
            sql_str1 = 'select tradingdate,f_val from S28.comfactors where symbol = ''%s'' and f_type=%d';
            sql_str2 = 'select tradingdate,p1,p2,p3 from S28.bac_price where symbol =''%s'' order by tradingdate';
            for i0 = 1:T_dns
                sub_str = dns{i0};
                sub_str_l = length(sub_str);
                %x = fetchmysql(sprintf(sql_str,sub_str),2);
                %x = load(sprintf('data_update_%s.mat',sub_str));
                %x = x.F;
                x = fetchmysql(sprintf(sql_str2,sub_str),2);
                sub_code = fetchmysql(sprintf(sql_str_2,sub_str),2);

                f1 = fetchmysql(sprintf(sql_str1,sub_str,1),2);
                f2 = fetchmysql(sprintf(sql_str1,sub_str,2),2);
                %f1 = load(sprintf('F21_%s.mat',sub_str));
                %f1 = f1.F;
                %f2 = load(sprintf('F22_%s.mat',sub_str));
                %f2 = f2.F;


                [~,ia,ib] = intersect(f1(:,1),f2(:,1));
                f3 = cell2mat([f1(ia,2),f2(ib,2)]);
                f4 = ones(size(f3(:,1)));
                f4(f3(:,1)<0|f3(:,2)<0)=-1;
                f=[f1(ia,1),num2cell(f4)];
                [~,ia,ib] = intersect(sub_code(:,1),f(:,1),'stable');
                sub_code = [sub_code(ia,1:2),f(ib,end)];
                tref = x(:,1);
                [~,~,ia] = intersect(tref,sub_code(:,1),'stable');
                if ~eq(length(ia),length(tref))
                    continue
                end
                sub_signal = cell2mat(sub_code(ia,3));
                sub_code = sub_code(ia,2);
                sub_code = cellfun(@(x) str2double(x(sub_str_l+1:end)),sub_code);
                sub_code_ind = find(diff(sub_code))+1;

                x = cell2mat(x(:,2:end));
                x = x(:,2)./x(:,3)-1;
                x(isnan(x)|isinf(x)|eq(x,0)) = 0;
                T = length(tref);
                y = zeros(T,2);

                y_temp = cell(T,1);
                for i = 2:T
                    sub_y = zeros(1,2);
                    sub_sub_signal = sub_signal(i-1);       
                    sub_x = x(i);
                    sub_x = sub_x-2/10000;
                    if any(eq(sub_code_ind,i))
                        temp=0;
                    else
                        temp = sub_x;
                    end
                    if sub_sub_signal<0
                        sub_y(1) = temp(end);
                        sub_y(2) = temp(end);
                    else
                        sub_y(2) = -temp(end);
                    end
                    y_temp{i} = sub_y;
                    sprintf('%d-%d',i,T)
                end
                for i = 2:T
                    y(i,:) = y_temp{i};
                end
                %y_re = cumprod(1+y);
                y_re = cumsum(y)+1;

                if sub_signal(end)<0
                    test_v = 1;
                elseif sub_signal(end)>0
                    test_v = -1;
                else
                    test_v = 0;
                end
                sub_info = signal_str(test_v);

                h=figure;
                bpcure_plot_updateV2(tref,y_re(:,1)*100);
                title(sprintf('%s:%s-%s:%s',key_str,tref{end},sub_str,sub_info))
                setpixelposition(gcf,[223,365,1345,420]);
                box off
                Y_re = cat(2,Y_re,y_re(:,1));
                obj_wd.pasteFigure(h,sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info));                
                sub_re = [];
                [v,v_str] = curve_static(y_re(:,1));
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(i0,1)
                    sub_re =cat(2,sub_re,[[{key_str};v_str1'],[sub_str;v1']]);
                else
                    sub_re = cat(2,sub_re,[sub_str;v1']);
                end

                re{i0} = sub_re;                
            end
            re = [re{:}]';
        end
        function [re,Y_re] = get_com_3factor(obj_wd)
            key_str = 'S28三因子';
            signal_str = containers.Map([-1,0,1],{'做空','平仓','做多'});

            sql_str_2 = ['SELECT tradeDate,ticker,closeprice-settlePrice FROM ',...
                'yuqerdata.yq_MktMFutdGet where contractObject=''%s'' and mainCon=1 order by tradedate'];

            cut_time = [930,1000];
            cut_str = {'多头净值','多空净值'};

            dns = {'IF','IH','IC'};
            re = cell(dns);
            T_dns = length(dns);
            Y_re = [];

            sql_str1 = 'select tradingdate,f_val from S28.comfactors where symbol = ''%s'' and f_type=%d';
            sql_str2 = 'select tradingdate,p1,p2,p3 from S28.bac_price where symbol =''%s'' order by tradingdate';
            for i0 = 1:T_dns
                sub_str = dns{i0};
                sub_str_l = length(sub_str);
                %x = fetchmysql(sprintf(sql_str,sub_str),2);
                %x = load(sprintf('data_update_%s.mat',sub_str));
                %x = x.F;
                x = fetchmysql(sprintf(sql_str2,sub_str),2);

                sub_code = fetchmysql(sprintf(sql_str_2,sub_str),2);

                f1 = fetchmysql(sprintf(sql_str1,sub_str,1),2);
                f2 = fetchmysql(sprintf(sql_str1,sub_str,2),2);
                f3 = fetchmysql(sprintf(sql_str1,sub_str,4),2);
                %f1 = load(sprintf('F21_%s.mat',sub_str));
                %f1 = f1.F;
                %f2 = load(sprintf('F22_%s.mat',sub_str));
                %f2 = f2.F;

                %f3 = load(sprintf('F24_%s.mat',sub_str));
                %f3 = f3.F;
                sub_inds = suscc_intersect({f1(:,1),f2(:,1),f3(:,1)});

                f4 = cell2mat([f1(sub_inds(:,1),2),f2(sub_inds(:,2),2),f3(sub_inds(:,3),2)]);

                f4 = sum(f4<0,2);
                f5 = ones(size(f4(:,1)));
                f5(f4>=2) = -1;
                f=[f1(sub_inds(:,1),1),num2cell(f5)];

                [~,ia,ib] = intersect(sub_code(:,1),f(:,1),'stable');
                sub_code = [sub_code(ia,1:2),f(ib,end)];
                tref = x(:,1);
                [~,~,ia] = intersect(tref,sub_code(:,1),'stable');
                if ~eq(length(ia),length(tref))
                    continue
                end
                sub_signal = cell2mat(sub_code(ia,3));
                sub_code = sub_code(ia,2);
                sub_code = cellfun(@(x) str2double(x(sub_str_l+1:end)),sub_code);
                sub_code_ind = find(diff(sub_code))+1;

                x = cell2mat(x(:,2:end));
                x = x(:,2)./x(:,3)-1;
                x(isnan(x)|isinf(x)|eq(x,0)) = 0;
                T = length(tref);
                y = zeros(T,2);

                y_temp = cell(T,1);
                for i = 2:T
                    sub_y = zeros(1,2);
                    sub_sub_signal = sub_signal(i-1);       
                    sub_x = x(i);
                    sub_x = sub_x-2/10000;
                    if any(eq(sub_code_ind,i))
                        temp=0;
                    else
                        temp = sub_x;
                    end
                    if sub_sub_signal<0
                        sub_y(1) = temp(end);
                        sub_y(2) = temp(end);
                    else
                        sub_y(2) = -temp(end);
                    end
                    y_temp{i} = sub_y;
                    sprintf('%d-%d',i,T)
                end
                for i = 2:T
                    y(i,:) = y_temp{i};
                end
                %y_re = cumprod(1+y);
                y_re = cumsum(y)+1;
                if sub_signal(end)<0
                    test_v = 1;
                elseif sub_signal(end)>0
                    test_v = -1;
                else
                    test_v = 0;
                end
                sub_info = signal_str(test_v);

                h = figure;
                bpcure_plot_updateV2(tref,y_re(:,1)*100);
                title(sprintf('%s:%s-%s:%s',key_str,tref{end},sub_str,sub_info))
                setpixelposition(gcf,[223,365,1345,420]);
                box off
                Y_re = cat(2,Y_re,y_re(:,1));
                obj_wd.pasteFigure(h,sprintf('%s-%s-%s:%s',key_str,tref{end},sub_str,sub_info));                
                sub_re = [];
                [v,v_str] = curve_static(y_re(:,1));
                [v1,v_str1] = ad_trans_sta_info(v,v_str); 
                if eq(i0,1)
                    sub_re =cat(2,sub_re,[[{key_str};v_str1'],[sub_str;v1']]);
                else
                    sub_re = cat(2,sub_re,[sub_str;v1']);
                end

                re{i0} = sub_re;                
            end
            re = [re{:}]';
            Y_re = [tref,num2cell(Y_re)];
        end
    end
end