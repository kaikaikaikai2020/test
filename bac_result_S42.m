classdef bac_result_S42 < handle
    methods
        function get_all_results(obj)
            obj.update_signal()
            obj.write_result()
        end
    end
    methods(Static)
        function update_signal()
            
            symbol_pool_all = yq_methods.get_symbol_A();
            T_symbol_pool_all = length(symbol_pool_all);

            t0 = datetime;
            run_mod = 'f';
            parfor i = 1:T_symbol_pool_all
                dos_str = sprintf('python M_TD_update1.py %s %s a_stock',symbol_pool_all{i},run_mod);
                %sprintf(dos_str)
                dos(dos_str)
            end

            tt = datetime;

            sprintf('time used %s',tt-t0)
            
        end
        function write_result()
            symbol_pool = {'000300','000905','000906'};
            T_symbol_pool = length(symbol_pool);
            t=datestr(now,'yyyy-mm-dd');


            run_mod = 'f';
            key_str = 'S42 A股组合-固定参数-多';

            sql_str = 'select tradeDate,chg from S42.s42_a_stock where symbol = "%s" and g_num=1 and c_m = "%s"';
            tref = yq_methods.get_tradingdate('2010-01-01',t);

            sta_re2 = cell(T_symbol_pool,1);

            write_sel = true;
            if write_sel
                pn_write = fullfile(pwd,'计算结果');
                if ~exist(pn_write,'dir')
                    mkdir(pn_write)
                end
                obj_wd = wordcom(fullfile(pn_write,sprintf('%s%s.doc',key_str,datestr(now,'yyyymmdd'))));
                xls_fn = fullfile(pn_write,sprintf('%s%s.xlsx',key_str,datestr(now,'yyyymmdd')));
            end

            for i = 1:T_symbol_pool
                sub_symbol = symbol_pool{i};
                symbols = yq_methods.get_index_pool(sub_symbol,t);

                T_symbol = length(symbols);
                y = cell(T_symbol,1);
                parfor j = 1:T_symbol
                    sub_f = fetchmysql(sprintf(sql_str,symbols{j},run_mod),2);
                    if isempty(sub_f)
                        continue
                    end
                    sub_y = zeros(size(tref));
                    [~,ia,ib] = intersect(tref,sub_f(:,1));
                    sub_y(ia) = cell2mat(sub_f(ib,2));
                    y{j} = sub_y;
                    sprintf('%s: %d-%d',key_str,j,T_symbol_pool)
                end
                y = [y{:}];
                r_day = mean(y,2);

                r_c = cumprod(1+r_day);
                t_str = cellfun(@(x) [x(1:4),x(6:7),x(9:10)],tref,'UniformOutput',false);

                T = length(t_str);
                h=figure;
                title_str = sub_symbol;
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
                if write_sel
                    obj_wd.pasteFigure(h,title_str);
                end

            end
            y = [sta_re2{:}];
            y = y';
            if write_sel
                obj_wd.CloseWord();
                xlstocsv_adair(xls_fn,y);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        
        
    end
    
    
    
    
end