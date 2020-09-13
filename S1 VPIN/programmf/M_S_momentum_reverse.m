%M_S_momentum
%{
（１）当天收盘即判断下一天的市场趋势，并用下一天开盘价交易；
（２）做多信号：短期均线Ｓ下穿长期均线Ｌ，则做多；
（３）做空信号：短期均线Ｓ上穿长期均线Ｌ，则做空；
（４）平仓信号：两条均线持平，若持有头寸，则全部平仓；
（５）若由多头转为空头（空头转为多头），则先平仓再做空（做多）

（１）标的物：沪深３００股指期货当月主力合约；
（２）样本区间：２０１１年３月１日至２０１４年８月３１日；
（３）手续费：平今仓万分之六点九；
（４）保证金１００％，初始资金为１；
（５）无风险收益率：３％。
%}
clear
load VPIN_day_data.mat
load vpin_para.mat
%
ini_money = 5e5;
num_L = 34;
num_S = 26;
ini_value = 1e6;
loss_control = 2;
if eq(loss_control,1)
    stop_losses = -0.03;
    takeprofit  = 0.10;
else
    stop_losses =[];
    takeprofit  = [];
end
%

ts = datenum(2011,3,1);
te = datenum(2014,8,31);
%data
ind = X(:,1)>=ts & X(:,1)<=te;
X = X(ind,:);
%signal
s_L = moving_window_average(X(:,3),num_L);
s_S = moving_window_average(X(:,3),num_S);
s_L(1:num_L) = 0;
s_S(1:num_S) = 0;
T = length(s_L);
signal = zeros(T,1);
for i = num_L:T-1
    if s_S(i)<s_S(i-1) && s_S(i)<s_L(i) && s_S(i-1)<s_L(i-1) && s_S(i-2)>=s_L(i-2)
        signal(i) = 1;
        continue;
    end
    if s_S(i)>s_S(i-1) && s_S(i)>s_L(i) && s_S(i-1)>s_L(i-1) && s_S(i-2)<=s_L(i-2)
        signal(i) = -1;
        continue;
    end
    signal(i) = signal(i-1);
end

figure
subplot(2,1,1);
plot(X(:,1),signal,'LineWidth',2)
datetick('x','yymm')
xlabel('时间')
ylabel('多空信号')
mark_label(gca,'A')
obj1 = tf_bactest();
[y,orders] = obj1.simu_bac_method(signal,X(:,2:3),6.9/10000);
y = ini_money+cumsum(y);
[sta1,sta2,sta_values] = curve_static(y);
subplot(2,1,2);
plot(X(:,1),y/y(1),'LineWidth',2)
datetick('x','yymm')
check_data = [X,signal,y];
sharpe(y(2:end)./y(1:end-1)-1,3/100)
xlabel('时间')
ylabel('净值曲线')
mark_label(gca,'B')
