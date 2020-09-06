classdef bac_result_S24 < handle
    methods
        function get_all_results(obj)
            file_name = sprintf('S24��תծ�������ֶ�%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'������');
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
            key_str = '�����������';
            %������������
            %��Ҫ�任Ϊ���ݿ�
            sql_str = 'select tradingdate,f_val1,f_val2 from S24.return_data order by tradingdate';
            tref = fetchmysql(sql_str,2);
            tref_num = datenum(tref(:,1));
            y_c = cumprod(1+cell2mat(tref(:,2:3)));
            tref = tref(:,1);
            %load bac_curve.mat
            %�޷��������ʰ����껪5%��
            r_bond = exp(log(1.05)/244)-1;
            %�����ź�����
            x1 = fetchmysql(['select tradingdate,10y from aksharedata.bond_china_yield ',...
                'where 10y is not null and symbol=''��ծ��ծ����������'' order by tradingdate'],2);
            x2 = fetchmysql(['select tradeDate,divYield*100 from yuqerdata.yq_MktIdxdEvalGet ',...
                'where ticker = ''000922'' and PEType=1 order by tradeDate'],2); 
            [~,ia,ib] = intersect(x1(:,1),x2(:,1),'stable');
            X = [x1(ia,:),x2(ib,end)];
            tref_num_signal = datenum(X(:,1));
            tref_signal = X(:,1);
            X = cell2mat(X(:,2:end));
            %�ź�ƽ��
            X20 = movmean(X,[20,0]);
            X10 = movmean(X,[10,0]);
            X5 = movmean(X,[5,0]);
            %���ӻ�            
            %signal > 0  bond or 
            %�����ź�1
            signal_value = X10(:,2)-X10(:,1);
            %�������ڶ���
            [~,ia,ib] = intersect(tref,tref_signal);
            tref_num = tref_num(ia);
            tref = tref(ia);
            y_c = y_c(ia,1);
            y_r = [0;y_c(2:end)./y_c(1:end-1)-1];
            %�źŷ�������һ��ִ��ת��
            signal_index = zeros(size(y_c));
            temp = find(signal_value>0)+1;
            temp(temp>length(y_c)) = [];
            signal_index(temp) = 1;
            f_str = containers.Map([0,1],{'��','���п�תծ'});
            title_str = sprintf('%s-%s:%s',key_str,tref{end},f_str(signal_index(end)));
            %�ϳ�����
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
            legend({'��תծָ��','���Ծ�ֵ'},'NumColumns',2,'Location','best');
            title(title_str);
            %ͳ�Ʋ���
            V = cumprod(1+r);
            [v,v_str] = curve_static(V);
            [v1,v_str1] = ad_trans_sta_info(v,v_str); 
            re =[ [{sprintf('%s������0','S24��תծ�����ֶ�')};v_str1'],[{'�ֶ��ź�'};v1']];
            re = re';
                        
        end
        function [h,re] = get_autosignal2()
            key_str = '���������������';
            %����������������
            [tref_add,Y_m] = Impliedvolatility_update();
            %load sig_add.mat tref_add Y_m
            tref_add_num = datenum(tref_add);
            %������������
            sql_str = 'select tradingdate,f_val1,f_val2 from S24.return_data order by tradingdate';
            tref = fetchmysql(sql_str,2);
            tref_num = datenum(tref(:,1));
            y_c = cumprod(1+cell2mat(tref(:,2:3)));
            tref = tref(:,1);
            %�޷��������ʰ����껪5%��
            r_bond = exp(log(1.05)/244)-1;

            %�����ź�����
            x1 = fetchmysql(['select tradingdate,10y from aksharedata.bond_china_yield ',...
                'where 10y is not null and symbol=''��ծ��ծ����������'' order by tradingdate'],2);
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

            %�ź�ƽ��
            X20 = movmean(X,[20,0]);
            X10 = movmean(X,[10,0]);
            X5 = movmean(X,[5,0]);

            %{
            subplot(3,1,1);plot(X5);
            subplot(3,1,2);plot(X10);
            subplot(3,1,3);plot(X20);
            %}
            %������֤������Ϣ��
            X10(:,2) = X10(:,2).*Y_m;
            %signal > 0  bond or 
            %�����ź�1
            signal_value = (X10(:,2)-X10(:,1));
            %�������ڶ���
            [tref,ia,ib] = intersect(tref,tref_signal);
            tref_num = tref_num(ia);
            y_c = y_c(ia,1);
            y_r = [0;y_c(2:end)./y_c(1:end-1)-1];
            %�źŷ�������һ��ִ��ת��
            signal_index = zeros(size(y_c)); %�����ź�
            temp = find(signal_value>0)+1;
            temp(temp>length(y_c)) = [];
            signal_index(temp) = 1;
            f_str = containers.Map([0,1],{'��','���п�תծ'});
            title_str = sprintf('%s-%s:%s',key_str,tref{end},f_str(signal_index(end)));
            %�ϳ�����
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
            legend({'��תծָ��','���Ծ�ֵ'},'NumColumns',2,'Location','best');
            title(title_str);
            %ͳ�Ʋ���
            V = cumprod(1+r);
            [v,v_str] = curve_static(V);
            [v1,v_str1] = ad_trans_sta_info(v,v_str); 
            re =[ [{sprintf('%s������0','S24��תծ�����ֶ�')};v_str1'],[{'�����ֶ��ź�'};v1']];
            re = re';

            
        end
    end
end

function [tref,Y_m] = Impliedvolatility_update()
%wind ��תծ���������ʺϳ�ָ�� 
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
%ƽ��
y_ci = movmean(y,[20,0])/100;

%50ָ��ʵ�ʲ�����
x = fetchmysql(['SELECT tradedate,closeIndex/precloseIndex-1 FROM yuqerdata.yq_index ',...
    'where symbol = ''000016'' and tradedate>=''2008-01-01'' order by tradedate'],2);

y2 = cell2mat(x(:,2));
y1 = movstd(y2,[15,0]);

y_50 = movmean(y1*sqrt(244),[20,0]);
%y_50 =  y1*sqrt(244);

%���ݶ���
[~,ia,ib] = intersect(tref,x(:,1));
tref = tref(ia);
Y = [y_ci(ia),y_50(ib)];
%��������ϵ��
Y_m = Y(:,2)./Y(:,1);
end