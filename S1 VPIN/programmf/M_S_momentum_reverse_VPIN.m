%M_S_reverse_momentum
%{
（１）当天收盘即判断下一天的市场趋势，并用下一天开盘价交易；
（２）做多信号：短期均线Ｓ低于长期均线Ｌ，ＣＤＦ值低于日均ＶＰＩＮ的２９％
分位数，则做多；
（３）做空信号：短期均线Ｓ高于长期均线Ｌ，ＣＤＦ值低于日均ＶＰＩＮ的２９％
分位数，则做空；
（４）平仓信号：ＣＤＦ值高于日均ＶＰＩＮ的２９％分位数；
（５）若由多头转为空头（空头转为多头），则先平仓再做空（做多）。


（１）标的物：沪深３００股指期货当月主力合约；
（２）样本区间：２０１１年３月１日至２０１４年８月３１日；
（３）手续费：平今仓万分之六点九；
（４）保证金１００％，初始资金为１；
（５）无风险收益率：３％。
%}
close all
clear
load VPIN_day_data.mat
load vpin_para.mat
load VPIN_val.mat

method_sel = 5;reverse_sel = true;
%备注 中午信号反转的含义我理解的可能不对，我只是把选股时均线选择的信号反了，并不是
%反转所有信号，现在进行了修正。
%method_sel
%1; %按照文献中方法计算 只比均线，cdf只处在日均VPIN的29分位
%2; %按照文献中方法计算 只比均线，log cdf只处在日均VPIN的29分位
%3  %更改文献中选股方式，使用上穿代替高于，下穿代替低于 cdf只处在日均VPIN的29分位
%4  %更改文献中选股方式，使用上穿代替高于，下穿代替低于 cdf只处在日均VPIN的40分位
%5  %更改文献中选股方式，使用上穿代替高于，下穿代替低于 VPIN只处在日均VPIN的29分位

%reverse_sel
%true 信号反转
%false 信号不反转

%true 信号反转
%false 信号不反转

y = moving_window_average(VPIN(:,end),50);
y = y./V;

%
ini_money = 5e5;
num_L = 28;
num_S = 26;

%
ts = datenum(2011,3,1);
te = datenum(2014,8,31);
%data
ind = X(:,1)>=ts & X(:,1)<=te;
X = X(ind,1:4);
%signal
s_L = moving_window_average(X(:,3),num_L);
s_S = moving_window_average(X(:,3),num_S);
s_L(1:num_L) = 0;
s_S(1:num_S) = 0;
T = length(s_L);

obj1 = tf_bactest();

%section VPIN
quantile_val = zeros(size(X,1),2);
cdf = zeros(size(X(:,1)));

ind = VPIN(:,1)>=datenum(2013,6,24)&VPIN(:,1)<datenum(2013,6,26);
sub_y = [VPIN(ind,1),y(ind)];
subp1 = p1(ind);
ind1 =VPIN(:,1)<datenum(2013,6,24);
parmhat = lognfit(y(ind1));
mx = parmhat(1);
stdx = parmhat(2);
if any(eq(method_sel,[1,2,3,5]))
    cut_v=0.29;
elseif eq(method_sel,4)
    cut_v = 0.40;
end
for i = 1:size(X,1)
    sub_x = [VPIN_para2;X(1:i-1,4)];
    if any(eq(method_sel,[1,3,4,5]))
        mx = mean(sub_x);
        stdx = std(sub_x);
         cdf(i) = normcdf(X(i,4),mx,stdx);
    end
    if eq(method_sel,2)
        parmhat = lognfit(sub_x);
        mx = parmhat(1);
        stdx = parmhat(2);
        cdf(i) = logncdf(X(i,4),mx,stdx);
    end
%    quantile_val(i,:) = [quantile(p0,cut_v(1)),quantile(p0,cut_v(2))];
    quantile_val(i,:) = quantile(sub_x,cut_v(1));
end
signal2 = zeros(T,1);
for i = num_L:T-1
    if any(eq(method_sel,[1,2,3,4]))
         test_ind2 = cdf(i,end)<quantile_val(i,1);
    elseif eq(method_sel,5)
         test_ind2 = X(i,end)<quantile_val(i,1);
    end    
    
    if any(eq(method_sel,[1,2]))        
        if s_S(i)<s_L(i) && test_ind2
            signal2(i) = 1;
            continue
        end
        if s_S(i)>s_L(i) && test_ind2
            signal2(i) = -1;
            continue
        end
    elseif any(eq(method_sel,[3,4,5]))
        if s_S(i)<s_S(i-1) && s_S(i)<s_L(i) && s_S(i-1)<s_L(i-1) && s_S(i-2)>=s_L(i-2) &&test_ind2
            signal2(i) = 1;
            continue;
        end
        if s_S(i)>s_S(i-1) && s_S(i)>s_L(i) && s_S(i-1)>s_L(i-1) && s_S(i-2)<=s_L(i-2) &&test_ind2
            signal2(i) = -1;
            continue;
        end
    end
    
    if ~test_ind2
        signal2(i) = 0;
        continue;
    end    
    signal2(i) = signal2(i-1);
end

if reverse_sel
    temp = signal2;
    signal2(eq(temp,1)) = -1;
    signal2(eq(temp,-1)) = 1;
end

figure
subplot(2,1,1);
plot(X(:,1),signal2,'LineWidth',2)
datetick('x','yymm')
xlabel('时间')
ylabel('多空信号')
mark_label(gca,'A')
[y_bac,orders] = obj1.simu_bac_method(signal2,X(:,2:3),6.9/10000);
y_bac = ini_money+cumsum(y_bac);
[sta1c,sta2c,sta_valuesc] = curve_static(y_bac);
subplot(2,1,2);
plot(X(:,1),y_bac/y_bac(1),'LineWidth',2)
datetick('x','yymm')
check_data = [X,signal2,y_bac];
sharpe(y_bac(2:end)./y_bac(1:end-1)-1,3/100)
xlabel('时间')
ylabel('净值曲线')
mark_label(gca,'C')
%X(:,end)>quantile_val(:,1)&X(:,end)<quantile_val(:,2)
xls_re = [signal2,y_bac];

xls_re = [cellstr(datestr(X(:,1),'yyyymmdd')),num2cell(xls_re)];
xls_re = [{'时间','多空信号','曲线'};xls_re];
if ~reverse_sel
    xlswrite('MS_momentumReverseVPIN.xlsx',xls_re,sprintf('sheet%d',method_sel));
else
    xlswrite('MS_momentumReverseVPIN.xlsx',xls_re,sprintf('sheet%d_sigreverse',method_sel));
end