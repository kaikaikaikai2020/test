%M_S_momentum VPIN
%{
���Թ���������ң��Կղ֣�������һ�ݺ�Լ�������
ʱ���ж൥������ƽ���ٿ��ղ֡�
���Թ���������ң�����֣�������һ�ݺ�Լ�������
ʱ���пյ�������ƽ���ٿ���֡�
����û���κ������볡���߳���������ֻ�дﵽ�������ʱ�Ż�ƽ��ԭ��
�Ĳ�λ���������ֻ����һ�ݺ�Լ�Ĳ�λ�������ڼӲֵ����������һ����Ϊ��
���Ľ��ײ��ԣ����԰�����������ȷ�Ϻ��Ľ��׹������Ч�ԡ�
t 2011.11-2012.10
%}
close all
clear
load VPIN_day_data.mat
load vpin_para.mat
load VPIN_val.mat

reverse_sel = false;

%true �źŷ�ת
%false �źŲ���ת

y = moving_window_average(VPIN(:,end),50);
y = y./V;

% ����
ini_money = 5e5;
% ����
ts = datenum(2011,11,1);
te = datenum(2012,10,31);
ind = X(:,1)>=ts & X(:,1)<=te;
X = X(ind,:);
Rt = zeros(size(X(:,end)));
Rt(2:end) = (X(2:end,3)-X(1:end-1,3))./X(1:end-1,3);
% �ź�
T = size(X,1);
cut_v = 0.35;
signal2 = zeros(T,1);
xls_re = zeros(T,2);
for i = 2:T-1
    
    if X(i,end)>cut_v &&Rt(i)>0
       signal2(i) = -1;
        continue;
    end
    if X(i,end)>cut_v &&Rt(i)<0
       signal2(i) = 1;
        continue;
    end
  
    signal2(i) = signal2(i-1);
end

if reverse_sel
    temp = signal2;
    signal2(eq(temp,1)) = -1;
    signal2(eq(temp,-1)) = 1;
end

obj1 = tf_bactest();
xls_re(:,1) = signal2;
figure
subplot(2,1,1);
plot(X(:,1),signal2,'LineWidth',2)
datetick('x','yymm')
xlabel('ʱ��')
ylabel('����ź�')
mark_label(gca,'A')
[y_bac,orders] = obj1.simu_bac_method(signal2,X(:,2:3),6.9/10000);
y_bac = ini_money+cumsum(y_bac);
[sta1,sta2,sta_values] = curve_static(y_bac);
subplot(2,1,2);
plot(X(:,1),y_bac/y_bac(1),'LineWidth',2)
datetick('x','yymm')
xls_re(:,2) = y_bac/y_bac(1);
sta_values
xlabel('ʱ��')
ylabel('��ֵ����')
mark_label(gca,'C')
%X(:,end)>quantile_val(:,1)&X(:,end)<quantile_val(:,2)
xls_re = [cellstr(datestr(X(:,1),'yyyymmdd')),num2cell(xls_re)];
xls_re = [{'ʱ��','����ź�','����'};xls_re];
% if ~reverse_sel
%     xlswrite('MS_momentumVPIN.xlsx',xls_re,sprintf('sheet%d',method_sel));
% else
%     xlswrite('MS_momentumVPIN.xlsx',xls_re,sprintf('sheet%d_sigreverse',method_sel));
% end