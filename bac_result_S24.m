classdef bac_result_S24 < handle
    methods
        function get_all_results(obj)
            file_name = sprintf('S24可转债多因子轮动%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));            
            [h,re1] = obj.get_autosignal1();
            setpixelposition(h,[223,365,1345,420]);
            obj_wd.pasteFigure(h,' ');
            
            [h,re2] = obj.get_autosignal2();
            setpixelposition(h,[223,365,1345,420]);
            obj_wd.pasteFigure(h,' ');
            obj_wd.CloseWord()  
            re = [re1;re2(end,:)];
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
        end
    end
    methods(Static)
        function [h,re] = get_autosignal1()
            key_str = '风险溢价因子';
            %载入曲线数据
            %需要变换为数据库
            sql_str = 'select tradingdate,f_val1,f_val2 from S24.return_data order by tradingdate';
            tref = fetchmysql(sql_str,2);
            tref_num = datenum(tref(:,1));
            y_c = cumprod(1+cell2mat(tref(:,2:3)));
            tref = tref(:,1);
            %load bac_curve.mat
            %无风险收益率按照年华5%计
            r_bond = exp(log(1.05)/244)-1;
            %读入信号数据
            x1 = fetchmysql(['select tradingdate,10y from aksharedata.bond_china_yield ',...
                'where 10y is not null and symbol=''中债国债收益率曲线'' order by tradingdate'],2);
            x2 = fetchmysql(['select tradeDate,divYield*100 from yuqerdata.yq_MktIdxdEvalGet ',...
                'where ticker = ''000922'' and PEType=1 order by tradeDate'],2); 
            [~,ia,ib] = intersect(x1(:,1),x2(:,1),'stable');
            X = [x1(ia,:),x2(ib,end)];
            tref_num_signal = datenum(X(:,1));
            tref_signal = X(:,1);
            X = cell2mat(X(:,2:end));
            %信号平滑
            X20 = movmean(X,[20,0]);
            X10 = movmean(X,[10,0]);
            X5 = movmean(X,[5,0]);
            %可视化            
            %signal > 0  bond or 
            %计算信号1
            signal_value = X10(:,2)-X10(:,1);
            %按照日期对齐
            [~,ia,ib] = intersect(tref,tref_signal);
            tref_num = tref_num(ia);
            tref = tref(ia);
            y_c = y_c(ia,1);
            y_r = [0;y_c(2:end)./y_c(1:end-1)-1];
            %信号发出的下一日执行转换
            signal_index = zeros(size(y_c));
            temp = find(signal_value>0)+1;
            temp(temp>length(y_c)) = [];
            signal_index(temp) = 1;
            f_str = containers.Map([0,1],{'空','持有可转债'});
            title_str = sprintf('%s-%s:%s',key_str,tref{end},f_str(signal_index(end)));
            %合成曲线
            r = zeros(size(signal_index));
            r(eq(signal_index,1)) = y_r(eq(signal_index,1));
            r(eq(signal_index,0)) = r_bond;
            h = figure;
            plot(tref_num,cumprod(1+r),'LineWidth',2)
            hold on
            plot(tref_num,y_c/y_c(1),'LineWidth',2)
            datetick('x','yyyy')    
            set(gca,'XTickLabelRotation',90);
            set(gca,'XTick',tref_num(round(linspace(1,end,20))),'xlim',tref_num([1,end]));
            datetick('x','yyyymmdd','keepticks');                
            legend({'可转债指数','策略净值'},'NumColumns',2,'Location','best');
            title(title_str);
            %统计参数
            V = cumprod(1+r);
            [v,v_str] = curve_static(V);
            [v1,v_str1] = ad_trans_sta_info(v,v_str); 
            re =[ [{sprintf('%s手续费0','S24可转债利率轮动')};v_str1'],[{'轮动信号'};v1']];
            re = re';
                        
        end
        function [h,re] = get_autosignal2()
            key_str = '修正风险溢价因子';
            %计算修正步骤数据
            [tref_add,Y_m] = Impliedvolatility_update();
            %load sig_add.mat tref_add Y_m
            tref_add_num = datenum(tref_add);
            %载入曲线数据
            sql_str = 'select tradingdate,f_val1,f_val2 from S24.return_data order by tradingdate';
            tref = fetchmysql(sql_str,2);
            tref_num = datenum(tref(:,1));
            y_c = cumprod(1+cell2mat(tref(:,2:3)));
            tref = tref(:,1);
            %无风险收益率按照年华5%计
            r_bond = exp(log(1.05)/244)-1;

            %读入信号数据
            x1 = fetchmysql(['select tradingdate,10y from aksharedata.bond_china_yield ',...
                'where 10y is not null and symbol=''中债国债收益率曲线'' order by tradingdate'],2);
            x2 = fetchmysql(['select tradeDate,divYield*100 from yuqerdata.yq_MktIdxdEvalGet ',...
                'where ticker = ''000922'' and PEType=1 order by tradeDate'],2); 
            [~,ia,ib] = intersect(x1(:,1),x2(:,1),'stable');
            X = [x1(ia,:),x2(ib,end)];
            tref_num_signal = datenum(X(:,1));
            [~,ia,ib] = intersect(tref_num_signal,tref_add_num);
            X = X(ia,:);
            tref_num_signal = tref_num_signal(ia);
            tref_add_num = tref_add_num(ib);
            Y_m = Y_m(ib);

            [tref_num_signal,ia ] = sort(tref_num_signal);
            X = X(ia,:);
            tref_signal = X(:,1);
            tref_signal = cellstr(datestr(datenum(tref_signal),'yyyy-mm-dd'));
            X = cell2mat(X(:,2:end));

            %信号平滑
            X20 = movmean(X,[20,0]);
            X10 = movmean(X,[10,0]);
            X5 = movmean(X,[5,0]);

            %{
            subplot(3,1,1);plot(X5);
            subplot(3,1,2);plot(X10);
            subplot(3,1,3);plot(X20);
            %}
            %修正中证红利股息率
            X10(:,2) = X10(:,2).*Y_m;
            %signal > 0  bond or 
            %计算信号1
            signal_value = (X10(:,2)-X10(:,1));
            %按照日期对齐
            [tref,ia,ib] = intersect(tref,tref_signal);
            tref_num = tref_num(ia);
            y_c = y_c(ia,1);
            y_r = [0;y_c(2:end)./y_c(1:end-1)-1];
            %信号发出的下一日执行转换
            signal_index = zeros(size(y_c)); %保存信号
            temp = find(signal_value>0)+1;
            temp(temp>length(y_c)) = [];
            signal_index(temp) = 1;
            f_str = containers.Map([0,1],{'空','持有可转债'});
            title_str = sprintf('%s-%s:%s',key_str,tref{end},f_str(signal_index(end)));
            %合成曲线
            r = zeros(size(signal_index));
            r(eq(signal_index,1)) = y_r(eq(signal_index,1));
            r(eq(signal_index,0)) = r_bond;
            h = figure;
            plot(tref_num,cumprod(1+r),'LineWidth',2)
            hold on
            plot(tref_num,y_c/y_c(1),'LineWidth',2)
            set(gca,'XTickLabelRotation',90);
            set(gca,'XTick',tref_num(round(linspace(1,end,20))),'xlim',tref_num([1,end]));
            datetick('x','yyyymmdd','keepticks');                
            legend({'可转债指数','策略净值'},'NumColumns',2,'Location','best');
            title(title_str);
            %统计参数
            V = cumprod(1+r);
            [v,v_str] = curve_static(V);
            [v1,v_str1] = ad_trans_sta_info(v,v_str); 
            re =[ [{sprintf('%s手续费0','S24可转债利率轮动')};v_str1'],[{'修正轮动信号'};v1']];
            re = re';

            
        end
    end
end

function [tref,Y_m] = Impliedvolatility_update()
%wind 可转债隐含波动率合成指数 
tref = fetchmysql('SELECT distinct(tradingdate) FROM yuqerdata.bond_impliedvol_wind_update where tradingdate >=''2008-01-01'' order by tradingdate',2);

T = length(tref);
sql_str = 'select f_val from yuqerdata.bond_impliedvol_wind_update where tradingdate =''%s''';
y = zeros(T,1);
parfor i = 1:T
    sub_x = fetchmysql(sprintf(sql_str,tref{i}));
    sub_x(isnan(sub_x)) = [];
    y(i) = mean(sub_x);
end

%y_ci = y;
%平滑
y_ci = movmean(y,[20,0])/100;

%50指数实际波动率
x = fetchmysql(['SELECT tradedate,closeIndex/precloseIndex-1 FROM yuqerdata.yq_index ',...
    'where symbol = ''000016'' and tradedate>=''2008-01-01'' order by tradedate'],2);

y2 = cell2mat(x(:,2));
y1 = movstd(y2,[15,0]);

y_50 = movmean(y1*sqrt(244),[20,0]);
%y_50 =  y1*sqrt(244);

%数据对齐
[~,ia,ib] = intersect(tref,x(:,1));
tref = tref(ia);
Y = [y_ci(ia),y_50(ib)];
%计算修正系数
Y_m = Y(:,2)./Y(:,1);
end