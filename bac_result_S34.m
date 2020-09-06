%S34实时更新数据程序
%只发最后一个时间点的
classdef bac_result_S34< handle
    methods
        function get_all_results(obj)
            obj.get_S34_signal();
            obj.get_S34_return();
            obj.get_report();
        end
        function get_report(obj)  
            key_str1 = 'S34matlab优化';
            method_id = 34;
            key_str = sprintf('S%d增强效果',method_id);
            tn = sprintf('S%d_result',method_id);            
            sql_str1 = 'select tradingdate,f_ref,f_f from S37.%s where method_name=''%s'' and pool_name = ''%s'' order by tradingdate'; 
            index_str = '000001-上证综指,000016-上证50,000905-中证500,000300-沪深300';
            temp = strsplit(index_str,',');
            index_info = cellfun(@(x) strsplit(x,'-'),temp,'UniformOutput',false);            
%            symbol_pool_all = cellfun(@(x) x{1},index_info,'UniformOutput',false);
            symbol_pool_info = cellfun(@(x) x{2},index_info,'UniformOutput',false);
            
            
            file_name = sprintf('%s表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            T_symbol_pool = length(symbol_pool_info);
            sub_re = cell(1,T_symbol_pool);
            for i = 1:T_symbol_pool
                sub_x = fetchmysql(sprintf(sql_str1,tn,key_str1,symbol_pool_info{i}),2);
                tref = sub_x(:,1);
                r_day = cell2mat(sub_x(:,end-1:end));
                y_c = cumprod(1+r_day);
                title_str = sprintf('%s-%s',key_str,symbol_pool_info{i});
                
                t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref,'UniformOutput',false);            
                T = length(t_str);
                h1=figure;
                plot(y_c,'-','LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                setpixelposition(h1,[223,365,1345,420]);
                box off
                legend({'增强前','增强后'},'NumColumns',2,'Location','best');
                title(title_str);                
                obj_wd.pasteFigure(h1,title_str);
                
                h1=figure;
                y_c2 = y_c(:,2)-y_c(:,1);
                plot(y_c2,'-','LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                setpixelposition(h1,[223,365,1345,420]);
                box off
                legend({'增强后-增强前'},'NumColumns',2,'Location','best');
                title(title_str);                
                obj_wd.pasteFigure(h1,' ');                
                
                [v0,v_str0] = curve_static(y_c(:,1));
                [v,v_str] = obj.ad_trans_sta_info(v0,v_str0);
                temp1 = [[{''};v_str'],[{sprintf('%s-增强前',title_str)};v']];
                
                [v0,v_str0] = curve_static(y_c(:,2));
                [v,v_str] = obj.ad_trans_sta_info(v0,v_str0);
                temp2 = [[{''};v_str'],[{sprintf('%s-增强前',title_str)};v']];
                
                [v0,v_str0] = curve_static(y_c2+1);
                [v,v_str] = obj.ad_trans_sta_info(v0,v_str0);
                temp3 = [[{''};v_str'],[{sprintf('%s-增强后-增强前',title_str)};v']];
                
                if eq(i,1)
                    sub_re{i} = [temp1,temp2(:,2:end),temp3(:,2:end)];
                else
                    sub_re{i} = [temp1(:,2:end),temp2(:,2:end),temp3(:,2:end)];
                end
            end
            sta_re = [sub_re{:}]';

            obj_wd.CloseWord()
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re)            
        end
    end
    methods(Static)
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
        function get_S34_return()
            tn_signal = 'S37.S34_signal';
            tn = 'S37.S34_result';
            var_info = {'tradingdate','pool_name','method_name','f_f','f_ref'};
            key_str = 'S34matlab优化';
            index_str = '000001-上证综指,000016-上证50,000905-中证500,000300-沪深300';
            temp = strsplit(index_str,',');
            index_info = cellfun(@(x) strsplit(x,'-'),temp,'UniformOutput',false);            
            symbol_pool_all = cellfun(@(x) x{1},index_info,'UniformOutput',false);
            symbol_pool_info = cellfun(@(x) x{2},index_info,'UniformOutput',false);
            
            sql_str0 = 'select distinct tradingdate from %s where pool_name = ''%s'' and method_name = ''%s'' order by tradingdate';
            sql_str1 = 'select symbol,w from %s where tradingdate =''%s'' and pool_name = ''%s'' and method_name = ''%s'' ';
            sql_str_index = 'select tradeDate,CHGPct from yuqerdata.yq_index where symbol = ''%s'' order by tradeDate ';
            sql_str_symbol = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate = ''%s''';
            T_symbol_pool_all = length(symbol_pool_all);
            for pool_id = 1:T_symbol_pool_all
                index_pool=symbol_pool_all{pool_id};
                index_name = symbol_pool_info{pool_id};
                r_index = fetchmysql(sprintf(sql_str_index,index_pool),2);
                
                tref_ref =fetchmysql(sprintf(sql_str0,tn_signal,index_name,key_str),2);
                tref_ref_num = datenum(tref_ref);
                tref = yq_methods.get_tradingdate(tref_ref{1});
                tref_complete = fetchmysql(sprintf(sql_str0,tn,index_name,key_str),2);
                tref = setdiff(tref,tref_complete);
                if isempty(tref)
                    continue
                end
                tref_num = datenum(tref);
                T = length(tref);
                re = cell(T,1);
                parfor i = 1:T
                    id = find(tref_ref_num<tref_num(i),1,'last');
                    if isempty(id)
                        re{i}  = [0;0];
                        continue
                    end
                    sub_t1 = tref_ref{id};
                    sub_t2 = tref{i};
                    sub_r = fetchmysql(sprintf(sql_str_symbol,sub_t2),2);
                    sub_x = fetchmysql(sprintf(sql_str1,tn_signal,sub_t1,index_name,key_str),2);
                    
                    sub_y = zeros(size(sub_x(:,1)));
                    [~,ia,ib] = intersect(sub_x(:,1),sub_r(:,1));
                    sub_y(ia) = cell2mat(sub_r(ib,2));
                    sub_w = cell2mat(sub_x(:,end));
                    sub_w(isnan(sub_w)) = 0;
                    sub_w(sub_w<0) = 0;
                    sub_w = sub_w./sum(sub_w);
                    sub_re1 = sum(sub_y.*sub_w);
                    ia = strcmp(r_index(:,1),sub_t2);
                    sub_re2 = cell2mat(r_index(ia,2));
                    re{i}  = [sub_re1;sub_re2];
                    sprintf('%s %d-%d %s',key_str,i,T,index_name)
                end
                
                re = [re{:}]';
                if ~isempty(re)
                    re = num2cell(re(:,[ones(1,3),1:end]));
                    re(:,1) = tref;
                    re(:,2) = {index_name};
                    re(:,3) = {key_str};
                    datainsert_adair(tn,var_info,re);
                end
            end
            
        end
        function get_S34_signal()
            tn = 'S37.S34_signal';
            var_info = {'tradingdate','pool_name','method_name','symbol','w'};

            key_str = 'S34matlab优化';
            index_str = '000001-上证综指,000016-上证50,000905-中证500,000300-沪深300';
            temp = strsplit(index_str,',');
            index_info = cellfun(@(x) strsplit(x,'-'),temp,'UniformOutput',false);

            window = 125;
            t1 = '2012-01-01';
            t2 = datestr(now,'yyyy-mm-dd');
            symbol_pool_all = cellfun(@(x) x{1},index_info,'UniformOutput',false);
            symbol_pool_info = cellfun(@(x) x{2},index_info,'UniformOutput',false);
            T_symbol_pool_all = length(symbol_pool_all);
            sql_str_t0 = ['select tradingdate from %s where pool_name = ''%s'' ',...
                'and method_name = ''%s'' order by tradingdate desc limit 1'];
            for pool_id = 1:T_symbol_pool_all
                index_pool=symbol_pool_all{pool_id};
                index_name = symbol_pool_info{pool_id};
                t0 = fetchmysql(sprintf(sql_str_t0,tn,index_name,key_str),2);
                if isempty(t0)
                    t0 = {'1990-01-01'};
                end
                %%{                
                %日期
                sql_str_index = ['select tradeDate from yuqerdata.yq_index ',...
                            'where tradeDate >= ''%s'' and tradeDate<=''%s'' and ',...
                            'symbol = ''%s'' order by tradeDate ;'];
                y_index = fetchmysql(sprintf(sql_str_index,t1,t2,index_pool),2);
                if size(y_index,1)<window*2
                    continue
                end
                tref = yq_methods.get_tradingdate();
                %tref = yq_methods.get_tradingdate('2012-01-01','2019-04-02');
                %获取月底日期
                month_cut_date2 = yq_methods.get_month_end();
                [month_cut_date2,month_cut] = intersect(tref,month_cut_date2);
                month_cut = month_cut(month_cut>window);
                T = length(month_cut);
                re = cell(T,1);
                num0 = find(datenum(month_cut_date2)>datenum(t0),1);
                if isempty(num0)
                    num0 = T+1;
                end
                parfor i = num0:T
                    [wp,sub_symbol_pool,OK] = predict_weight_S34_update4(tref(1:month_cut(i)),window,index_pool);
                    if ~OK
                        ind = ~eq(wp,0);
                        symbol_sel1 = [sub_symbol_pool(ind,1),num2cell(wp(ind))];
                        temp = symbol_sel1(:,[1,1,1,1:end]);
                        temp(:,1) = tref(month_cut(i));
                        temp(:,2) = {index_name};
                        temp(:,3) = {key_str};
                        re{i} = temp';
                    end
                    sprintf('%s: %d-%d',key_str,i,T)
                end
                re = [re{:}]'; 
                if ~isempty(re)
                    datainsert_adair(tn,var_info,re);
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%
    end
end
function [wp,sub_symbol_pool,OK] = predict_weight_S34_update4(tref,window,index_pool)
    sql_str2 = ['select tradingdate from yuqerdata.IdxCloseWeightGet ',...
                'where tradingdate >= ''%s'' and ticker = ''%s''  order by tradingdate limit 1'];
    sql_str3 = ['select symbol,weight from yuqerdata.IdxCloseWeightGet ',...
            'where tradingdate = ''%s'' and ticker = ''%s'''];
    sql_str1= ['select tradingdate from yuqerdata.IdxCloseWeightGet ',...
            'where tradingdate < ''%s'' and ticker = ''%s'' order by tradingdate desc limit 1'];
    sub_t = fetchmysql(sprintf(sql_str1,tref{end},index_pool),2);
    if isempty(sub_t)
        sub_t = fetchmysql(sprintf(sql_str2,tref{1},index_pool),2);
    end
    if isempty(sub_t)
        wp=[];
        OK=true;
        sub_symbol_pool = [];
        return
    end
    sub_symbol_pool = fetchmysql(sprintf(sql_str3,sub_t{1},index_pool),2);

    tref = tref(end-window+1:end);
    %获取收益率数据
    sub_t1 = tref{1};
    sub_t2 = tref{end};
    [sub_r,~,sub_symbol_u] = get_interchgPct(sub_t1,sub_t2);
    X = zeros(size(sub_symbol_pool,1),length(tref));
    [~,ia,ib] = intersect(sub_symbol_pool(:,1),sub_symbol_u);
    X(ia,:) = sub_r(ib,:);
    %}
    %load temp_data
    %lamada = 0;
    max_w = 0.1;
    X = X';
    w0 = cell2mat(sub_symbol_pool(:,end));
    w0 = w0/sum(w0);
    r = X*w0;

    %lasso 弹性网选股步骤
    [b,FitInfo] = lasso(X,r,'CV',5,'Alpha',0.75);
    %[b,FitInfo] = lasso(X,r,'CV',5);
    wp = b(:,FitInfo.Index1SE);

    wp(wp<0) = 0;
    id = wp>0;
    %非线性优化步骤
    if ~(any(id))
        wp=[];
        OK=true;
    else
        X2 = X(:,id);    
        %f = 1/window*(r-X*w)+0.5*ones(1,index_num)*log(1+w/p)/log(1+0.2/p);
        fun = @(w) 1/window*sum((r-X2*w).^2);
        options = optimoptions('fmincon','Display','off');
        options.MaxFunctionEvaluations = 30000;
        warning('off')
        wp1 = fmincon(fun,w0(id),[],[],ones(1,sum(id)),1,zeros(sum(id),1),ones(sum(id),1)*max_w,[],options);
        wp(:) = 0;
        wp(id) = wp1;
        OK = false;
    end
end

function [sub_r,sub_t_u,sub_symbol_u] = get_interchgPct(sub_t1,sub_t2)

    sql_str = ['select symbol,tradeDate,chgPct from yuqerdata.yq_dayprice ',...
        'where tradeDate >= ''%s'' and tradeDate <=''%s'' and chgPct is not null order by tradeDate'];
    sub_x = fetchmysql(sprintf(sql_str,sub_t1,sub_t2),2);
    
    %[~,ia] = intersect(sub_x(:,1),sub_symbol_pool(:,1));
    %sub_x = sub_x(ia,:);
       
    %重组
    sub_t_u = unique(sub_x(:,2));
    sub_symbol_u = unique(sub_x(:,1));
    T_sub_t_u = length(sub_t_u);
    T_sub_symbol = length(sub_symbol_u);
    sub_r = zeros(T_sub_symbol,T_sub_t_u);
    for j = 1:T_sub_t_u
        sub_sub_x = sub_x(strcmp(sub_x(:,2),sub_t_u(j)),[1,3]);
        [~,ia,ib] = intersect(sub_symbol_u,sub_sub_x(:,1));
        sub_r(ia,j) = cell2mat(sub_sub_x(ib,2));
    end
end