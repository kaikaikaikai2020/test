%{
要点
1 平仓再执行
2 asia us 初值都是0.5，各自执行各自的

3 每次都进行再平衡

印度亚洲和美国手续费买卖各万分之一，
台湾亚洲买万分之三，卖万分之三十三。美国买卖都是万分之一。
%}

clear
close all
load data20201027.mat
symbol_pair = {'INFO','INFY','IRN_1M';'TT2330','TSM','NTN_1m'};

fee0 = [];
fee0.IN=[1/10000,1/10000];
fee0.TT = [3/10000,33/10000];
fee0.US=[1/10000,1/10000];

fees = {'IN','US';'TT','US'};

T1 = size(symbol_pair,1);
W0=20;
cut_v=1.5;
W = [W0-1,0];
f_str1 = '%s:开盘:溢价%0.4f，上限阈值%0.4f，下限阈值%0.4f %s';
f_str2 = '%s:开盘平，持有价~亚：%0.2f,US：%0.2f，平仓价~亚洲：%0.2f,US：%0.2f，收益：亚%0.4f，US%0.4f';
f_str3 = '%s:收盘平，持有价~亚：%0.2f，平仓价~亚洲：%0.2f,收益：亚%0.4f';
for i0 =1:1%T1
    recorder = strAdd();
    %data loading
    sym1 = symbol_pair{i0,1};
    sym2 = symbol_pair{i0,2};
    sym3 = symbol_pair{i0,3};
    title_str = sprintf('%s-%s',sym1,sym2);
    fn = sprintf('ADR平仓信号1模式1-执行仓单%s_阈值%0.2f.xlsx',title_str,cut_v);
    x1 = data.(sym1);
    x2 = data.(sym2);
    x3 = data.(sym3);
    
    sub_fee1 = fee0.(fees{i0,1});
    sub_fee2 = fee0.(fees{i0,2});
    
    sub_fee_com = [sub_fee1',sub_fee2'];    
    
    tref = x1.tref;
    open_asia = x1.data(:,2);
    close_us = x2.data(:,1);
    p = x3.data(:,2);
    %signal
    boll = zeros(size(close_us));
    boll(2:end) = close_us(1:end-1).*p(2:end)./open_asia(2:end)-1;
    %boll(2:end) = boll(1:end-1);
    
    M = movmean(boll,W);
    S = movstd(boll,W);
    L = M-S*cut_v;
    H = M+S*cut_v;

    T2 =length(boll);
    pos=zeros(T2,2);
    %亚洲买入,美国买入
    y  = zeros(T2,2);
    yf = zeros(T2,1);
    for i = W0:T2
        %开盘统计
        sub_pos1 = pos(i-1,:);%昨日仓位价格
        sub_pos2 = [x1.data(i,2),x2.data(i,2)];%今日开盘价格
        sub_pos3 = x1.data(i,1);%今日亚洲收盘价格
        if boll(i)>H(i)
            recorder.A(sprintf(f_str1,tref{i},boll(i),H(i),L(i),'超过上限'));
            %符合平仓条件，开盘平仓            
            if any(~eq(sub_pos1,0))
                r = get_ret(sub_pos1,sub_pos2,sub_fee_com);
                recorder.A(sprintf(f_str2,tref{i},sub_pos1,sub_pos2,r));
                 %记录收益
                y(i,:) = y(i,:)+r;
                sub_pos1(:) = 0;
            end
            %符合开仓条件，开仓
            pos(i,1)=sub_pos2(1);
            %收盘统计
            temp_r = get_ret0(pos(i,1),sub_pos3,sub_fee1);
            if temp_r>0 %收盘收益大于0
                y(i,1) = y(i,1)+temp_r; %记录收益
                yf(i) = yf(i)+temp_r/2;
                recorder.A(sprintf(f_str3,tref{i},pos(i,1),sub_pos3,temp_r));
                pos(i,1) = 0; %平仓
            else
                pos(i,2) = -sub_pos2(2); %买入美国股票
            end
        elseif boll(i)<L(i)
            recorder.A(sprintf(f_str1,tref{i},boll(i),H(i),L(i),'跌过下限'));
            %符合平仓条件，开盘平仓 
            if any(~eq(sub_pos1,0))
                r = get_ret(sub_pos1,sub_pos2,sub_fee_com);
                recorder.A(sprintf(f_str2,tref{i},sub_pos1,sub_pos2,r));
                y(i,:)=y(i,:)+r;
                sub_pos1(:) = 0;
            end
            %符合开仓条件，开仓
            pos(i,1)=-sub_pos2(1);
            %收盘统计
            temp_r = get_ret0(pos(i,1),sub_pos3,sub_fee1); % 收盘收益大于0
            if temp_r>0
                y(i,1) = y(i,1)+temp_r;
                recorder.A(sprintf(f_str3,tref{i},pos(i,1),sub_pos3,temp_r));
                pos(i,1) = 0;
            else
                pos(i,2) = sub_pos2(2);
            end
        else
            %保持
            pos(i,:) = sub_pos1;
        end
    end
    y = y./2;
    %y1 = cumprod(1+sum(y,2));
    yc = [cumprod(1+y),cumprod(1+sum(y,2))];
    
    h = figure_S53(yc,tref,title_str,1);
    legend({sym1,sym2,[sym1,'-',sym2]},'NumColumns',3,'location','best');
    xlswrite(fn,recorder.str1);
end


