%M_S_momentum VPIN
%{
�������������̼��ж���һ����г����ƣ�������һ�쿪�̼۽��ף�����
�����������źţ����ھ��ߣӸ��ڳ��ھ��ߣ̣��ãģ�ֵ�����վ��֣Уɣεģ���
����������������λ��֮�䣬�����ࣻ����
�����������źţ����ھ��ߣӵ��ڳ��ھ��ߣ̣��ãģ�ֵ�����վ��֣Уɣεģ���
����������������λ��֮�䣬�����գ�����
������ƽ���źţ��ãģ�ֵ�����վ��֣Уɣεģ���������������λ��֮�⣻����
���������ɶ�ͷתΪ��ͷ����ͷתΪ��ͷ��������ƽ�������գ����ࣩ������

�������������������ָ�ڻ�����������Լ������
�������������䣺���������ꣳ�£��������������꣸�£����գ�����
�����������ѣ�ƽ������֮����ţ�����
��������֤�𣱣���������ʼ�ʽ�Ϊ��������
�������޷��������ʣ�����������
%}
close all
clear
load VPIN_day_data.mat
load vpin_para.mat
load VPIN_val.mat

method_sel = 5;reverse_sel = true;
%��ע �����źŷ�ת�ĺ��������Ŀ��ܲ��ԣ���ֻ�ǰ�ѡ��ʱ����ѡ����źŷ��ˣ�������
%��ת�����źţ����ڽ�����������
%1; %���������з������� ֻ�Ⱦ��ߣ�cdfֻ�����վ�VPIN��31-85��λ
%2; %���������з������� ֻ�Ⱦ��ߣ�cdfֻ�����վ� log VPIN��31-85��λ
%3  %����������ѡ�ɷ�ʽ��ʹ���ϴ�������ڣ��´�������� cdfֻ�����վ�VPIN��31-85��λ
%4  %����������ѡ�ɷ�ʽ��ʹ���ϴ�������ڣ��´�������� cdfֻ�����վ�VPIN��5-95��λ
%5  %����������ѡ�ɷ�ʽ��ʹ���ϴ�������ڣ��´�������� VPINֻ�����վ�VPIN��31-85��λ

%true �źŷ�ת
%false �źŲ���ת

y = moving_window_average(VPIN(:,end),50);
y = y./V;

% ����
ini_money = 5e5;
num_L = 27;
num_S = 9;
% ����
ts = datenum(2011,3,1);
te = datenum(2014,8,31);
ind = X(:,1)>=ts & X(:,1)<=te;
X = X(ind,:);
% �ź�
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
%cut_v = [0.05,0.95]; 
if any(eq(method_sel,[1,2,3,5]))
    cut_v=[0.31,0.85];
elseif eq(method_sel,4)
    cut_v = [0.05,0.95];
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
        cdf(i) = logncdf(X(i,5),mx,stdx);
    end
%    quantile_val(i,:) = [quantile(p0,cut_v(1)),quantile(p0,cut_v(2))];
    quantile_val(i,:) = [quantile(sub_x,cut_v(1)),quantile(sub_x,cut_v(2))];
end
signal2 = zeros(T,1);

xls_re = zeros(T,2);
for i = num_L:T-1
    if any(eq(method_sel,[1,2,3,4]))
        test_ind1 = cdf(i,end)>=quantile_val(i,1)&&cdf(i,end)<=quantile_val(i,2);
    elseif eq(method_sel,5)
        test_ind1 = X(i,end)>=quantile_val(i,1)&&X(i,end)<=quantile_val(i,2);
    end    
    
    if any(eq(method_sel,[1,2]))        
        if s_S(i)>s_L(i)
           signal2(i) = 1;
            continue;
        end
        if s_S(i)<s_L(i)
           signal2(i) = -1;
            continue;
        end
    elseif any(eq(method_sel,[3,4,5]))
        if s_S(i)>s_S(i-1) && s_S(i)>s_L(i) && s_S(i-1)>s_L(i-1) && s_S(i-2)<=s_L(i-2) &&test_ind1
            signal2(i) = 1;
            continue;
        end
        if s_S(i)<s_S(i-1) && s_S(i)<s_L(i) && s_S(i-1)<s_L(i-1) && s_S(i-2)>=s_L(i-2) &&test_ind1
            signal2(i) = -1;
            continue;
        end
    end
    if ~test_ind1
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
if ~reverse_sel
    xlswrite('MS_momentumVPIN.xlsx',xls_re,sprintf('sheet%d',method_sel));
else
    xlswrite('MS_momentumVPIN.xlsx',xls_re,sprintf('sheet%d_sigreverse',method_sel));
end