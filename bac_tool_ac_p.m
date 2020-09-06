%{
回测工具
输入 股票代码，时间
输出 每个交易日的收益
可以断点写
需要限定输出的表格名称

需要知道具体时间点的股票池
backtest according symbol pool
%}
classdef bac_tool_ac_p < handle
    methods
        function bac_S49_p1(obj)
            %计算收益率
            %输出参数
            tn = 'S49.f1_com1';
            var1 = {'tradeDate','ticker'}; %time ticker
            tn_out_dn = 'S37';
            tn_out_tn = 'factor_return_f49';
            tn_out = sprintf('%s.%s',tn_out_dn,tn_out_tn);
            f_name = '超预期因子';
            pool_name = '全市场';
            var_out = {'factor_name','tradingdate','id_pool','f_f'};
            var_out_type = {'varchar(20)','date','varchar(10)','float'};
            t0 = '2016-07-30';
            %计算并写入数据库
            obj.get_return(tn,var1,tn_out_dn,tn_out_tn,tn_out,f_name,pool_name,var_out,var_out_type,t0)
            %%%%%%%%%%%%%%%
            sql_str = 'select %s,%s from %s order by %s';
            r1 = fetchmysql(sprintf(sql_str,var_out{2},var_out{end},tn_out,var_out{2}),2);
            sql_str = 'select tradeDate,chgpct from yuqerdata.yq_index  where symbol = "000905" order by tradeDate';
            r2 = fetchmysql(sql_str,2);
            [tref_f,ia,ib] = intersect(r1(:,1),r2(:,1));
            r1 = cell2mat(r1(ia,2));
            %加入手续费 1.5/1000
            tref_do = fetchmysql(sprintf('select distinct(%s) from %s',var1{1},tn),2);
            [~,ia] = intersect(tref_f,tref_do);
            r1(ia) = r1(ia)-1.5/1000;
            r2 = cell2mat(r2(ib,2));
            r3 = r1-r2;
            tref_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),tref_f,'UniformOutput',false);
            %统计参数
            y_c1 = cumprod(1+r1);
            y_c_com = cumprod(1+r3);
            
            y_c_title = {'超预期因子','超预期因子对冲500指数'};
            h1 = obj.plot_curve(tref_str,y_c1,'超预期因子');
            h2 = obj.plot_curve(tref_str,y_c_com,'超预期因子对冲500指数');
            
            sta_re = obj.curve_static_batch([y_c1,y_c_com],y_c_title);
            
            key_str = sprintf('S49-part1-%s',f_name);
            obj_h = [h1,h2];
            obj.my_report(key_str,obj_h,y_c_title,sta_re)
        end
    end
    methods(Static)
        function get_return(tn,var1,tn_out_dn,tn_out_tn,tn_out,f_name,pool_name,var_out,var_out_type,t0)

            create_table_adair(tn_out_dn,tn_out_tn,var_out,var_out_type,strjoin(var_out(1:3),','));
            tref = yq_methods.get_tradingdate(t0);
            tref_OK = 'select distinct(tradingdate) from %s where factor_name = "%s"';
            tref_OK = fetchmysql(sprintf(tref_OK,tn_out,f_name),2);
            tref_undo = setdiff(tref,tref_OK);

            tref_p = sprintf('select distinct(%s) from %s order by %s',var1{1},tn,var1{1});
            tref_p = fetchmysql(tref_p,2);
            tref_p_num = datenum(tref_p);

            T = length(tref_undo);
            if T>0
                sql_str_pool = 'select %s from %s where %s="%s"';
                sql_str = 'select symbol,chgPct from yuqerdata.yq_dayprice where tradeDate = "%s" and chgPct is not null';
                y_chg = zeros(T,1);
                parfor i = 1:T
                    %寻找股票池
                    ind = find(tref_p_num<datenum(tref_undo(i)),1,'last');
                    sub_t = tref_p{ind};
                    sql_str_temp = sprintf(sql_str_pool,var1{2},tn,var1{1},sub_t);
                    sub_pool = fetchmysql(sql_str_temp,2);
                    %寻找收益数据
                    chg = fetchmysql(sprintf(sql_str,tref_undo{i}),2);
                    %计算收益
                    sub_r = zeros(size(sub_pool));
                    [~,ia,ib] = intersect(sub_pool,chg(:,1));
                    sub_r(ia) = cell2mat(chg(ib,2));
                    %写入结果
                    y_chg(i) = mean(sub_r);
                    sprintf('%s %s收益率 %d-%d',f_name,tref_undo{i},i,T)
                end
                f = [tref_undo(:,[1,1,1]),num2cell(y_chg)];
                f(:,1) = {f_name};
                f(:,3) = {pool_name};
                datainsert_adair(tn_out,var_out,f)
            end
        end

        function h = plot_curve(t_str,r_c,title_str)
            h=figure;
            bpcure_plot_updateV2(t_str,r_c(:,end))
            setpixelposition(gcf,[223,365,1345,420]);
            title(title_str);
        end

        function sta_re = curve_static_batch(yc,title_str)
            
            sta_re = cell(size(yc,2),1);
            for i = 1:length(sta_re)
                [v0,v_str0] = curve_static(yc(:,i));
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
        
        function my_report(key_str,obj_h,h_title,sta_re)
            file_name = sprintf('%s因子表现%s',key_str,datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            for i = 1:length(obj_h)
                obj_wd.pasteFigure(obj_h(i),h_title{i});
            end
            obj_wd.CloseWord()
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),sta_re)
        end
        
    end
end