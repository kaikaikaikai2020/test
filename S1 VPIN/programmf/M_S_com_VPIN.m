%M_S_ com VPIN
%{
�������������̼��ж���һ����г����ƣ�������һ�쿪�̼۽��ף�����
�����������źţ����ھ��ߣӣ͸��ڳ��ھ��ߣ̣ͣ��ãģ�ֵ���ڣ֣Уɣεģ�����������
��������λ��֮�䣻����ھ��ߣӣҵ��ڳ��ھ��ߣ̣ң��ãģ�ֵ���ڣ֣УɣΣ���
�ģ�������λ���������ࣻ����
�����������źţ����ھ��ߣӣ���ڳ��ھ��ߣ̣ͣ��ãģ�ֵ���ڣ֣Уɣεģ�����������
��������λ��֮�䣻����ھ��ߣӣҸ��ڳ��ھ��ߣ̣򣬣ãģ�ֵ���ڣ֣УɣΣ���
�ģ�������λ���������գ�����
������ƽ���źţ��ãģ�ֵ���ڣ֣Уɣεģ���������������λ��֮�����ڣ֣Уɣεģ���
��������λ��������
���������ɶ�ͷתΪ��ͷ����ͷתΪ��ͷ��������ƽ�������գ����ࣩ������
���������̣��ӣͺ̣ͣ򡢣ӣҷֱ������ڣ֣УɣεĶ������Ժͷ�ת���Ե����ţ���
������ϣ���ǰ�Ŀ�֪���̣��������ӣ��������̣򣽣������ӣ򣽣���������


�������������������ָ�ڻ�����������Լ������
�������������䣺���������ꣳ�£��������������꣸�£����գ�����
�����������ѣ�ƽ������֮����ţ�����
��������֤�𣱣���������ʼ�ʽ�Ϊ��������
�������޷��������ʣ�����������
%}

clear
load VPIN_day_data.mat
load vpin_para.mat
load VPIN_val.mat

method_sel =5;reverse_sel = true;
%��ע �����źŷ�ת�ĺ��������Ŀ��ܲ��ԣ���ֻ�ǰ�ѡ��ʱ����ѡ����źŷ��ˣ�������
%��ת�����źţ����ڽ�����������
%method_sel
%1; %���������з������� ֻ�Ⱦ��ߣ�cdfֻ�����վ�VPIN��31-85\29��λ
%2; %���������з������� ֻ�Ⱦ��ߣ�log cdfֻ�����վ�VPIN��31-85\29��λ
%3  %����������ѡ�ɷ�ʽ��ʹ���ϴ�������ڣ��´�������� cdfֻ�����վ�VPIN��31-85\29��λ
%4  %����������ѡ�ɷ�ʽ��ʹ���ϴ�������ڣ��´�������� cdfֻ�����վ�VPIN��5-95\40��λ
%5  %����������ѡ�ɷ�ʽ��ʹ���ϴ�������ڣ��´�������� VPINֻ�����վ�VPIN��31-85\29��λ

%reverse_sel
%true �źŷ�ת
%false �źŲ���ת

%true �źŷ�ת
%false �źŲ���ת

y = moving_window_average(VPIN(:,end),50);
y = y./V;

%
num_L = 27;
num_S = 9;
num_L2 = 28;
num_S2 = 26;

ini_money = 5e5;
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

s_L2 = moving_window_average(X(:,3),num_L2);
s_S2 = moving_window_average(X(:,3),num_S2);
s_L2(1:num_L2) = 0;
s_S2(1:num_S2) = 0;

T = length(s_L);

obj1 = tf_bactest();

%section VPIN
quantile_val = zeros(size(X,1),3);
cdf = zeros(size(X(:,1)));

ind = VPIN(:,1)>=datenum(2013,6,24)&VPIN(:,1)<datenum(2013,6,26);
sub_y = [VPIN(ind,1),y(ind)];
subp1 = p1(ind);
ind1 =VPIN(:,1)<datenum(2013,6,24);
parmhat = lognfit(y(ind1));
mx = parmhat(1);
stdx = parmhat(2);
%cut_v = [0.05,0.95]; 
if any(eq(method_sel,[1,2,3,5]))
    cut_v=[0.31,0.85,0.29];
elseif eq(method_sel,4)
    cut_v=[0.05,0.95,0.4];
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
    quantile_val(i,:) = [quantile(sub_x,cut_v(1)),quantile(sub_x,cut_v(2)),quantile(sub_x,cut_v(3))];
end
signal2 = zeros(T,1);
for i = num_L:T-1
    if any(eq(method_sel,[1,2,3,4]))
         tempx = cdf(i,end);%test_ind2 = cdf(i,end)<quantile_val(i,1);
    elseif eq(method_sel,5)
         tempx = X(i,end);%test_ind2 = X(i,end)<quantile_val(i,1);
    end    
    
    test_ind1 = tempx>=quantile_val(i,1)&&tempx<=quantile_val(i,2);
    test_ind2 = tempx<quantile_val(i,3);
    test_ind3 = (tempx>=quantile_val(i,3)&&tempx<=quantile_val(i,1))|(tempx>=quantile_val(i,2));
    
   test_a1 = s_S(i)>s_S(i-1) && s_S(i)>s_L(i) && s_S(i-1)>s_L(i-1) && s_S(i-2)<=s_L(i-2);
   test_a2 = (s_S(i)<s_S(i-1) && s_S(i)<s_L(i) && s_S(i-1)<s_L(i-1) && s_S(i-2)>=s_L(i-2));
   test_indb1 = s_S2(i)<s_S2(i-1) && s_S2(i)<s_L2(i) && s_S2(i-1)<s_L2(i-1) && s_S2(i-2)>=s_L2(i-2);
   test_indb2 = s_S2(i)>s_S2(i-1) && s_S2(i)>s_L2(i) && s_S2(i-1)>s_L2(i-1) && s_S2(i-2)<=s_L2(i-2);
    
    if any(eq(method_sel,[1,2]))        
        if (s_S(i)>s_L(i)&&test_ind1) || (s_S2(i)<s_L2(i)&&test_ind2)
            signal2(i) = 1;
            continue;
        end
        if  (s_S(i)<s_L(i) &&test_ind1)  || (s_S2(i)>s_L2(i)&&test_ind2)
           signal2(i) = -1;
            continue;
        end
    elseif any(eq(method_sel,[3,4,5]))
        if (test_a1&&test_ind1) || (test_indb1&&test_ind2)
            signal2(i) = 1;
            continue;
        end
        if  test_a2 &&test_ind1  || (test_indb2&&test_ind2)
           signal2(i) = -1;
            continue;
        end
    end
       
    if test_ind3
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
xlabel('ʱ��')
ylabel('����ź�')
mark_label(gca,'A')
[y_bac,orders] = obj1.simu_bac_method(signal2,X(:,2:3),6.9/10000);
y_bac = ini_money+cumsum(y_bac);
[sta1c,sta2c,sta_valuesc] = curve_static(y_bac);
subplot(2,1,2);
plot(X(:,1),y_bac/y_bac(1),'LineWidth',2)
datetick('x','yymm')
check_data = [X,signal2,y_bac];
sharpe(y_bac(2:end)./y_bac(1:end-1)-1,3/100)
xlabel('ʱ��')
ylabel('��ֵ����')
mark_label(gca,'C')
%X(:,end)>quantile_val(:,1)&X(:,end)<quantile_val(:,2)

xls_re = [signal2,y_bac];
xls_re = [cellstr(datestr(X(:,1),'yyyymmdd')),num2cell(xls_re)];
xls_re = [{'ʱ��','����ź�','����'};xls_re];
if ~reverse_sel
    xlswrite('MS_momentumComVPIN.xlsx',xls_re,sprintf('sheet%d',method_sel));
else
    xlswrite('MS_momentumComVPIN.xlsx',xls_re,sprintf('sheet%d_sigreverse',method_sel));
end