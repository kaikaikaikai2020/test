classdef bac_result_S5 < handle
    methods
        function get_all_results(obj)
            file_name = sprintf('S5动态模分解择时%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            
            re = obj.get_signal_S5(obj_wd);
            obj_wd.CloseWord()
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
        end
    end
    methods(Static)
        function re = get_signal_S5(obj_wd)
            dN = 'S5';
            tn = 'S5_para';
            format_str = containers.Map([1,0,-1],{'做多','平仓','做空'});
            %tradeDate,过去一周，未来一周，正确率，R2，Mu,window
            var_info = {'tradingdate','r_b5','r_a5','r1','r2','mu','wid'};

            sql_str = 'select %s from %s.%s order by tradingdate';
            x = fetchmysql(sprintf(sql_str,strjoin(var_info([1,[1,5,2,4,3,6]+1]),','),dN,tn),2);
            targ_tref = datenum(x(:,1));
            re = cell2mat(x(:,2:end));

            index_code = '000300';
            sql_str_f1 = ['select tradeDate,closeIndex from yuqerdata.yq_index where  ',...
                'symbol = ''%s'' order by tradeDate'];
            x= fetchmysql(sprintf(sql_str_f1,index_code),2);

            tref_300 = datenum(x(:,1));
            close_price_300 = cell2mat(x(:,2));



            [~,ia] = intersect(tref_300,targ_tref);
            tref_300 = tref_300(ia);
            close_price_300 = close_price_300(ia);

            close_price_300_return = [0;close_price_300(2:end)./close_price_300(1:end-1)-1];

            t = datetime(targ_tref,'ConvertFrom','datenum');
            t_str = cellstr(datestr(targ_tref,'yyyymmdd'));

            y = movavg(real(re(:,4)),'linear',30);
            %y = movmean(real(re(:,4)),30);

            y2 = y;
            for i = 120:length(y)
                sub_wind = i-120+1:i;
                y2(i) = half_year_cutvalue(y(sub_wind));
            end

            v1 = 1.03;
            ind1 = y>y2 &abs(re(:,2))>=v1;
            ind2 = y<=y2 | abs(re(:,2))<0.99;
            ind3 =  abs(re(:,2))<0.99;

            T = length(ind1);
            r1 = zeros(T,1);
            r2 = zeros(T,1);
            fee = 3/1000/2;

            signal_ind = zeros(T,1);

            for i = 2:T-1
                if ind1(i)
                    signal_ind(i+1) = 1;
                    if ~eq(signal_ind(i+1),signal_ind(i))
                        r2(i+1) = fee;
                    end
                    continue
                end
                if ind2(i)
                    signal_ind(i+1) = 0;
                    if ~eq(signal_ind(i+1),signal_ind(i))
                        r2(i+1) = fee;
                    end
                    continue
                end

                signal_ind(i+1) = signal_ind(i);
                r2(i+1) = 0;
            end

            r1(eq(signal_ind,1))=close_price_300_return(eq(signal_ind,1));

            r3 = r1-r2;
            y_back_test =cumprod(1+r3);
            y_back_ref = close_price_300/close_price_300(1);


            %辅助信号
            close_price_300_ma = movavg(close_price_300,'linear',30);
            %close_price_300_ma = movmean(close_price_300,30);
            r1 = zeros(T,1);
            r2 = zeros(T,1);
            signal_ind2 = zeros(T,1);
            signal_value = 0;
            signal_type=0;
            mark_pos = -inf;
            for i = 3:T-1

                add_signal1 = close_price_300(i)<close_price_300(i-1) & close_price_300(i)<close_price_300_ma(i) & close_price_300(i-1)<close_price_300_ma(i-1) & close_price_300(i-2)>=close_price_300_ma(i-2); %下穿
                if ind1(i) %买点
                    signal_ind2(i+1) = 1;
                    if ~eq(signal_ind2(i+1),signal_ind2(i))
                        r2(i+1) = fee;
                    end
                    if close_price_300(i)>close_price_300_ma(i)
                        signal_type = 1;
                    else
                        mark_pos = i;
                        signal_type = 2;
                    end        
                    continue
                end
                %卖点
                if eq(signal_type,1)
                    if add_signal1 || ind3(i)
                        signal_ind2(i+1) = 0;
                        if ~eq(signal_ind2(i+1),signal_ind2(i))
                            r2(i+1) = fee;
                        end
                        signal_type=0;
                        mark_pos = -inf;
                        continue
                    end
                end
                if eq(signal_type,2)
                    if eq(i-mark_pos,5) || ind3(i)
                        signal_ind2(i+1) = 0;
                        if ~eq(signal_ind2(i+1),signal_ind2(i))
                            r2(i+1) = fee;
                        end
                        signal_type=0;
                        mark_pos = -inf;
                        continue
                    end
                end

                signal_ind2(i+1) = signal_ind2(i);
                r2(i+1) = 0;
            end

            r1(eq(signal_ind2,1))=close_price_300_return(eq(signal_ind2,1));
            r3 = r1-r2;
            y_back_test2 =cumprod(1+r3);

            info1 = sprintf('%s-择时策略：%s',t_str{end},format_str(signal_ind(end)));
            info2 = sprintf('%s-改进择时策略：%s',t_str{end},format_str(signal_ind2(end)));
            info = sprintf('%s\n%s',info1,info2);

            h=figure;
            plot([y_back_ref,y_back_test,y_back_test2],'LineWidth',2);
            T=length(t_str);
            set(gca,'xlim',[0,T]);
            K = 30;
            set(gca,'XTick',floor(linspace(1,T,K)));

            set(gca,'XTickLabel',t_str(floor(linspace(1,T,K))));
            set(gca,'XTickLabelRotation',90)    
            setpixelposition(gcf,[223,365,1345,420]);
            box off
            g_str = {'300','择时策略','改进择时策略净值'};
            legend(g_str,'NumColumns',length(g_str),'Location','southeast');
            xylimis = axis(gca);
            text(xylimis(1),xylimis(4),info,'VerticalAlignment','top')
            obj_wd.pasteFigure(h,' ');
            
            [v1,v_str1] = curve_static(y_back_ref);
            [v2,v_str2] = curve_static(y_back_test);
            [v3,v_str3] = curve_static(y_back_test2);
            
            [v1,v_str1] = ad_trans_sta_info(v1,v_str1); 
            [v2,~] = ad_trans_sta_info(v2,v_str2); 
            [v3,~] = ad_trans_sta_info(v3,v_str3); 
            re = [[{sprintf('%s千3','S5')};v_str1'],[g_str(1);v1'],[g_str(2);v2'],[g_str(3);v3']];
            re = re';
        end
    end
    
    
end

function v = half_year_cutvalue(x)
x = sort(x);
v = x(round(end/10));
end