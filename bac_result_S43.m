classdef bac_result_S43<handle
    methods
        function get_all_results(obj)
            obj.update_signal()
            obj.get_result()
        end
    end
    methods(Static)
        function update_signal()
            sprintf('开始执行43升级信号程序')
            dos('python M_S43_ON_A_stock.py')
        end
        function get_result()
            key_str = sprintf('S43 双底策略指数成分股组合%s',datestr(now,'yyyymmdd'));
            write_sel = true;
            if write_sel
                pn_write = fullfile(pwd,'计算结果');
                if ~exist(pn_write,'dir')
                    mkdir(pn_write)
                end
                obj_wd = wordcom(fullfile(pn_write,sprintf('%s.doc',key_str)));
                xls_fn = fullfile(pn_write,sprintf('%s.xlsx',key_str));
                index_com_fn = fullfile(pn_write,sprintf('%s成分股.mat',key_str));
            end

            sql_str = 'select ticker,tradeDate,r_15-1  from S37.S43_Astock order by tradeDate';
            x = fetchmysql(sql_str,2);
            %symbols = unique(x(:,1));
            %tref = unique(x(:,2));
            x = cell2table(x,'VariableNames',{'s','t','v'});
            X = unstack(x,'v','t');

            tref = X.Properties.VariableNames;
            tref = cellfun(@(x) x(2:end),tref,'UniformOutput',false);
            tref = tref(2:end);
            X = table2cell(X); 
            symbols = X(:,1);
            X = cell2mat(X(:,2:end))';
            X(isnan(X)) = 0;

            ind0 = eq(sum(abs(X)),0);
            X(:,ind0) = [];
            symbols(ind0) = [];

            t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref,'UniformOutput',false);
            T = length(t_str);

            symbol_pool_all = {   'a',    '000905','000300','000906'};
            symbol_pool_info = {'全市场','中证500','沪深300','中证800'};
            T_index_pool = length(symbol_pool_all);
            sta_re2 = cell(T_index_pool,1);
            symbols_comp = cell(T_index_pool,1);
            for i = 1:T_index_pool
                sub_index = symbol_pool_all{i};
                title_str = symbol_pool_info{i};
                title_str(strfind(title_str,'_')) = '-';

                sub_symbols = yq_methods.get_index_pool(sub_index,datestr(now,'yyyy-mm-dd'));
                symbols_comp{i} = sub_symbols;
                [~,ia] = intersect(symbols,sub_symbols);
                sub_r = mean(X(:,ia),2);
                r_c = cumprod(1+sub_r);
                h=figure;
                plot(r_c,'-','LineWidth',2);
                set(gca,'xlim',[0,T]);
                set(gca,'XTick',floor(linspace(1,T,15)));
                set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
                set(gca,'XTickLabelRotation',90)    
                setpixelposition(h,[223,365,1345,420]);
                box off
                title(title_str)    
                [v0,v_str0] = curve_static(r_c,[],false);
                [v,v_str] = ad_trans_sta_info(v0,v_str0); 
                result2 = [v_str;v]';
                result = [{'',title_str};result2];
                if ~eq(i,1)
                    result = result(:,2);
                end
                sta_re2{i} = result;
                sprintf('%s %d-%d',key_str,i,T_index_pool)
                if write_sel
                    obj_wd.pasteFigure(h,title_str);  
                end

            end

            y = [sta_re2{:}];
            y = y';

            if write_sel
                obj_wd.CloseWord();
                xlstocsv_adair(xls_fn,y);
                save(index_com_fn,'symbols_comp');
            end
            
        end
    end
    
    
end