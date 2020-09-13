%S5窗口参数计算步骤，最好写入数据库
%DMD 变动窗口结果
%update
%原来方法只是比较了本征值大小，大不一定准确率高，需要比较准确率

%2 预留5个交易日窗口，更正原始做法中使用未来信息
clear
%para
num3 = -100;
dN = 'S5';
tn = 'S5_para';
%tradeDate,过去一周，未来一周，正确率，R2，Mu,window
var_info = {'tradingdate','r_b5','r_a5','r1','r2','mu','wid'};


load ticker_300_pool.mat ticker_300 t_300 datenum_300
index_code = '000300';
sql_str_f1 = ['select tradeDate,closeIndex from yuqerdata.yq_index where  ',...
    'symbol = ''%s'' order by tradeDate'];
x= fetchmysql(sprintf(sql_str_f1,index_code),2);

tref_300 = datenum(x(:,1));
close_price_300 = cell2mat(x(:,2));
num_week = 5;
close_price_300_return_f = zeros(size(close_price_300));
close_price_300_return_b = close_price_300_return_f;
for i = num_week+1:length(close_price_300)-num_week
    close_price_300_return_f(i) = close_price_300(i+num_week)/close_price_300(i)-1;
    close_price_300_return_b(i) = close_price_300(i)/close_price_300(i-num_week)-1;
end

sql_str_f2 = 'select tradingdate from S5.S5_para order by tradingdate desc limit 1';
t0 = fetchmysql(sql_str_f2,2);

if isempty(t0)
    t0 = '2007-01-01';
else
    t0 = t0{1};
end
id = tref_300>datenum(t0);
targ_tref = tref_300(id);

T = length(targ_tref);
re = zeros(T,6);
%过去一周收益率，本征值，未来一周收益率
for i = 1:T
    sprintf('begin %d-%d',i,T)
    t0 = targ_tref(i);
    sub_re = get_sub_dmd_result(t0,tref_300,tref_300,close_price_300_return_f,close_price_300_return_b,index_code,num3);
    re(i,:) = sub_re;
    
    sprintf('end %d-%d',i,T)
end
if ~isempty(re)
    re(:,5) = abs(re(:,5));
    re(:,[1:4,6:end]) = real(re(:,[1:4,6:end]));

    re2 = [cellstr(datestr(targ_tref,'yyyy-mm-dd')),num2cell(re)];
    conn = mysql_conn();
    datainsert(conn,sprintf('%s.%s',dN,tn),var_info,re2);
    close(conn)
end




function re = get_sub_dmd_result(t0,tref,tref_300,close_price_300_return_f,close_price_300_return_b,index_code,num3)
    %tref 历史交易时间
    %tref_300 300历史交易时间
    %close_price_300_return_f 300 向前收益率
    %close_price_300_return_b 300 向后收益率
    %ticker_300 300历史股序号
    %t_300 300历史股时间 - 字符
    %datenum_300 300历史时间-数字
    %num3 窗口参数
    w_num =5; %number of week day
    ind = find(eq(tref_300,t0));    
    re = zeros(1,6);
    %[~,ticker] = get_300_tickets_update(t0,ticker_300,t_300,datenum_300);
    ticker = get_index_pool(index_code,datestr(t0,'yyyy-mm-dd'));
    re(1) = close_price_300_return_b(ind);
    re(2) = close_price_300_return_f(ind);   
    
    t3 = get_trading_date_interval(tref,t0,num3*2-w_num); %过去N+5天数据
    [X,~] = get_index_com_data(ticker,t3,length(t3));
    y = close_price_300_return_f(max(1,ind+num3*2-w_num):ind);
    if length(y)<abs(num3*2)+1
        temp = abs(num3*2)+w_num+1-length(y);
        y = [zeros(temp,1);y];
    end
    
    wids = 50:2:100;
    xy_re = zeros(length(wids),3);

    for j = 1:length(wids)
        wid = wids(j);
        xy_data = cell(100,1);
        for k = 1:100        
            sub_X = X(:,end-k-wid+1-w_num:end-k+1-w_num);
            [mu,~,~,R2] = dmd_method(sub_X);            
            if eq(k,1)
                temp = [R2,mu(1,1)];
            else
                temp = [nan,nan];
            end
            xy_data{k} = [temp,abs(mu(1,1)),y(end-k+1-w_num)]';
        end
        xy_data = [xy_data{:}]';
        
        xy_re(j,1) = sum((xy_data(:,3)-1).*xy_data(:,4)>0)/100;
        xy_re(j,2:end) = xy_data(1,1:2);
    end

    [c_v,ia] = max(xy_re(:,1));
    %使用优化参数，计算最新的数值
    sub_wid = wids(ia);
    sub_X = X(:,end-sub_wid:end);
    [mu,~,~,R2] = dmd_method(sub_X);    
    re(3:6) = [c_v,R2,mu(1,1),sub_wid];
    %过去一周，未来一周，正确率，R2，Mu,window
    %1,2,3,4,5
end




