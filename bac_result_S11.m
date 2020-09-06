classdef bac_result_S11 < handle
    methods
        function get_all_results(obj)
            file_name = sprintf('S11Hurst择时%s',datestr(now,'yyyy-mm-dd'));
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            re = obj.get_signal_S11(obj_wd);
            obj_wd.CloseWord()
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),re)
        end
        
    end
    methods(Static)
        function re = get_signal_S11(obj_wd)
            key_str = '移动窗口';
            %读取数据
            %index_name_pool = {'上证综指','深证成指','上证50','沪深300','中证500','中小板指'};
            index_name_pool = {'上证综指','上证50','沪深300','中证500'};
            T_index = length(index_name_pool);
            t_para = {[datenum(2000,1,1);datenum(2019,6,30);datenum(2006,12,29)],...
                [datenum(2000,1,1);datenum(2019,6,30);datenum(2006,12,29)],...
                [datenum(2000,1,1);datenum(2019,6,30);datenum(2012,12,29)],...
                [datenum(2000,1,1);datenum(2019,6,30);datenum(2013,12,29)],...
                [datenum(2000,1,1);datenum(2019,6,30);datenum(2013,12,29)]};
            re = cell(T_index,1);
            for index_sel = 1:T_index %选择指数
                sub_data_info = index_name_pool{index_sel};

                t_cut = t_para{index_sel}(3);
                circle_time = [1,1,1,1,0.5]; %周期设置）%1 1 2 2 0.5

                x = get_index_data_yuqer(sub_data_info);


                check_mod = 1;%1 核实hurst指数；2 核实 移动均线 

                hurst_widow = 52*4; %0 所有可用历史数据，否者窗口数据
                hurst_widow_cal = 52*circle_time(index_sel); %计算hurst时的窗口参数

                ma_window = 12;
                ema_window = ma_window;

                delta1 = 0.5;%上限参数
                delta2 = 0.5;%下限参数

                K = 0.5;%平仓resi参数
                K1 = 0.5;%平仓resi参数

                tref = datenum(x(:,1));

                open_price = cell2mat(x(:,2));
                close_price = cell2mat(x(:,3));
                [tref_w,open_price_w,close_price_w] = get_week_data(tref,open_price,close_price);

                %ema_close_price_w = EMA(close_price_w,ema_window); %EMA窗口大小参数未说明
                %ma_close_price_w = MA(close_price_w,ma_window); %EMA窗口大小参数未说明

                r1 = close_price(2:end)./close_price(1:end-1)-1;
                r1_w = [0;close_price_w(2:end)./close_price_w(1:end-1)-1];

                model_ind = find(tref_w>=t_cut,1);

                T =length(r1_w);
                hurst_exp = zeros(T,1);
                y = zeros(T,1);
                for i = hurst_widow+1:T
                    if eq(hurst_widow,0)
                        sub_wid = 1:i;
                        temp_v = 52;
                    else
                        sub_wid = i-hurst_widow:i;%计算hurst指数窗口参数
                        temp_v = hurst_widow;
                    end

                    [~,y(i),hurst_exp(i)] = hurst_rs_update1(r1_w(sub_wid),(min(hurst_widow_cal,temp_v):-4:4)');
                end
                y = MA(y,12);
                hurst_std = movstd(y,[hurst_widow_cal,0]);
                hurst_std(1:model_ind-1) = 0;

                TBound = hurst_exp+hurst_std*delta1;
                LBound = hurst_exp-hurst_std*delta2;

                %AR计算残差项
                order = 5;
                m = arx(r1_w, order);
                resi_pred = resid([r1_w(1:order);r1_w], m);
                resi_pred = resi_pred(order+1:end);
                resi_pred  = resi_pred.OutputData;
                resi_std = movstd(resi_pred,[hurst_widow,0]);


                signal = zeros(size(hurst_std));
                signal1 = signal;
                for i = model_ind:length(signal)
                    tempv = cumprod(1+r1_w(max(i-52*1+1,1):i));
                    tempv = tempv(end)-1;
                    %反转开仓
                    if y(i)<=LBound(i) && abs(resi_pred(i))<K*resi_std(i)
                        signal(i) = -1;
                        if tempv>0.1
                            signal1(i) = -1;
                        else
                            signal1(i) = 1;
                        end
                        continue
                    end

                    if eq(signal(i-1),-1) && y(i)>hurst_exp(i)
                        signal(i) = 0;
                        signal1(i) = 0;
                        continue
                    end
                    %趋势开仓    
                    if y(i) > TBound(i)
                        signal(i) = 1;
                        if tempv>0.1
                            signal1(i) = 1;
                        else
                            signal1(i) = -1;
                        end
                        continue
                    end

                    if eq(signal(i-1),1)

                        if y(i)<hurst_exp(i) || ...
                                (tempv<0&&y(i)>TBound(i) && resi_pred(i)>K1*resi_std(i)) ||...
                                (tempv>0&&y(i)>TBound(i) && resi_pred(i)<-K1*resi_std(i))
                            signal(i) = 0;
                            signal1(i) = 0;
                        end
                        continue        
                    end

                    signal1(i) = signal1(i-1);
                    signal(i) = signal(i-1);

                end

                ind = [0;find(diff(signal));length(signal)];
                ind = [ind(1:end-1)+1,ind(2:end)];
                p1 = ind((eq(signal(ind(:,1)),1)),1);
                p2 = ind((eq(signal(ind(:,1)),-1)),1);

                r_c = zeros(size(signal1));
                for i = 2:length(signal1)
                    r_c(i) = r1_w(i)*signal1(i-1);    
                end


                ind = false(length(signal),5);
                ind(:,1) = ~ind(:,1);
                ind(:,2) = eq(signal,1);
                ind(:,3) = eq(signal,-1);
                ind(:,4) = eq(signal1,1);
                ind(:,5) = eq(signal1,-1);

                r_c_a = zeros(size(ind));
                for i = 1:5
                    r_c_a(ind(:,i),i) = r_c(ind(:,i));
                end
                %subplot(T_index,1,index_sel)
                h = figure;
                plot(tref_w(model_ind:end),(cumprod(1+(r_c_a(model_ind:end,:)))-1)*100,'LineWidth',2)
                set(gca,'XTickLabelRotation',90);
                set(gca,'XTick',tref_w(model_ind:20:end),'xlim',tref_w([model_ind,end]));
                datetick('x','yyyymmdd','keepticks');
                set(gca,'fontsize',12);
                leg_str2=  {'总收益','趋势收益','反转收益','做多收益','做空收益'};
                legend(leg_str2,'NumColumns',length(leg_str2),'location','best')
                title_str = sprintf('%s-%s',key_str,sub_data_info);
                title(title_str)
                setpixelposition(h,[223,365,1345,420]);
                obj_wd.pasteFigure(h,title_str);
                
                V = cumprod(1+(r_c_a(model_ind:end,:)));
                [v0,v_str0] = curve_static(V(:,1));
                [v,v_str] = ad_trans_sta_info(v0,v_str0); 
                temp = [[{' '};v_str'],[{sub_data_info};v']];
                if eq(index_sel,1)
                    re{index_sel} = temp;
                else
                    re{index_sel} = temp(:,2);
                end
                
            end
            re = [re{:}]';

        end
    end
end

%窗口变为等分窗口
function [Hal,He,Ht,pval95] = hurst_rs_update1(x,d,fontsize)
%HURST Calculate the Hurst exponent using R/S analysis.
%   H = HURST(X) calculates the Hurst exponent of time series X using 
%   the R/S analysis of Hurst [2], corrected for small sample bias [1,3,4]. 
%   If a vector of increasing natural numbers is given as the second input 
%   parameter, i.e. HURST(X,D), then it defines the box sizes that the 
%   sample is divided into (the values in D have to be divisors of the 
%   length of series X). If D is a scalar (default value D = 50) it is 
%   treated as the smallest box size that the sample can be divided into. 
%   In this case the optimal sample size OptN and the vector of divisors 
%   for this size are automatically computed. 
%   OptN is defined as the length that possesses the most divisors among 
%   series shorter than X by no more than 1%. The input series X is 
%   truncated at the OptN-th value. 
%   [H,HE,HT] = HURST(X) returns the uncorrected empirical and theoretical 
%   Hurst exponents.
%   [H,HE,HT,PV95] = HURST(X) returns the empirical 95% confidence 
%   intervals PV95 (see [4]).
%
%   If there are no output parameters, the R/S statistics is automatically 
%   plotted against the divisors on a loglog paper and the results of the 
%   analysis are displayed in the command window. HURST(X,D,FONTSIZE) 
%   allows to specify a fontsize different than 14 in the plotted figure.
%
%   References:
%   [1] A.A.Anis, E.H.Lloyd (1976) The expected value of the adjusted 
%   rescaled Hurst range of independent normal summands, Biometrica 63, 
%   283-298.
%   [2] H.E.Hurst (1951) Long-term storage capacity of reservoirs, 
%   Transactions of the American Society of Civil Engineers 116, 770-808.
%   [3] E.E.Peters (1994) Fractal Market Analysis, Wiley.
%   [4] R.Weron (2002) Estimating long range dependence: finite sample 
%   properties and confidence intervals, Physica A 312, 285-299.

%   Written by Rafal Weron (2011.09.30). 
%   Based on functions hurstal.m, hurstcal.m, finddiv.m, findndiv.m 
%   originally written by Witold Wiland & Rafal Weron (1997.06.30, 
%   2001.02.01, 2002.07.27).  

if nargin<3
    fontsize = 14; 
end
if nargin<2
    d = 50; 
end
if max(size(d)) == 1
    % For scalar d set dmin=d and find the 'optimal' vector d
    dmin = d;
    % Find such a natural number OptN that possesses the largest number of 
    % divisors among all natural numbers in the interval [0.99*N,N] 
    N = length(x); 
    N0 = floor(0.99*N);
    dv = zeros(N-N0+1,1);
    for i = N0:N
        dv(i-N0+1) = length(divisors(i,dmin));
    end
    OptN = N0 + max(find(max(dv)==dv)) - 1; %#ok<MXFND>
    % Use the first OptN values of x for further analysis
    x = x(1:OptN);
    % Find the divisors of x
    d = divisors(OptN,dmin);
else
    OptN = length(x);
end

N = length(d);
RSe = zeros(N,1);
ERS = zeros(N,1);

% Calculate empirical R/S
parfor i=1:N
   RSe(i) = RScalc(x,d(i));
end

% Compute Anis-Lloyd [1] and Peters [3] corrected theoretical E(R/S)
% (see [4] for details)
for i=1:N
    n = d(i); 
    K = 1:n-1;
    ratio = (n-0.5)/n * sum(sqrt((ones(1,n-1)*n-K)./K));
    if (n>340)
        ERS(i) = ratio/sqrt(0.5*pi*n);
    else
        ERS(i) = (gamma(0.5*(n-1))*ratio) / (gamma(0.5*n)*sqrt(pi));
    end
end

% Calculate the Anis-Lloyd/Peters corrected Hurst exponent
% Compute the Hurst exponent as the slope on a loglog scale
ERSal = sqrt(0.5*pi.*d);
Pal = polyfit(log10(d),log10( RSe - ERS + ERSal ),1);
Hal = Pal(1);
% Calculate the empirical and theoretical Hurst exponents
Pe = polyfit(log10(d),log10(RSe),1);
He = Pe(1);
P = polyfit(log10(d),log10(ERS),1);
Ht = P(1);

% Compute empirical confidence intervals (see [4])
L = log2(OptN);
% R/S-AL (min(divisor)>50) two-sided empirical confidence intervals
pval95 = [0.5-exp(-7.33*log(log(L))+4.21) exp(-7.20*log(log(L))+4.04)+0.5];
C = [   0.5-exp(-7.35*log(log(L))+4.06) exp(-7.07*log(log(L))+3.75)+0.5 .90];
C = [C; pval95                                                          .95];
C = [C; 0.5-exp(-7.19*log(log(L))+4.34) exp(-7.51*log(log(L))+4.58)+0.5 .99];

% Display and plot results if no output arguments are specified
if nargout < 1
    % Display results
    disp('---------------------------------------------------------------')
    disp(['R/S-AL using ' num2str(length(d)) ' divisors (' num2str(d(1)) ',...,' num2str(d(length(d))) ...
        ') for a sample of ' num2str(OptN) ' values'])
    disp(['Corrected theoretical Hurst exponent    ' num2str(0.5,4)]);
    disp(['Corrected empirical Hurst exponent      ' num2str(Hal,4)]);
    disp(['Theoretical Hurst exponent              ' num2str(Ht,4)]);
    disp(['Empirical Hurst exponent                ' num2str(He,4)]);
    disp('---------------------------------------------------------------')

    % Display empirical confidence intervals
    disp('R/S-AL (min(divisor)>50) two-sided empirical confidence intervals')
    disp('--- conf_lo   conf_hi   level ---------------------------------')
    disp(C)
    disp('---------------------------------------------------------------')

    % Plot R/S
    h2 = plot(log10(d),log10(ERSal/(ERS(1)/RSe(1))),'r-');
    if fontsize > 10
        set(h2,'linewidth',2); 
    end
    hold on
    h1 = plot(log10(d),log10(RSe-ERS+ERSal),'k-');
    if fontsize > 10
        set(h1,'linewidth',2); 
    end
    hold off
    set(gca,'Box','on','fontsize',fontsize);
    xlabel('log_{10}n','fontsize',fontsize);
    ylabel('log_{10}R/S','fontsize',fontsize);
    legend('Theoretical (R/S)','Empirical (R/S)')
end
end
function d = divisors(n,n0)
% Find all divisors of the natural number N greater or equal to N0
i = n0:floor(n/2);
d = find((n./i)==floor(n./i))' + n0 - 1;
end
function rs = RScalc(Z,n)
% Calculate (R/S)_n for given n
%update 解决分组问题
m = floor(length(Z)/n);
Z = Z(end-m*n+1:end);
Y = reshape(Z,n,m);
E = mean(Y);
S = std(Y,1);
% for i=1:m
%     Y(:,i) = Y(:,i) - E(i);
% end
Y = bsxfun(@minus,Y,E);
Y = cumsum(Y);
% Find the ranges of cummulative series
MM = max(Y) - min(Y);
% Rescale the ranges by the standard deviations
CS = MM./S;
rs = mean(CS);
end

%获取周数据
function [tref_w,p_open_w,p_close_w] = get_week_data(tref,p_open,p_close)
week_num = weeknum(tref);
ind = find(diff(week_num));
ind = [0;ind;length(tref)];

ind = [ind(1:end-1)+1,ind(2:end)];
p_open_w = p_open(ind(:,1));
p_close_w = p_close(ind(:,2));
tref_w = tref(ind(:,2));
end

function MAValue=MA(Price,Length)
%---------------------此函数用来计算简单移动平均--------------------------
%----------------------------------编写者--------------------------------
%Lian Xiangbin(连长,785674410@qq.com),DUFE,2014
%----------------------------------参考----------------------------------
%[1]招商证券.基于纯技术指标的多因子选股模型,2014-04-11
%[2]百度百科.移动平均线词条
%----------------------------------简介----------------------------------
%移动平均线是由著名的美国投资专家葛兰碧于20世纪中期提出来的。均线理论是当今应用
%最普遍的技术指标之一，它帮助交易者确认现有趋势、判断将出现的趋势等。简单移动平
%均线是最简单的一种移动平均线，它是某个时间段价格序列的简单平均值。也就是说，
%这个时间段上的每个价格权重相同
%----------------------------------基本用法------------------------------
%1)均线与价格形成金叉买入，形成死叉卖出
%2)短期均线与长期均线形成金叉买入，形成死叉卖出
%----------------------------------调用函数------------------------------
%MAValue=MA(Price,Length)
%----------------------------------参数----------------------------------
%Price-目标价格序列
%Length-计算简单移动平均的周期
%----------------------------------输出----------------------------------
%MAValue：简单移动平均值

MAValue=zeros(length(Price),1);
for i=Length:length(Price)
    MAValue(i)=sum(Price(i-Length+1:i))/Length;
end
MAValue(1:Length-1)=Price(1:Length-1);
end