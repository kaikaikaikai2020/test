%FLS strategy
clear

%dat_sel 1 Ԥ����  2 wind
data_sel = 2;
if eq(data_sel,1)
    load blank_16_data_matrix.mat
else
    load bank16_data_matrix_wind.mat
end
%set date format
trade_time.Format = 'uuuu-MM-dd HH:mm';

%set parameters
p_window = 5; %Ͷ������
p_deta1 = 2;  %��ͷ����
p_deta2 = -p_deta1; %��ͷ����
p_deta3 = 0.1; %ƽ�ֲ���

ebzu = 0.0001;  %FLS ����1
u = (1-ebzu)/ebzu; %FLS ����2

trade_time_num = datenum(trade_time);  
trade_time_day = unique(floor(trade_time_num));

%��ʼ�� ��ȡ��ʷ������
T = length(trade_time_num);
s_t0 = floor(trade_time_num(1));
s_tt_M = get_end_day(trade_time_day,s_t0,p_window);
i1 = find(trade_time_num>=s_tt_M,1);
start_num = i1;
%initial model
sub_x = X(1:i1-1,:);
sub_model_re = fls_spread(sub_x,ebzu);%��ԣ�����spread
sub_spread = sub_model_re.spread;
%��ȡͶ��������
s_tt_E = get_end_day(trade_time_day,s_tt_M,p_window);

%��ʼ������
sta_results = zeros(T,8); %���̽��
spread_all = zeros(T,1); %spread
s_signal = zeros(T,1); %signal
for i = start_num:T
    sta_results(i,1:4) = [sub_model_re.alfa,sub_model_re.beta(end),sub_model_re.p];
    sub_x = X(i,sub_model_re.p);
    sta_results(i,7:8) = sub_x;
    if any(isnan(sub_x)) %�����ͣ�ƣ�������һѭ��
        continue
    end
    %����beta
    sub_x_add = X(i1:i,sub_model_re.p);
    sub_x_add = sub_x_add(~isnan(sum(sub_x_add,2)),:);
    sub_b = fls_online([sub_model_re.x;sub_x_add(:,2)],[sub_model_re.y;sub_x_add(:,1)],u);
    %����spread
    spread_all(i) = sub_x(:,1)-sub_x(:,2)*sub_b(end);
    sta_results(i,2) = sub_b(end);
    %update mx std
    sub_spread_add = spread_all(i1:i);
    sub_spread_add = sub_spread_add(~eq(sub_spread_add,0)&~isnan(sub_spread_add));
    sub_mx = mean([sub_spread;sub_spread_add]);
    sub_std = std([sub_spread;sub_spread_add]);
    %signal 
    sub_std_spread = (spread_all(i)-sub_mx)/sub_std;
    if eq(s_signal(i-1),1)
        if spread_all(i)-sub_mx>0 && sub_std_spread > p_deta3 %�����ź�����
            s_signal(i) = 1;
        else
            if sub_std_spread < p_deta2 %�źŷ�ת
                s_signal(i) = -1;
            else %����
                s_signal(i) = 0;
            end
        end
    elseif eq(s_signal(i-1),-1)
        if spread_all(i)-sub_mx<0 && abs(sub_std_spread) > p_deta3 %�����ź�����
            s_signal(i) = -1;
        else
            if sub_std_spread > p_deta1 %�źŷ�ת
                s_signal(i) = 1;
            else
                s_signal(i) = 0; %����
            end
        end
    else
        if sub_std_spread < p_deta2 %��
            s_signal(i) = -1;
        elseif sub_std_spread > p_deta1 %��
            s_signal(i) = 1;
        else
            s_signal(i) = 0;
        end
    end
    sta_results(i,5:6) = [sub_std_spread,s_signal(i)]; %����
    
    if trade_time_num(i)>= s_tt_E   %Ͷ�������Ƿ��ѵ�
        %data
        sub_x = X(i1:i-1,:);
        %update model
        sub_model_re = fls_spread(sub_x,ebzu);
        sub_spread = sub_model_re.spread;
        i1=i;
        s_tt_E_old = s_tt_E;
        s_tt_E = get_end_day(trade_time_day,s_tt_E,p_window);%����Ͷ������
        sta_results(i,6) = nan;%��ֹ�Ǻ�
    end 
end
sta_results(end,6) = nan;%��ֹ�Ǻ�
%static return
[re,pos_re] =sta_get_position(sta_results);
cash_flow = sum(pos_re,2);
subplot(2,1,1);
plot(trade_time,cash_flow/cash_flow(1),'linewidth',2);
%plot(cash_flow/cash_flow(1),'linewidth',2);
title('��ʱ���');
cash_flow_day = zeros(size(trade_time_day));
trade_time_day_all = floor(trade_time_num);
temp = [0;diff(cash_flow)];
for i = 1:length(cash_flow_day)
    cash_flow_day(i) = sum(temp(eq(trade_time_day_all,trade_time_day(i))));
end
cash_flow_day = cash_flow(1)+cumsum(cash_flow_day);
subplot(2,1,2);
plot(cash_flow_day/cash_flow_day(1),'linewidth',2);
title('ÿ�ս��')
[v,v_str,sta_val] = curve_static(cash_flow_day);
sprintf('�껯������: %0.2f%%',sta_val.nh*100)
sprintf('Sharp-value: %0.2f (�޷���������3%%)',sta_val.sharp)



function tt = get_end_day(trade_time_day,t0,p_window)
    ind= find(trade_time_day>=t0,1);
    if ind+p_window-1>=length(trade_time_day)
        tt = trade_time_day(end)+1;
    else
        tt = trade_time_day(ind+p_window);
    end
end


