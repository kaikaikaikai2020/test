%DMD �䶯���ڽ��
%update
%ԭ������ֻ�ǱȽ��˱���ֵ��С����һ��׼ȷ�ʸߣ���Ҫ�Ƚ�׼ȷ��

%2 Ԥ��5�������մ��ڣ�����ԭʼ������ʹ��δ����Ϣ
clear

load ticker_300_pool.mat ticker_300 t_300 datenum_300

[~,~,x] = xlsread('sz399300.xlsx');

tref_300 = datenum(x(2:end,2));
close_price_300 = cell2mat(x(2:end,4));
num_week = 5;
close_price_300_return_f = zeros(size(close_price_300));
close_price_300_return_b = close_price_300_return_f;
for i = num_week+1:length(close_price_300)-num_week
    close_price_300_return_f(i) = close_price_300(i+num_week)/close_price_300(i)-1;
    close_price_300_return_b(i) = close_price_300(i)/close_price_300(i-num_week)-1;
end

tref = xlsread('tref.xlsx');
num3 = -100;

t0 = datenum(2005,7,1);
tt = datenum(2017,3,1);

targ_tref = tref(tref>=t0&tref<=tt);

T = length(targ_tref);

re = zeros(T,6);
%��ȥһ�������ʣ�����ֵ��δ��һ��������
for i = 1:T
    tic
    sprintf('begin %d-%d',i,T)
    t0 = targ_tref(i);
    sub_re = get_sub_dmd_result(t0,tref,tref_300,close_price_300_return_f,close_price_300_return_b,ticker_300,t_300,datenum_300,num3);
    re(i,:) = sub_re;
    
    sprintf('end %d-%d',i,T)
    toc
end

function re = get_sub_dmd_result(t0,tref,tref_300,close_price_300_return_f,close_price_300_return_b,ticker_300,t_300,datenum_300,num3)
    %tref ��ʷ����ʱ��
    %tref_300 300��ʷ����ʱ��
    %close_price_300_return_f 300 ��ǰ������
    %close_price_300_return_b 300 ���������
    %ticker_300 300��ʷ�����
    %t_300 300��ʷ��ʱ�� - �ַ�
    %datenum_300 300��ʷʱ��-����
    %num3 ���ڲ���
    w_num =5; %number of week day
    ind = find(eq(tref_300,t0));    
    re = zeros(1,6);
    [~,ticker] = get_300_tickets_update(t0,ticker_300,t_300,datenum_300);
    re(1) = close_price_300_return_b(ind);
    re(2) = close_price_300_return_f(ind);   
    
    t3 = get_trading_date_interval(tref,t0,num3*2-w_num); %��ȥN+5������
    [X,~] = get_history_300_data(ticker,t3(1),t3(end),length(t3));
    y = close_price_300_return_f(max(1,ind+num3*2-w_num):ind);
    if length(y)<abs(num3*2)+1
        temp = abs(num3*2)+w_num+1-length(y);
        y = [zeros(temp,1);y];
    end
    
    wids = 50:2:100;
    xy_re = zeros(length(wids),3);
    for j = 1:length(wids)
        wid = wids(j);
        xy_data = zeros(100,2);
        for k = 1:100        
            sub_X = X(:,end-k-wid+1-w_num:end-k+1-w_num);
            [mu,~,~,R2] = dmd_method(sub_X);
            xy_data(k,:) = [abs(mu(1,1)),y(end-k+1-w_num)];
            if eq(k,1)
                xy_re(j,2:end) = [R2,mu(1,1)];
            end
        end
        xy_re(j,1) = sum((xy_data(:,1)-1).*xy_data(:,2)>0)/100;
    end
    [c_v,ia] = max(xy_re(:,1));
    %ʹ���Ż��������������µ���ֵ
    sub_wid = wids(ia);
    sub_X = X(:,end-sub_wid:end);
    [mu,~,~,R2] = dmd_method(sub_X);    
    re(3:6) = [c_v,R2,mu(1,1),sub_wid];
    %��ȥһ�ܣ�δ��һ�ܣ���ȷ�ʣ�R2��Mu,window
    %1,2,3,4,5
end




