%M_S_momentum
%{
�������������̼��ж���һ����г����ƣ�������һ�쿪�̼۽��ף�����
�����������źţ����ھ��ߣ��ϴ����ھ��ߣ̣������ࣻ����
�����������źţ����ھ��ߣ��´����ھ��ߣ̣������գ�����
������ƽ���źţ��������߳�ƽ��������ͷ�磬��ȫ��ƽ�֣�����
���������ɶ�ͷתΪ��ͷ����ͷתΪ��ͷ��������ƽ�������գ����ࣩ������

�������������������ָ�ڻ�����������Լ������
�������������䣺���������ꣳ�£��������������꣸�£����գ�����
�����������ѣ�ƽ������֮����ţ�����
��������֤�𣱣���������ʼ�ʽ�Ϊ��������
�������޷��������ʣ�����������
%}
clear
load VPIN_day_data.mat
load vpin_para.mat
% ����
ini_money = 5e5;
num_L = 25;
num_S = 9;
% ��ȡ����
ts = datenum(2011,3,1);
te = datenum(2014,8,31);
ind = X(:,1)>=ts & X(:,1)<=te;
X = X(ind,:);
%�����ź�
s_L = moving_window_average(X(:,3),num_L);
s_S = moving_window_average(X(:,3),num_S);
s_L(1:num_L) = 0;
s_S(1:num_S) = 0;
T = length(s_L);
signal = zeros(T,1);
for i = num_L:T-1
    if s_S(i)>s_S(i-1) && s_S(i)>s_L(i) && s_S(i-1)>s_L(i-1) && s_S(i-2)<=s_L(i-2)
        signal(i) = 1;
        continue;
    end
    if s_S(i)<s_S(i-1) && s_S(i)<s_L(i) && s_S(i-1)<s_L(i-1) && s_S(i-2)>=s_L(i-2)
        signal(i) = -1;
        continue;
    end
    signal(i) = signal(i-1);
end
figure
subplot(2,1,1);
plot(X(:,1),signal,'LineWidth',2)
datetick('x','yymm')
xlabel('ʱ��')
ylabel('����ź�')
mark_label(gca,'A')
obj1 = tf_bactest();
[y,orders] = obj1.simu_bac_method(signal,X(:,2:3),6.9/10000);
y = ini_money+cumsum(y);
[sta1,sta2,sta_values] = curve_static(y);
subplot(2,1,2);
plot(X(:,1),y/y(1),'LineWidth',2)
datetick('x','yymm')
check_data = [X,signal,y];
xlabel('ʱ��')
ylabel('��ֵ����')
mark_label(gca,'B')


