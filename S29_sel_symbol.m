classdef S29_sel_symbol<handle
    properties
        x_st_symbol
        x_st_date0
        x_st_date1
        F_all
    end
    methods
        function obj=S29_sel_symbol()
            %读入因子数据
            sql_str_f1 = ['select factor_name,pub_date,symbol,f_val from ',...
                'S29.factor_yuqer_com order by pub_date desc']; 
            sql_str_f2 = ['select factor_name,pub_date,symbol,f_val from ',...
                'S29.factor_yuqer_com_ttm order by pub_date desc'];
            %载入ST信息数据
            sql_str = 'SELECT * FROM yuqerdata.st_info order by tradedate desc';
            x_st = fetchmysql(sql_str,2);
            x_st(:,1) = cellfun(@str2double,x_st(:,1),'UniformOutput',false);
            x_st_codenum = cell2mat(x_st(:,1));
            x_st_u_codenum = unique(x_st_codenum);
            x_st_data = cell(length(x_st_u_codenum),3);
            for i = 1:length(x_st_u_codenum)
                sub_x_st_data=x_st(eq(x_st_codenum,x_st_u_codenum(i)),:);
                x_st_data(i,:) = {sprintf('%0.6d',x_st_u_codenum(i)),sub_x_st_data{1,2},sub_x_st_data{end,2}};
            end
            obj.x_st_symbol = x_st_data(:,1);
            obj.x_st_date0 = datenum(x_st_data(:,3));
            obj.x_st_date1 = datenum(x_st_data(:,2));


            F = fetchmysql(sql_str_f1,2);
            [temp,~,ib] = unique(F(:,2));
            temp = datenum(temp);
            t_F =temp(ib);
            F_ttm = fetchmysql(sql_str_f2,2);
            [temp,~,ib] = unique(F_ttm(:,2));
            temp = datenum(temp);
            t_F_ttm =temp(ib);

            obj.F_all = cell(10,2);
            for i = 1:5
                sub_ind1 = strcmp(F(:,1),sprintf('cF%d',i));
                obj.F_all{i,1} = F(sub_ind1,:);
                obj.F_all{i,2} = t_F(sub_ind1,:);

                sub_ind2 = strcmp(F_ttm(:,1),sprintf('ctm%d',i));
                obj.F_all{i+5,1} = F_ttm(sub_ind2,:);
                obj.F_all{i+5,2} = t_F_ttm(sub_ind2,:);
            end
        end
        function symbol_pool = get_symbol_m1(obj,t_sel,index_sel)
            symbol_pool = obj.get_symbol_s1(obj.F_all,obj.x_st_symbol,obj.x_st_date0,obj.x_st_date1,t_sel,index_sel);
        end
        function symbol_pool = get_symbol_m3(obj,t_sel,index_sel)
            symbol_pool = obj.get_symbol_s3(obj.F_all,obj.x_st_symbol,obj.x_st_date0,obj.x_st_date1,t_sel,index_sel);
        end
        function symbol_pool = get_symbol_m4(obj,t_sel,index_sel)
            symbol_pool = obj.get_symbol_s4(obj.F_all,obj.x_st_symbol,obj.x_st_date0,obj.x_st_date1,t_sel,index_sel);
        end
        
    end
    methods(Static)
        %method1
        function symbol_pool = get_symbol_s1(F_all,x_st_symbol,x_st_date0,x_st_date1,t_sel,index_sel)
            sql_str_f3 = ['select ticker,chgPct from yuqerdata.MktEqumAdjAfGet where ',...
            'endDate=''%s'' and chgPct is not null'];
            sub_t_num = datenum(t_sel);
            %月度数据
            x = fetchmysql(sprintf(sql_str_f3,t_sel),2);
            if ~isempty(index_sel)
                sub_symbol_pool = get_index_com_symbol(index_sel,t_sel);
                [~,ia] = intersect(x(:,1),sub_symbol_pool);
                x = x(ia,:);
            end
            sub_y = cell2mat(x(:,2));
            %每个因子数据
            sub_F = nan(size(x,1),10);
            for j = 1:10
                sub_f = F_all{j,1}(F_all{j,2}<=sub_t_num,:);
                [~,ia] =unique(sub_f(:,3),'stable');
                sub_f = sub_f(ia,[3,4]);
                [~,ia,ib] = intersect(x(:,1),sub_f(:,1),'stable');
                sub_F(ia,j) = cell2mat(sub_f(ib,2));        
            end    
            %行业数据
            sub_code = yq_methods.get_industry_class(t_sel);
            [~,ia,ib] = intersect(x(:,1),sub_code(:,1),'stable');
            sub_code_v = zeros(size(x(:,1)));
            sub_code_v(ia) = cell2mat(sub_code(ib,2));
            %dummy
            sub_code_v_u = unique(sub_code_v);
            dummy_v = zeros(length(sub_code_v),length(sub_code_v_u));
            for j = 1:length(sub_code_v_u)
                dummy_v(eq(sub_code_v,sub_code_v_u(j)),j) = 1;
            end
            %st等数据
            sub_st_symbol = x_st_symbol(sub_t_num>=x_st_date0&sub_t_num<=x_st_date1);
            sub_st_symbol = cellfun(@(x) sprintf('%0.6d',x),sub_st_symbol,'UniformOutput',false);
            [~,del_ind] = intersect(x(:,1),sub_st_symbol,'stable');
            %涨跌停
            %综合数据 y = kx + b
            sub_x = [sub_F,dummy_v];
            nan_ind = isnan(sum(sub_x,2)+sub_y);
            nan_ind(del_ind) = true;
            sub_y = sub_y(~nan_ind,:);
            sub_x = sub_x(~nan_ind,:);
            sub_symbol = x(~nan_ind,1);
            sub_indus_code = sub_code_v(~nan_ind,:);

            %linner regression
            [~,~,r] = regress(sub_y,[ones(size(sub_y)),sub_x]); 
            %rank data
            [~,~,ia] = unique(r);
            [~,~,ia2] = unique(-(sub_y-r));

            sub_indus_code_u = unique(sub_indus_code);
            ia_f = [];
            %select symbol according industry
            for j = 1:length(sub_indus_code_u)
                sub_ind = find(eq(sub_indus_code,sub_indus_code_u(j)));
                sub_index = min([ia(sub_ind),ia2(sub_ind)],[],2);
                [~,sub_ia_f] = sort(sub_index);
                sub_ia_f = sub_ind(sub_ia_f(1:ceil(end/10)));  
                ia_f = cat(1,ia_f,sub_ia_f);
            end

            symbol_pool = sub_symbol(ia_f);

        end

        function symbol_pool = get_symbol_s2(F_all,x_st_symbol,x_st_date0,x_st_date1,t_sel)
            sql_str_f3 = ['select ticker,chgPct from yuqerdata.MktEqumAdjAfGet where ',...
            'endDate=''%s'' and chgPct is not null'];
            warning off
            sub_t_num = datenum(t_sel);
            %月度数据
            x = fetchmysql(sprintf(sql_str_f3,t_sel),2);
            sub_y = cell2mat(x(:,2));
            %每个因子数据
            sub_F = nan(size(x,1),10);
            for j = 1:10
                sub_f = F_all{j,1}(F_all{j,2}<=sub_t_num,:);
                [~,ia] =unique(sub_f(:,3),'stable');
                sub_f = sub_f(ia,[3,4]);
                [~,ia,ib] = intersect(x(:,1),sub_f(:,1),'stable');
                sub_F(ia,j) = cell2mat(sub_f(ib,2));        
            end    
            %行业数据
            sub_code = yq_methods.get_industry_class(t_sel);
            [~,ia,ib] = intersect(x(:,1),sub_code(:,1),'stable');
            sub_code_v = zeros(size(x(:,1)));
            sub_code_v(ia) = cell2mat(sub_code(ib,2));
            %dummy
            sub_code_v_u = unique(sub_code_v);
            dummy_v = zeros(length(sub_code_v),length(sub_code_v_u));
            for j = 1:length(sub_code_v_u)
                dummy_v(eq(sub_code_v,sub_code_v_u(j)),j) = 1;
            end
            %st等数据
            sub_st_symbol = x_st_symbol(sub_t_num>=x_st_date0&sub_t_num<=x_st_date1);
            sub_st_symbol = cellfun(@(x) sprintf('%0.6d',x),sub_st_symbol,'UniformOutput',false);
            [~,del_ind] = intersect(x(:,1),sub_st_symbol,'stable');
            %涨跌停
            %综合数据 y = kx + b
            sub_x = [sub_F,dummy_v];
            nan_ind = isnan(sum(sub_x,2)+sub_y);
            nan_ind(del_ind) = true;
            sub_y = sub_y(~nan_ind,:);
            sub_x = sub_x(~nan_ind,:);
            sub_symbol = x(~nan_ind,1);

            %linner regression
            [~,~,r] = regress(sub_y,[ones(size(sub_y)),sub_x]); 
            [~,ia] = sort(r);
            [~,ia2] = sort(-(sub_y-r));

            ia_f = intersect(ia(1:floor(end/10)),ia2(1:floor(end/10)));

            symbol_pool = sub_symbol(ia_f);

        end

        function symbol_pool = get_symbol_s3(F_all,x_st_symbol,x_st_date0,x_st_date1,t_sel,index_sel)
            sql_str_f3 = ['select ticker,chgPct from yuqerdata.MktEqumAdjAfGet where ',...
            'endDate=''%s'' and chgPct is not null'];
            warning off
            sub_t_num = datenum(t_sel);
            %月度数据
            x = fetchmysql(sprintf(sql_str_f3,t_sel),2);
            if ~isempty(index_sel)
                sub_symbol_pool = get_index_com_symbol(index_sel,t_sel);
                [~,ia] = intersect(x(:,1),sub_symbol_pool);
                x = x(ia,:);
            end
            sub_y = cell2mat(x(:,2));
            %每个因子数据
            sub_F = nan(size(x,1),10);
            for j = 1:10
                sub_f = F_all{j,1}(F_all{j,2}<=sub_t_num,:);
                [~,ia] =unique(sub_f(:,3),'stable');
                sub_f = sub_f(ia,[3,4]);
                [~,ia,ib] = intersect(x(:,1),sub_f(:,1),'stable');
                sub_F(ia,j) = cell2mat(sub_f(ib,2));        
            end    
            %行业数据
            sub_code = yq_methods.get_industry_class(t_sel);
            [~,ia,ib] = intersect(x(:,1),sub_code(:,1),'stable');
            sub_code_v = zeros(size(x(:,1)));
            sub_code_v(ia) = cell2mat(sub_code(ib,2));
            %dummy
            sub_code_v_u = unique(sub_code_v);
            dummy_v = zeros(length(sub_code_v),length(sub_code_v_u));
            for j = 1:length(sub_code_v_u)
                dummy_v(eq(sub_code_v,sub_code_v_u(j)),j) = 1;
            end
            %st等数据
            sub_st_symbol = x_st_symbol(sub_t_num>=x_st_date0&sub_t_num<=x_st_date1);
            sub_st_symbol = cellfun(@(x) sprintf('%0.6d',x),sub_st_symbol,'UniformOutput',false);
            [~,del_ind] = intersect(x(:,1),sub_st_symbol,'stable');
            %涨跌停
            %综合数据 y = kx + b
            sub_x = [sub_F,dummy_v];
            nan_ind = isnan(sum(sub_x,2)+sub_y);
            nan_ind(del_ind) = true;
            sub_y = sub_y(~nan_ind,:);
            sub_x = sub_x(~nan_ind,:);
            sub_symbol = x(~nan_ind,1);

            %linner regression
            [~,~,r] = regress(sub_y,[ones(size(sub_y)),sub_x]); 
            [~,ia] = sort(r);
            [~,ia2] = sort(-(sub_y-r));

            ia_f = [];
            j = 1;
            while j <10
                ia_f = intersect(ia(1:ceil(end/10*j)),ia2(1:ceil(end/10*j)));
                j = j + 1;
                if ~isempty(ia_f)
                    j = 20;
                end
            end
            symbol_pool = sub_symbol(ia_f);
        end

        function symbol_pool = get_symbol_s4(F_all,x_st_symbol,x_st_date0,x_st_date1,t_sel,index_sel)
            sql_str_f3 = ['select ticker,chgPct from yuqerdata.MktEqumAdjAfGet where ',...
            'endDate=''%s'' and chgPct is not null'];
            warning off
            sub_t_num = datenum(t_sel);
            %月度数据
            x = fetchmysql(sprintf(sql_str_f3,t_sel),2);
            if ~isempty(index_sel)
                sub_symbol_pool = get_index_com_symbol(index_sel,t_sel);
                [~,ia] = intersect(x(:,1),sub_symbol_pool);
                x = x(ia,:);
            end
            sub_y = cell2mat(x(:,2));
            %每个因子数据
            sub_F = nan(size(x,1),10);
            for j = 1:10
                sub_f = F_all{j,1}(F_all{j,2}<=sub_t_num,:);
                [~,ia] =unique(sub_f(:,3),'stable');
                sub_f = sub_f(ia,[3,4]);
                [~,ia,ib] = intersect(x(:,1),sub_f(:,1),'stable');
                sub_F(ia,j) = cell2mat(sub_f(ib,2));        
            end    
            %行业数据
            sub_code = yq_methods.get_industry_class(t_sel);
            [~,ia,ib] = intersect(x(:,1),sub_code(:,1),'stable');
            sub_code_v = zeros(size(x(:,1)));
            sub_code_v(ia) = cell2mat(sub_code(ib,2));
            %dummy
            sub_code_v_u = unique(sub_code_v);
            dummy_v = zeros(length(sub_code_v),length(sub_code_v_u));
            for j = 1:length(sub_code_v_u)
                dummy_v(eq(sub_code_v,sub_code_v_u(j)),j) = 1;
            end
            %st等数据
            sub_st_symbol = x_st_symbol(sub_t_num>=x_st_date0&sub_t_num<=x_st_date1);
            sub_st_symbol = cellfun(@(x) sprintf('%0.6d',x),sub_st_symbol,'UniformOutput',false);
            [~,del_ind] = intersect(x(:,1),sub_st_symbol,'stable');
            %涨跌停
            %综合数据 y = kx + b
            sub_x = [sub_F,dummy_v];
            nan_ind = isnan(sum(sub_x,2)+sub_y);
            nan_ind(del_ind) = true;
            sub_y = sub_y(~nan_ind,:);
            sub_x = sub_x(~nan_ind,:);
            sub_symbol = x(~nan_ind,1);
            sub_indus_code = sub_code_v(~nan_ind,:);

            %linner regression
            [~,~,r] = regress(sub_y,[ones(size(sub_y)),sub_x]); 
            [~,~,ia] = unique(r);
            [~,~,ia2] = unique(-(sub_y-r));

            sub_indus_code_u = unique(sub_indus_code);
            ia_f = [];
            for j = 1:length(sub_indus_code_u)
                sub_ind = find(eq(sub_indus_code,sub_indus_code_u(j)));
                [~,sub_ia] = sort(ia(sub_ind));
                [~,sub_ia2] = sort(ia2(sub_ind));
                k = 1;
                while k < 10
                    sub_ia_f = intersect(sub_ia(1:ceil(end/10*k)),sub_ia2(1:ceil(end/10*k)));
                    k = k + 1;
                    if ~isempty(sub_ia_f)
                        k = 20;
                    end
                end
                ia_f = cat(1,ia_f,sub_ind(sub_ia_f));
            end

            symbol_pool = sub_symbol(ia_f);

        end
    end
end

function sub_symbol_pool = get_index_com_symbol(index_pool,t)
sub_t = fetchmysql(sprintf(['select tradingdate from yuqerdata.IdxCloseWeightGet ',...
    'where tradingdate < ''%s'' and ticker = ''%s'' order by tradingdate desc limit 1'],...
                t,index_pool),2);
if isempty(sub_t)
    sub_t = fetchmysql(sprintf(['select tradingdate from yuqerdata.IdxCloseWeightGet ',...
        'where tradingdate >= ''%s'' and ticker = ''%s''  order by tradingdate limit 1'],...
   t,index_pool),2);
end
sub_symbol_pool = fetchmysql(sprintf(['select symbol from yuqerdata.IdxCloseWeightGet ',...
    'where tradingdate = ''%s'' and ticker = ''%s'''],sub_t{1},index_pool),2);
end