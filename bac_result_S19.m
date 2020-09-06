%{
19
M2 全股票池建模预测 移动窗口
M-2 全股票池建模预测  固定窗口（0-50）

21
M2 全股票池建模预测 移动窗口
%}
classdef bac_result_S19 < handle
    properties
        group_num1 = 5
        group_info1
        method_name19 ={'LR','RF','LogiR','NB','XGB','SGD','XGB_R','gcf'};
        method_name21 ={'LR','RF','LogiR','NB','XGB','SGD','XGB_R'};
        index_pool19 = {'全市场','中证500','沪深300','中证500-M2','沪深300-M2','中证500-M-2','沪深300-M-2'};
        index_pool21 = {'全市场','中证500','沪深300','中证500-M2','沪深300-M2'};
        
    end
    methods
        function obj = bac_result_S19()
            obj.group_info1 = cell(obj.group_num1,1);
            for i = 1:obj.group_num1
                obj.group_info1{i} = sprintf('第%d组',i);
            end
        end
        function get_all_results(obj)
            obj.get_group_return(21)
            obj.get_group_return()
            obj.get_report()
            obj.get_report(21)
        end
    end
    methods
        function get_group_return(obj,method_id)
            if nargin < 2
                method_id = 19;
            end
            if eq(method_id,19)
                sub_index_pool = obj.index_pool19;
                method_name = obj.method_name19;
            else
                sub_index_pool = obj.index_pool21;
                method_name = obj.method_name21;
            end
            key_str = sprintf('S%d分组结果',method_id);
            tn = sprintf('S%d_result',method_id);
            tn2 = sprintf('S%d_signal',method_id);
            
            var_info = {'tradingdate','pool_name','method_name','f_val1','f_val2',...
                            'f_val3','f_va4','f_va5','f_f'};
            
            sql_str1 = 'select tradingdate from S37.%s where pool_name =''%s'' and method_name = ''%s'' order by tradingdate limit 1';
            sql_str2 = 'select symbol from S37.%s where pool_name=''%s'' and method_name = ''%s'' and tradingdate=''%s'' order by f_val';
            sql_str3 = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate =''%s''';
            sql_str4 = 'select distinct(tradingdate) from S37.%s where pool_name=''%s'' and method_name = ''%s'' order by tradingdate';
            
            for index_sel = 1:length(sub_index_pool)
                index_name = sub_index_pool{index_sel};
                factor_num = length(method_name);
                for i = 1:factor_num
                    sub_factor_name = method_name{i};
                    t0 = fetchmysql(sprintf(sql_str1,tn2,index_name,sub_factor_name),2);
                    t0 = t0{1};
                    tref_f = fetchmysql(sprintf(sql_str4,tn2,index_name,sub_factor_name),2);
                    tref_f_num = datenum(tref_f);

                    tref = yq_methods.get_tradingdate(t0);
                    tref_complete = 'select tradingdate from S37.%s where method_name = ''%s'' and pool_name = ''%s''';
                    tref_complete = fetchmysql(sprintf(tref_complete,tn,sub_factor_name,index_name),2);
                    tref = setdiff(tref,tref_complete);

                    T_tref = length(tref);
                    F = cell(T_tref);
                    parfor j = 1:T_tref
                        sub_t = tref{j};
                        ind = find(tref_f_num<datenum(sub_t),1,'last');
                        if isempty(ind)
                            r = zeros(1,obj.group_num1+1);
                        else
                            sub_t2 = tref_f{ind};%因子时间
                            f1 = fetchmysql(sprintf(sql_str2,tn2,index_name,sub_factor_name,sub_t2),2);
                            f1_y = ones(size(f1));
                            temp_L = length(f1_y)/obj.group_num1;
                            for k = 1:obj.group_num1
                                temp_1 = floor(temp_L*(k-1)+1);
                                if ~eq(k,obj.group_num1)
                                    temp_2 = floor(temp_L*k);
                                else
                                    temp_2 = length(f1);
                                end
                                f1_y(temp_1:temp_2) = k;

                            end
                            f1 =[f1,num2cell(f1_y)];
                            %这里需要修正
                            y1 = fetchmysql(sprintf(sql_str3,sub_t),2);                    
                            sub_r = obj.get_sub_group_return(f1,y1);
                            r = [sub_r,sub_r(:,end)-sub_r(:,1)];
                        end
                        f = num2cell(r(:,[1,1,1,1:end]));
                        f(:,1) = {sub_t};
                        f(:,2) = {index_name};
                        f(:,3) = {sub_factor_name};
                        F{j} = f';                    
                        sprintf('%s计算每日分组回测结果-%s %d-%d %d-%d %s',key_str,sub_t,j,T_tref,i,factor_num,index_name)
                    end 
                    F = [F{:}]';
                    if ~isempty(F)
                        sprintf('%s每日回测结果写入数据库%0.2d-%d',key_str,i,factor_num)
                        datainsert_adair(sprintf('S37.%s',tn),var_info,F)
                    end
                end
            end
        end
        function get_report(obj,method_id)  
            if nargin < 2
                method_id = 19;
            end
            if eq(method_id,19)
                sub_index_pool = obj.index_pool19;
                method_name = obj.method_name19;
            else
                sub_index_pool = obj.index_pool21;
                method_name = obj.method_name21;
            end
            
            key_str = sprintf('S%d分组结果',method_id);
            tn = sprintf('S%d_result',method_id);
            
            sql_str1 = 'select * from S37.%s where method_name=''%s'' order by tradingdate'; 
            
            file_name = sprintf('%s因子表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            factor_name = method_name;
            T_factor = length(factor_name); 
            T_index = length(sub_index_pool);
            sta_re = cell(T_factor,1);
            for i = 1:T_factor                
                sub_factor_name = factor_name{i};
                x = fetchmysql(sprintf(sql_str1,tn,sub_factor_name),2);
                sub_re = cell(1,T_index);
                for j = 1:T_index
                    sub_x = x(strcmp(x(:,2),sub_index_pool(j)),:);
                    tref = sub_x(:,1);
                    r_day = cell2mat(sub_x(:,4:end));
                    r_day = month_fee_update(tref,r_day);
                    title_str = sprintf('%s-%s-%s',key_str,sub_factor_name,sub_index_pool{j});
                    [h1,h2] = obj.draw_figure(tref,r_day,title_str);
                    obj_wd.pasteFigure(h1,' ');
                    obj_wd.pasteFigure(h2,' ');
                    [v0,v_str0] = curve_static(cumprod(1+r_day(:,end)));
                    [v,v_str] = obj.ad_trans_sta_info(v0,v_str0); 
                    sub_re{j} = [[{''};v_str'],[{title_str};v']];
                end
                sta_re{i} = [sub_re{:}];
            end
            obj_wd.CloseWord()
            
            sta_re = [sta_re{:}];
            sta_re = sta_re(:,[1,2:2:end])';
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re)            
        end
        
        function [h1,h2] = draw_figure(obj,tref,r_day,title_str)
            r_c = cumprod(1+r_day);
            t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref,'UniformOutput',false);
            
            T = length(t_str);
            h1=figure;

            plot(r_c(:,1:end-1),'-','LineWidth',2);
            set(gca,'xlim',[0,T]);
            set(gca,'XTick',floor(linspace(1,T,15)));
            set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(h1,[223,365,1345,420]);
            box off
            legend(obj.group_info1,'NumColumns',obj.group_num1,'Location','best');
            title(sprintf('%s 分组净值',title_str));

            h2=figure;
            bpcure_plot_updateV2(t_str,r_c(:,end))
            setpixelposition(gcf,[223,365,1345,420]);
            title(sprintf('%s 多空组合与回撤',title_str));
            
%             h3=figure;
%             bar(mean(r_day(:,1:end-1)))
%             setpixelposition(gcf,[223,365,1345,420]);
%             title(sprintf('%s 分组日均收益',title_str));
            
        end
        
    end
    methods(Static)
        function r = get_sub_group_return(f1,y1)
            [~,ia,ib] = intersect(f1(:,1),y1(:,1));
            m = size(f1,1);
            f = cell(size(f1));
            f(ia,:) = f1(ia,:);
            y = cell(m,2);
            y(ia,:) = y1(ib,:);
            f=cell2mat(f(:,2:end));
            y = cell2mat(y(:,end));
            
            max_num = max(f(:,1));
            r = zeros(1,max_num);
            for i = 1
                sub_f = f(:,i);
                sub_r = zeros(1,max_num);
                for j = 1:max_num
                    sub_r(j) = mean(y(eq(sub_f,j)));
                end
                r(i,:) = sub_r;
            end            
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
    end
    
end