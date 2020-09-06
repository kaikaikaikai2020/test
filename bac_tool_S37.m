%{
集成框架
20200623 升级 结果写入计算结果文件夹 便于检索
%}
classdef bac_tool_S37<handle
    properties
        
        group_return_tn
        group_return_var
        
        method_info=[]
        factor_info=[]
        
        factors_S36 = [];
        factors_S36_dir = -1*ones(1,13);
        factors_S36_info = [];
        symbol_pool_S36 = 'symbol_pool_S36'
        
        factors_S33 = [];
        factors_S33_dir = [1,-1,1,-1,1,-1,1,-1];
        factors_S33_info = [];
        symbol_pool_S33 = 'symbol_pool_S33'
        
        factors_S32 = [];
        factors_S32_dir = [-1,-1,1,1];
        factors_S32_info = [];
        symbol_pool_S32 = 'symbol_pool_S32'
        
        factors_S30 = [];
        factors_S30_dir = ones(1,6);
        factors_S30_info = {'HP','MA12','MA24','MA36','MA48','MA60'};
        symbol_pool_S30 = 'symbol_pool_S30'
        
        factors_S23 = [];
        factors_S23_dir
        factors_S23_info
        symbol_pool_S23 = 'symbol_pool_S23'
        
        factors_S23_1 = [];
        factors_S23_1_dir
        factors_S23_1_info
        symbol_pool_S23_1 = 'symbol_pool_S23_1'
        
        factors_S23_2 = [];
        factors_S23_2_dir
        factors_S23_2_info
        symbol_pool_S23_2 = 'symbol_pool_S23_2'
        
        factors_S22 = [];
        factors_S22_dir= [1,1,1];
        factors_S22_info = {'apb-1d','apb-5d','apb-1m'};
        symbol_pool_S22 = 'symbol_pool_S22' 
        
        factors_S45 = [];
        factors_S45_dir= [1,1,1];
        factors_S45_info = {'deg','ave','deg_x','ave_x','com2','degrev'};
        symbol_pool_S45 = 'symbol_pool_S45' 
        
        var_info_symbol = {'factor_name','tradingdate','symbol','id_a','id500','id300'};        
        symbol_pool_all = {   [],    '000905','000300'};
        symbol_pool_info = {'全市场','中证500','沪深300'};
        
        group_num1 = 5;
        group_info1
        group_num2 = 10;
        group_info2
    end
    methods
        function obj=bac_tool_S37()
            %S36
            obj.factors_S36=cell(13,1);
            obj.factors_S36_info=cell(13,1);
            for i = 1:13
                obj.factors_S36{i} = sprintf('S36f%0.2d',i);
                obj.factors_S36_info{i} = sprintf('因子%0.2d',i);
            end
            obj.factors_S36_info{6} = '文献1综合因子';
            obj.factors_S36_info{13} = '文献2综合因子';
            %S33
            tn_num_33 = 8;
            obj.factors_S33=cell(tn_num_33,1);
            obj.factors_S33_info=cell(tn_num_33,1);
            for i = 1:tn_num_33
                obj.factors_S33{i} = sprintf('S33f%0.2d',i);
                obj.factors_S33_info{i} = sprintf('因子%0.2d',i);
            end           
            %S32
            tn_num_32 = 4;
            obj.factors_S32=cell(tn_num_32,1);
            for i = 1:tn_num_32
                obj.factors_S32{i} = sprintf('S32f%0.2d',i);
            end  
            obj.factors_S32_info = {'理想反转','聪明钱','APM','S32综合因子'};
            %S30
            tn_num_30 = 6;
            obj.factors_S30=cell(tn_num_30,1);
            for i = 1:tn_num_30
                obj.factors_S30{i} = sprintf('S30f%0.2d',i);
            end
            %S23
            temp_info1 = {'买卖单Spread因子'};
            temp_dir1 = -1;
            temp_info2 = {'pareto买','pareto买_adj','pareto卖','pareto卖_adj'};
            temp_dir2 = [-1,-1,-1,-1];
            temp_info3 = strsplit('大买1,大卖1,大买卖差1,大买卖和1,大买2,大卖2,大买卖差2,大买卖和2,买单,卖单,买卖单差,买卖单和',',');
            temp_dir3 = ones(1,12);%因子方向
            temp_dir3([3,7,9,11]) = 1; 
            obj.factors_S23_info=[temp_info1,temp_info2,temp_info3];
            obj.factors_S23_dir = [temp_dir1,temp_dir2,temp_dir3];
            
            tn_num_23 = length(obj.factors_S23_info);
            obj.factors_S23=cell(tn_num_23,1);
            for i = 1:tn_num_23
                obj.factors_S23{i} = sprintf('S23f%0.2d',i);
            end
            %S23 未中性化
            obj.factors_S23_2_info = obj.factors_S23_info;
            obj.factors_S23_2_dir = obj.factors_S23_dir;
            tn_num_23_2 = length(obj.factors_S23_2_info);
            obj.factors_S23_2=cell(tn_num_23_2,1);
            for i = 1:tn_num_23_2
                obj.factors_S23_2{i} = sprintf('S23_2f%0.2d',i);
            end            
            %S23_1
            com_num = nchoosek(1:7,2);
            com_strS = cell(size(com_num(:,1)'));
            com_strB = com_strS;
            for i = 1:size(com_num,1)
                com_strB{i} = sprintf('Bf_val%d%d',com_num(i,1),com_num(i,2));
                com_strS{i} = sprintf('Sf_val%d%d',com_num(i,1),com_num(i,2));
            end
            obj.factors_S23_1_info = [com_strB,com_strS];
            obj.factors_S23_1_dir = -ones(size(obj.factors_S23_1_info));
            tn_num_23_1 = length(obj.factors_S23_1_info);
            obj.factors_S23_1=cell(tn_num_23_1,1);
            for i = 1:tn_num_23_1
                obj.factors_S23_1{i} = sprintf('S23_1f%0.2d',i);
            end
            %S22
            tn_num_22 = length(obj.factors_S22_info);
            obj.factors_S22=cell(tn_num_22,1);
            for i = 1:tn_num_22
                obj.factors_S22{i} = sprintf('S22f%0.2d',i);
            end
            
            obj.group_return_tn{1}= 'factor_group5_return';
            obj.group_return_var{1}= {'factor_name','tradingdate','id_pool','f_val1','f_val2',...
                'f_val3','f_va4','f_va5','f_f'};
            obj.group_return_tn{2} = 'factor_group10_return';
            obj.group_return_var{2} = {'factor_name','tradingdate','id_pool','f_val1','f_val2',...
                'f_val3','f_va4','f_va5','f_va6','f_va7','f_va8','f_va9','f_va10','f_f'};
            obj.group_info1 = cell(obj.group_num1,1);
            for i = 1:obj.group_num1
                obj.group_info1{i} = sprintf('第%d组',i);
            end
            obj.group_info2 = cell(obj.group_num2,1);
            for i = 1:obj.group_num2
                obj.group_info2{i} = sprintf('第%d组',i);
            end
        end
        
        function write_S36_report(obj)
            sql_str1 = 'select * from S37.factor_group5_return where factor_name=''%s'' order by tradingdate'; 
            
            file_name = sprintf('S36因子表现%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            sta_re = cell(13,1);
            for i = 1:13
                sub_factor_name = obj.factors_S36{i};
                x = fetchmysql(sprintf(sql_str1,sub_factor_name),2);
                sub_re = cell(1,3);
                for j = 1:3
                    sub_x = x(strcmp(x(:,3),obj.symbol_pool_info(j)),:);
                    tref = sub_x(:,2);
                    r_day = cell2mat(sub_x(:,4:end));
                    title_str = sprintf('%s-%s',obj.factors_S36_info{i},obj.symbol_pool_info{j});
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
        function write_S33_report(obj)
            key_str = 'S33';
            factor_name = obj.factors_S33;
            factor_info_S33 = obj.factors_S33_info;
            obj.get_report(key_str,factor_name,factor_info_S33)
        end
        function write_S32_report(obj)
            key_str = 'S32';
            factor_name = obj.factors_S32;
            f_factor_info = obj.factors_S32_info;
            obj.get_report(key_str,factor_name,f_factor_info)
        end
        function write_S30_report(obj)
            key_str = 'S30';
            factor_name = obj.factors_S30;
            f_factor_info = obj.factors_S30_info;
            obj.get_report(key_str,factor_name,f_factor_info)
        end
        function write_S23_report(obj)
            key_str = 'S23';
            factor_name = obj.factors_S23;
            f_factor_info = obj.factors_S23_info;
            obj.get_report(key_str,factor_name,f_factor_info)
        end
        function write_S23_1_report(obj)
            key_str = 'S23_1';
            factor_name = obj.factors_S23_1;
            f_factor_info = obj.factors_S23_1_info;
            obj.get_report(key_str,factor_name,f_factor_info)
        end
        function write_S23_2_report(obj)
            key_str = 'S23_2';
            factor_name = obj.factors_S23_2;
            f_factor_info = obj.factors_S23_2_info;
            obj.get_report(key_str,factor_name,f_factor_info)
        end
        function write_S22_report(obj)
            key_str = 'S22';
            factor_name = obj.factors_S22;
            f_factor_info = obj.factors_S22_info;
            obj.get_report(key_str,factor_name,f_factor_info)
        end        
        function get_report(obj,key_str,factor_name,f_factor_info)           
            
            sql_str1 = 'select * from S37.factor_group5_return where factor_name=''%s'' order by tradingdate'; 
            
            file_name = sprintf('%s因子表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            T_factor = length(factor_name);
            
            sta_re = cell(T_factor,1);
            for i = 1:T_factor
                sub_factor_name = factor_name{i};
                x = fetchmysql(sprintf(sql_str1,sub_factor_name),2);
                sub_re = cell(1,3);
                for j = 1:3
                    sub_x = x(strcmp(x(:,3),obj.symbol_pool_info(j)),:);
                    tref = sub_x(:,2);
                    r_day = cell2mat(sub_x(:,4:end));
                    %需要添加手续费判断
                    r_day = month_fee_update(tref,r_day);
                    title_str = sprintf('%s-%s',f_factor_info{i},obj.symbol_pool_info{j});
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
        
        function create_tables_S37(obj)            
            obj.create_symbol_pool_table(obj.symbol_pool_S36);
            obj.create_symbol_pool_table(obj.symbol_pool_S33);
            obj.create_symbol_pool_table(obj.symbol_pool_S32);
            obj.create_symbol_pool_table(obj.symbol_pool_S30);
            obj.create_symbol_pool_table(obj.symbol_pool_S23);
            obj.create_symbol_pool_table(obj.symbol_pool_S23_1);
            obj.create_symbol_pool_table(obj.symbol_pool_S23_2);
            obj.create_symbol_pool_table(obj.symbol_pool_S22);
        end
        function get_group_return_S36(obj)            
            sql_str1 = 'select tradingdate from S37.%s where factor_name=''%s'' order by tradingdate limit 1';
            sql_str2 = 'select symbol,id_a,id500,id300 from S37.%s where factor_name=''%s'' and tradingdate=''%s''';
            sql_str3 = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate =''%s''';
            sql_str4 = 'select distinct(tradingdate) from S37.%s where factor_name=''%s'' order by tradingdate';
            for i = 1:13
                sub_factor_name = obj.factors_S36{i};
                sub_tn = obj.symbol_pool_S36;
                t0 = fetchmysql(sprintf(sql_str1,sub_tn,sub_factor_name),2);
                t0 = t0{1};
                tref_f = fetchmysql(sprintf(sql_str4,sub_tn,sub_factor_name),2);
                tref_f_num = datenum(tref_f);
                
                tref = yq_methods.get_tradingdate(t0);
                tref_complete = 'select tradingdate from S37.%s where factor_name = ''%s'' and id_pool = ''全市场''';
                tref_complete = fetchmysql(sprintf(tref_complete,obj.group_return_tn{1},sub_factor_name),2);
                tref = setdiff(tref,tref_complete);
                
                T_tref = length(tref);
                parfor j = 1:T_tref
                    sub_t = tref{j};
                    ind = find(tref_f_num<datenum(sub_t),1,'last');
                    if isempty(ind)
                        r = zeros(3,obj.group_num1+1);
                    else
                        sub_t2 = tref_f{ind};%因子时间
                        f1 = fetchmysql(sprintf(sql_str2,sub_tn,sub_factor_name,sub_t2),2);
                        %这里需要修正
                        y1 = fetchmysql(sprintf(sql_str3,sub_t),2);                    
                        sub_r = obj.get_sub_group_return(f1,y1);
                        r = [sub_r,(sub_r(:,end)-sub_r(:,1)).*obj.factors_S36_dir(i)];
                    end
                    f = num2cell(r(:,[1,1,1,1:end]));
                    f(:,1) = {sub_factor_name};
                    f(:,2) = {sub_t};
                    f(:,3) = obj.symbol_pool_info';
                    datainsert_adair(sprintf('S37.%s',obj.group_return_tn{1}),obj.group_return_var{1},f)
                    sprintf('S37每日回测结果写入数据库-%s %d-%d %d-%d',sub_t,j,T_tref,i,13)
                end 
            end
        end
        %%%S33
        function get_group_return_S33(obj) 
            key_str = 'S33';
            factor_name = obj.factors_S33;
            tn_all = obj.symbol_pool_S33;
            factor_num = 8;
            factor_dir = obj.factors_S33_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        %%%S32
        function get_group_return_S32(obj) 
            key_str = 'S32';
            factor_name = obj.factors_S32;
            tn_all = obj.symbol_pool_S32;
            factor_num = 4;
            factor_dir = obj.factors_S32_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        %S30
        function get_group_return_S30(obj) 
            key_str = 'S30';
            factor_name = obj.factors_S30;
            tn_all = obj.symbol_pool_S30;
            factor_num = 6;
            factor_dir = obj.factors_S30_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        function get_group_return_S23(obj) 
            key_str = 'S23';
            factor_name = obj.factors_S23;
            tn_all = obj.symbol_pool_S23;
            factor_num = length(obj.factors_S23_dir);
            factor_dir = obj.factors_S23_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        function get_group_return_S23_2(obj) 
            key_str = 'S23_2';
            factor_name = obj.factors_S23_2;
            tn_all = obj.symbol_pool_S23_2;
            factor_num = length(obj.factors_S23_2_dir);
            factor_dir = obj.factors_S23_2_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        function get_group_return_S23_1(obj) 
            key_str = 'S23_1';
            factor_name = obj.factors_S23_1;
            tn_all = obj.symbol_pool_S23_1;
            factor_num = length(obj.factors_S23_1_dir);
            factor_dir = obj.factors_S23_1_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        function get_group_return_S22(obj) 
            key_str = 'S22';
            factor_name = obj.factors_S22;
            tn_all = obj.symbol_pool_S22;
            factor_num = length(obj.factors_S22_dir);
            factor_dir = obj.factors_S22_dir;
            obj.get_group_return(key_str,factor_name,tn_all,factor_num,factor_dir);
        end
        function get_group_return(obj,key_str,factor_name,tn_all,factor_num,factor_dir)
            %factor_name = obj.factors_S33;
            %tn_all = obj.symbol_pool_S33
            %factor_num = 8
            %factor_dir = obj.factors_S33_dir
            sql_str1 = 'select tradingdate from S37.%s where factor_name=''%s'' order by tradingdate limit 1';
            sql_str2 = 'select symbol,id_a,id500,id300 from S37.%s where factor_name=''%s'' and tradingdate=''%s''';
            sql_str3 = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate =''%s''';
            sql_str4 = 'select distinct(tradingdate) from S37.%s where factor_name=''%s'' order by tradingdate';
            for i = 1:factor_num
                sub_factor_name = factor_name{i};
                sub_tn = tn_all;
                t0 = fetchmysql(sprintf(sql_str1,sub_tn,sub_factor_name),2);
                t0 = t0{1};
                tref_f = fetchmysql(sprintf(sql_str4,sub_tn,sub_factor_name),2);
                tref_f_num = datenum(tref_f);
                
                tref = yq_methods.get_tradingdate(t0);
                tref_complete = 'select tradingdate from S37.%s where factor_name = ''%s'' and id_pool = ''全市场''';
                tref_complete = fetchmysql(sprintf(tref_complete,obj.group_return_tn{1},sub_factor_name),2);
                tref = setdiff(tref,tref_complete);
                
                T_tref = length(tref);
                F = cell(T_tref);
                parfor j = 1:T_tref
                    sub_t = tref{j};
                    ind = find(tref_f_num<datenum(sub_t),1,'last');
                    if isempty(ind)
                        r = zeros(3,obj.group_num1+1);
                    else
                        sub_t2 = tref_f{ind};%因子时间
                        f1 = fetchmysql(sprintf(sql_str2,sub_tn,sub_factor_name,sub_t2),2);
                        %这里需要修正
                        y1 = fetchmysql(sprintf(sql_str3,sub_t),2);                    
                        sub_r = obj.get_sub_group_return(f1,y1);
                        r = [sub_r,(sub_r(:,end)-sub_r(:,1)).*factor_dir(i)];
                    end
                    f = num2cell(r(:,[1,1,1,1:end]));
                    f(:,1) = {sub_factor_name};
                    f(:,2) = {sub_t};
                    f(:,3) = obj.symbol_pool_info';
                    F{j} = f';                    
                    sprintf('%s计算每日分组回测结果-%s %d-%d %d-%d',key_str,sub_t,j,T_tref,i,factor_num)
                end 
                F = [F{:}]';
                sprintf('%s每日回测结果写入数据库%0.2d-%d',key_str,i,factor_num)
                if ~isempty(F)
                    datainsert_adair(sprintf('S37.%s',obj.group_return_tn{1}),obj.group_return_var{1},F)
                end
            end
            
        end
        %%%
        function select_symbols_S36(obj)
            tref_month = yq_methods.get_month_end();
            sql_str = 'select distinct(tradingdate) from S36.factor_comS36 where f_type = %d';
            sql_str_t0='select distinct(tradingdate) from S37.%s where factor_name=''%s''';
            for i = 1:13
                tref = fetchmysql(sprintf(sql_str,i),2);
                tref = intersect(tref_month,tref);
                
                tref_complete = fetchmysql(sprintf(sql_str_t0,obj.symbol_pool_S36,obj.factors_S36{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S36_get_symbol(i,sub_t);
                    datainsert_adair(sprintf('S37.%s',obj.symbol_pool_S36),obj.var_info_symbol,f)
                    sprintf('S36因子%0.2d-%s选股结果写入数据库',i,sub_t)                    
                end                
            end
        end
        
        function select_symbols_S22(obj)
            key_str = 'S22';
            tn_result = sprintf('S37.%s',obj.symbol_pool_S22);
            f_factor_name = obj.factors_S22;
            
            tref_month = yq_methods.get_month_end();
            tN_all = {'S22.s22_factor_apb_1d','S22.s22_factor_apb_5d','S22.s22_factor_apb_month'};           
            sql_str = 'select distinct(tradingdate) from %s where tradingdate>=''2009-01-01''';
            sql_str_t0='select distinct(tradingdate) from %s where factor_name=''%s''';
            for i = 1:length(tN_all)   
                tref = fetchmysql(sprintf(sql_str,tN_all{i}),2);
                tref = intersect(tref_month,tref);
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,f_factor_name{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S22_get_symbol(i,sub_t);
                    datainsert_adair(tn_result,obj.var_info_symbol,f)
                    sprintf('%s因子%0.2d-%d-%s选股结果写入数据库',key_str,i,T_tref_do,sub_t)                    
                end                
            end
        end
        function F = get_S22_get_symbol(obj,f_id,sub_t) 
            f_factor_name=obj.factors_S22(f_id);
            tN_all = {'S22.s22_factor_apb_1d','S22.s22_factor_apb_5d','S22.s22_factor_apb_month'}; 
            
            sql_str = 'select symbol,f_val from %s where tradingdate=''%s''';
            x0 = fetchmysql(sprintf(sql_str,tN_all{f_id},sub_t),2); 
            x0(cellfun(@isnan,x0(:,end)),:) = [];

            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = obj.nero_test_ty(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = f_factor_name;
            F(:,2) = {sub_t};
        end
        function select_symbols_S23_1(obj)
            key_str = 'S23_1';
            tn_result = sprintf('S37.%s',obj.symbol_pool_S23_1);
            f_factor_name = obj.factors_S23_1;
            
            tref_month = yq_methods.get_month_end();
            tN_all = repmat({'S23.zhubifactor_volumeratio'},1,length(obj.factors_S23_1_dir));           
            sql_str = 'select distinct(tradingdate) from %s where tradingdate>=''2009-01-01''';
            sql_str_t0='select distinct(tradingdate) from %s where factor_name=''%s''';
            for i = 1:length(tN_all)   
                tref = fetchmysql(sprintf(sql_str,tN_all{i}),2);
                tref = intersect(tref_month,tref);
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,f_factor_name{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S23_1_get_symbol(i,sub_t);
                    datainsert_adair(tn_result,obj.var_info_symbol,f)
                    sprintf('%s因子%0.2d-%d-%s选股结果写入数据库',key_str,i,T_tref_do,sub_t)                    
                end                
            end
        end
        
        function F = get_S23_1_get_symbol(obj,f_id,sub_t) 
            f_factor_name=obj.factors_S23_1(f_id);
            tN_all = repmat({'S23.zhubifactor_volumeratio'},1,length(obj.factors_S23_1_dir));
            f_names = obj.factors_S23_1_info;
            
            sql_str = 'select symbol,%s from %s where tradingdate=''%s''';
            x0 = fetchmysql(sprintf(sql_str,f_names{f_id},tN_all{f_id},sub_t),2); 
            x0(cellfun(@isnan,x0(:,end)),:) = [];

            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = obj.nero_test_ty(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = f_factor_name;
            F(:,2) = {sub_t};
        end
                
        function select_symbols_S23(obj)
            key_str = 'S23';
            tn_result = sprintf('S37.%s',obj.symbol_pool_S23);
            f_factor_name = obj.factors_S23;
            tref_month = yq_methods.get_month_end();
            tN_all = [{'S23.fenbifactor1_month'},repmat({'S23.zhubifactor_pareto'},1,4)...
                repmat({'S23.zhubifactor_volumebig'},1,12)];
%             f_names = {'f_val','Bf_val','Bf_val_adj','Sf_val','Sf_val_adj',...
%                 'BB1','BS1','minus_BS1','sum_BS1','BB2','BS2','minus_BS2',...
%                 'sum_BS2','focus_B','focus_S','minus_fBS','sum_fBS'};
            
            sql_str = 'select distinct(tradingdate) from %s';
            sql_str_t0='select distinct(tradingdate) from %s where factor_name=''%s''';
            for i = 1:length(tN_all)   
                tref = fetchmysql(sprintf(sql_str,tN_all{i}),2);
                tref = intersect(tref_month,tref);
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,f_factor_name{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S23_get_symbol(i,sub_t);
                    datainsert_adair(tn_result,obj.var_info_symbol,f)
                    sprintf('%s因子%0.2d-%s选股结果写入数据库',key_str,i,sub_t)                    
                end                
            end
        end
        
        function select_symbols_S23_2(obj)
            key_str = 'S23_2';
            tn_result = sprintf('S37.%s',obj.symbol_pool_S23_2);
            f_factor_name = obj.factors_S23_2;
            tref_month = yq_methods.get_month_end();
            tN_all = [{'S23.fenbifactor1_month'},repmat({'S23.zhubifactor_pareto'},1,4)...
                repmat({'S23.zhubifactor_volumebig'},1,12)];
%             f_names = {'f_val','Bf_val','Bf_val_adj','Sf_val','Sf_val_adj',...
%                 'BB1','BS1','minus_BS1','sum_BS1','BB2','BS2','minus_BS2',...
%                 'sum_BS2','focus_B','focus_S','minus_fBS','sum_fBS'};
            
            sql_str = 'select distinct(tradingdate) from %s';
            sql_str_t0='select distinct(tradingdate) from %s where factor_name=''%s''';
            for i = 1:length(tN_all)   
                tref = fetchmysql(sprintf(sql_str,tN_all{i}),2);
                tref = intersect(tref_month,tref);
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,f_factor_name{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S23_2_get_symbol(i,sub_t);
                    datainsert_adair(tn_result,obj.var_info_symbol,f)
                    sprintf('%s因子%0.2d-%s选股结果写入数据库',key_str,i,sub_t)                    
                end                
            end
        end
        function F = get_S23_2_get_symbol(obj,f_id,sub_t) 
            f_factor_name=obj.factors_S23_2(f_id);
            tN_all = [{'S23.fenbifactor1_month'},repmat({'S23.zhubifactor_pareto'},1,4)...
                         repmat({'S23.zhubifactor_volumebig'},1,12)];
            f_names = {'f_val','Bf_val','Bf_val_adj','Sf_val','Sf_val_adj',...
                'BB1','BS1','minus_BS1','sum_BS1','BB2','BS2','minus_BS2',...
                'sum_BS2','focus_B','focus_S','minus_fBS','sum_fBS'};
            
            sql_str = 'select symbol,%s from %s where tradingdate=''%s''';
            x0 = fetchmysql(sprintf(sql_str,f_names{f_id},tN_all{f_id},sub_t),2); 

            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                %去掉中性化
                %x = obj.nero_test_ty(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = f_factor_name;
            F(:,2) = {sub_t};
        end
        
        function F = get_S23_get_symbol(obj,f_id,sub_t) 
            f_factor_name=obj.factors_S23(f_id);
            tN_all = [{'S23.fenbifactor1_month'},repmat({'S23.zhubifactor_pareto'},1,4)...
                         repmat({'S23.zhubifactor_volumebig'},1,12)];
            f_names = {'f_val','Bf_val','Bf_val_adj','Sf_val','Sf_val_adj',...
                'BB1','BS1','minus_BS1','sum_BS1','BB2','BS2','minus_BS2',...
                'sum_BS2','focus_B','focus_S','minus_fBS','sum_fBS'};
            
            sql_str = 'select symbol,%s from %s where tradingdate=''%s''';
            x0 = fetchmysql(sprintf(sql_str,f_names{f_id},tN_all{f_id},sub_t),2); 

            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = obj.nero_test_ty(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = f_factor_name;
            F(:,2) = {sub_t};
        end
        
        function select_symbols_S30(obj)
            key_str = 'S30';
            tn_result = sprintf('S37.%s',obj.symbol_pool_S30);
            f_factor_name = obj.factors_S30;
            tref_month = yq_methods.get_month_end();
            
            tN_all = ['S30.F_month_final_adj',repmat({'S30.F_month_final_adj_avg'},1,5)];
            sql_str = 'select distinct(tradingdate) from %s';
            sql_str_w = 'select distinct(tradingdate) from %s where w = %d';
            sql_str_t0='select distinct(tradingdate) from %s where factor_name=''%s''';
            for i = 1:length(tN_all)   
                if eq(i,1)
                    tref = fetchmysql(sprintf(sql_str,tN_all{i}),2);
                else
                    tref = fetchmysql(sprintf(sql_str_w,tN_all{i},i-1),2);
                end
                tref = intersect(tref_month,tref);
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,f_factor_name{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S30_get_symbol(i,sub_t);
                    datainsert_adair(tn_result,obj.var_info_symbol,f)
                    sprintf('%s因子%0.2d-%s选股结果写入数据库',key_str,i,sub_t)                    
                end                
            end
        end
        function F = get_S30_get_symbol(obj,f_id,sub_t) 
            f_factor_name=obj.factors_S30(f_id);
            tN_all = ['S30.F_month_final_adj',repmat({'S30.F_month_final_adj_avg'},1,5)];
            sql_str = 'select symbol,f_val from %s where tradingdate=''%s''';
            sql_str_w = 'select symbol,f_val from %s where tradingdate=''%s'' and w = %d';
            if f_id>1
                x0 = fetchmysql(sprintf(sql_str_w,tN_all{f_id},sub_t,f_id-1),2); 
            else
                x0 = fetchmysql(sprintf(sql_str,tN_all{f_id},sub_t),2); 
            end
            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = obj.nero_test_ty(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = f_factor_name;
            F(:,2) = {sub_t};
        end
        
        function select_symbols_S32(obj)
            key_str = 'S32';
            tn_result = sprintf('S37.%s',obj.symbol_pool_S32);
            tref_month = yq_methods.get_month_end();
            tN_all = {'S32.s32_factor_inverse','S32.factor_q','S32.factor_apm','S32.com_factor'};
            sql_str = 'select distinct(tradingdate) from %s  where tradingdate>=''2013-06-28''';
            sql_str_t0='select distinct(tradingdate) from %s where factor_name=''%s''';
            for i = 1:4   
                tref = fetchmysql(sprintf(sql_str,tN_all{i}),2);
                tref = intersect(tref_month,tref);
                tref_complete = fetchmysql(sprintf(sql_str_t0,tn_result,obj.factors_S32{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S32_get_symbol(i,sub_t);
                    datainsert_adair(tn_result,obj.var_info_symbol,f)
                    sprintf('%s因子%0.2d-%s选股结果写入数据库',key_str,i,sub_t)                    
                end                
            end
        end
        function F = get_S32_get_symbol(obj,f_id,sub_t) 
            
            tN_all = {'S32.s32_factor_inverse','S32.factor_q','S32.factor_apm','S32.com_factor'};
            sql_str = 'select symbol,f_val from %s where tradingdate=''%s''';
            x0 = fetchmysql(sprintf(sql_str,tN_all{f_id},sub_t),2); 
            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = obj.nero_test_ty(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = obj.factors_S32(f_id);
            F(:,2) = {sub_t};
        end
        
        function select_symbols_S33(obj)
            tref_month = yq_methods.get_month_end();
            
            sql_str = 'select distinct(tradingdate) from S33.factor_cvar_month';
            tref = fetchmysql(sql_str,2);
            tref = intersect(tref_month,tref);
            sql_str_t0='select distinct(tradingdate) from S37.%s where factor_name=''%s''';
            for i = 1:8   
                tref_complete = fetchmysql(sprintf(sql_str_t0,obj.symbol_pool_S33,obj.factors_S33{i}),2);
                tref_do = setdiff(tref,tref_complete);
                
                T_tref_do = length(tref_do);
                parfor j = 1:T_tref_do
                    %get symbol
                    sub_t = tref_do{j};
                    f = obj.get_S33_get_symbol(i,sub_t);
                    datainsert_adair(sprintf('S37.%s',obj.symbol_pool_S33),obj.var_info_symbol,f)
                    sprintf('S33因子%0.2d-%s选股结果写入数据库',i,sub_t)                    
                end                
            end
        end
        function F = get_S33_get_symbol(obj,f_id,sub_t) 
            
            f_id_pool = [1,2,3,4,1,2,3,4];
            tN_all = {'S33.factor_cvar_month','S33.factor_cvar_month_v2'};
            tN_all = tN_all([ones(1,4),ones(1,4)*2]);
            sql_str = 'select symbol,f_val%d from %s where tradingdate=''%s''';
            x0 = fetchmysql(sprintf(sql_str,f_id_pool(f_id),tN_all{f_id},sub_t),2); 
            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = S33_nero_test(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = obj.factors_S33(f_id);
            F(:,2) = {sub_t};
        end
        
        function F = get_S36_get_symbol(obj,f_id,sub_t) 
            x0 = obj.get_S36_factor(f_id,sub_t);
            X =x0(:,[1,1,1,1]);
            X(:,2:end) = {0};
            for i = 1:length(obj.symbol_pool_info)
                sub_index = obj.symbol_pool_all{i};
                if ~isempty(sub_index)
                    sub_symbol_pool = yq_methods.get_index_pool(sub_index,sub_t);
                    [~,ia1] = intersect(x0(:,1),sub_symbol_pool);
                    x = x0(ia1,:);
                else
                    x = x0;
                end
                x = S36_nero_test(x,sub_t);
                y= obj.get_cut_group(x,1);
                [~,ia,ib] = intersect(X(:,1),x(:,1));
                X(ia,i+1) = num2cell(y(ib));
            end
            F = X(:,[1,1,1:end]);
            F(:,1) = obj.factors_S36(f_id);
            F(:,2) = {sub_t};
        end
        
        function y=get_cut_group(obj,x,mode1)
            if nargin < 3
                mode1=1;
            end
            if eq(mode1,1)
                g_num = obj.group_num1;
            else
                g_num = obj.group_num2;
            end
            
            [~,ia] = sort(cell2mat(x(:,end)));
            y = zeros(size(ia));
            sub_num = floor(length(ia)/g_num);
            for j = 1:g_num
                if ~eq(j,g_num)
                    sub_w = (j-1)*sub_num+1:j*sub_num;
                else
                    sub_w = (j-1)*sub_num+1:length(ia);
                end
                y(ia(sub_w))=j;
            end
        end
        
        function create_symbol_pool_table(obj,tn)
            dN= 'S37';            
            %因子名称，时间，代码，排序
            var_info = obj.var_info_symbol;
            var_type = cell(size(var_info));
            var_type(:) = {'int'};
            var_type(1:3) = {'varchar(20)','date','varchar(6)'};
            %key_var = {'symbol','tradingdate'};
            key_var = strjoin(var_info([1,2,3]),',');
            %key_var = var_info{1};
            create_table_adair(dN,tn,var_info,var_type,key_var)
        end
        function create_group_return_result_table(obj)
            dN = 'S37';
            for i = 1:2
                tn = obj.group_return_tn{i};
                var_info = obj.group_return_var{i};
                var_type = cell(size(var_info));
                var_type(:) = {'float'};
                var_type(1:3) = {'varchar(20)','date','varchar(8)'};
                %key_var = {'symbol','tradingdate'};
                key_var = strjoin(var_info([1,2,3]),',');
                %key_var = var_info{1};
                create_table_adair(dN,tn,var_info,var_type,key_var)
            end
            
            
        end
        
    end
    methods(Static)
        
        function f = get_S36_factor(f_type,t)
            sql_str = 'select symbol,f_val from S36.factor_comS36 where f_type = %d and tradingdate=''%s''';
            f = fetchmysql(sprintf(sql_str,f_type,t),2);            
        end
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
            r = zeros(3,max_num);
            for i = 1:3
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
        %中性化一般方法 只有市值和行业
        function x1 =nero_test_ty(x1,t_str)
            window1 = 180;%33原本是60天，为了和S36统一，使用了180
            %上市时间
            sql_str4 = ['select ticker,listDate from yuqerdata.equget where listStatusCd !=''UN''',...
                            'and listDate is not null'];
            sql_str6 = 'select symbol,log(negMarketValue) from yuqerdata.yq_dayprice where tradeDate = ''%s''';
            symbol_info = fetchmysql(sql_str4,2);
            symbol_listdate = datenum(symbol_info(:,2));
            sql_str3 = 'select ticker from   yuqerdata.st_info where tradedate =''%s''';
            %st
            st = fetchmysql(sprintf(sql_str3,t_str),2);
            st = cellfun(@str2double,st,'UniformOutput',false);
            st = cellfun(@(x) sprintf('%0.6d',x),st,'UniformOutput',false);
            [~,ia] = intersect(x1(:,1),st);
            x1(ia,:) = [];
            %新股
            ind = datenum(t_str)-symbol_listdate>window1;
            [~,ia] = intersect(x1(:,1),symbol_info(ind,1));
            x1 = x1(ia,:);

            %中性化
            %sub_f_ner = get_ner_dataS36(t_str);
            sub_f_ner = fetchmysql(sprintf(sql_str6,t_str),2);
            %industry code
            x_indus = yq_methods.get_industry_class_2(t_str);
            inds = suscc_intersect({x1(:,1),sub_f_ner(:,1),x_indus(:,1)});
            x1 = x1(inds(:,1),:);
            sub_f_ner=sub_f_ner(inds(:,2),:);
            x_indus = x_indus(inds(:,3),:);

            x1_v = cell2mat(x1(:,2));
            sub_f_ner_v = cell2mat(sub_f_ner(:,2:end));
            x_indus_v = cell2mat(x_indus(:,2));        
            dummy_f = yq_methods.trans_dummy(x_indus_v(:,end));        
            %regress
            %[~,~,x1_v] = regress(x1_v,[ones(size(x1_v)),sub_f_ner_v,dummy_f]);
            warning off
            [~,~,x1_v] = regress(x1_v,[ones(size(x1_v)),sub_f_ner_v(:,end),dummy_f]); 
            warning on
            x1 = [x1(:,1),num2cell(x1_v)];
        end
        %
        function write_S26_report()
            tn = 'S37.S26_bac';
            var_info = {'tradingdate','y1','y2','y3'};

            sql_str = 'SELECT tradedate,closeindex FROM yuqerdata.yq_index where symbol = ''399102'' and tradedate>=''2010-01-01'' order by tradedate';
            x_1 = fetchmysql(sql_str,2);
            tref_num = datenum(x_1(:,1));
            ind = tref_num>=datenum(2011,1,1);
            tref_num = tref_num(ind);
            tref = x_1(ind,1);
            index1 = cell2mat(x_1(ind,2));

            T = length(tref);
            y1 = zeros(T,1);
            y2 = y1;
            sql_str = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradedate=''%s'' and chgPct is not null';

            key_symbol = [];
            ind = [1,2,4,7,8,10];
            sql_str1 = 'select symbol from S26.S26_result where rule_name = %d order by tradingdate';
            for i = 1:length(ind)    
                key_symbol = cat(1,key_symbol,fetchmysql(sprintf(sql_str1,ind(i)),2));
            end
            key_symbol = unique(key_symbol);

            x0 = fetchmysql(sprintf('select * from %s order by tradingdate',tn),2);
            if isempty(x0)
                t0 = '2001-01-01';
            else
                t0 = x0{end,1};
            end
            num0 = find(strcmp(tref,t0));
            if isempty(num0)
                num0 = 0;
            end
            parfor i = num0+1:T
                sub_x = fetchmysql(sprintf(sql_str,tref{i}),2);
                sub_y = cell2mat(sub_x(:,2));
                y1(i) = mean(sub_y);
                [~,ia] = intersect(sub_x(:,1),key_symbol);
                y2(i) = mean(sub_y(ia));
                sprintf('%d-%d',i,T)
            end

            re = [tref,num2cell([index1,y1,y2])];
            re = re(num0+1:end,:);
            if ~isempty(re)
                datainsert_adair(tn,var_info,re)
            end

            re = [x0;re];

            index1 = cell2mat(re(:,2));
            y1 =cell2mat(re(:,3));
            y2 = cell2mat(re(:,4));

            h = figure;
            plot(tref_num,[index1/index1(1),cumprod(1+[y2,y1])],'LineWidth',2)
            datetick('x','yymm')
            legend({'yqer全A','财务风险组合','创业板综'},'NumColumns',3)
            title('组合—update');
            setpixelposition(gcf,[430,368,1008,420]);
            file_name = sprintf('S31风险股市场表现%s',datestr(now,'yyyy-mm-dd'));
            obj_wd = wordcom(fullfile(pwd,sprintf('%s.doc',file_name)));  
            obj_wd.pasteFigure(h,'S31风险股市场表现');
            obj_wd.CloseWord()  
        end
    end
    
    
end