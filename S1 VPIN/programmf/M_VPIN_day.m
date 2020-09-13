%计算日平均VPIN
clear
load VPIN_val.mat

y = moving_window_average(VPIN(:,end),50);
y = y./V;
day_num_all = floor(VPIN(:,2));
day_num = unique(day_num_all);
T = length(day_num);
y_day = zeros(T,2);
for i = 1:T
    sub_x = y(eq(day_num_all,day_num(i)));
    y_day(i,:) = [mean(sub_x),sub_x(end)];
end

load IFmain_all

day_num_all_2 = floor(t);
day_num_2 = unique(day_num_all_2);
T = length(day_num_2);

X = zeros(T,3);
for i = 1:T
    sub_ind = find(eq(day_num_all_2,day_num_2(i)));
    sub_ind = sub_ind([1,end]);
    X(i,:) = [day_num_2(i),p_open(sub_ind(1)),p_close(sub_ind(2))];
end
[~,ia,ib] = intersect(day_num,day_num_2);
X = [X(ib,:),y_day(ia,:)];

X_str = [cellstr(datestr(X(:,1),'yyyy-mm-dd')),num2cell(X(:,2:end))];
X_str = [{'时间','开盘价','收盘价','日均VPIN','收盘VPIN'};X_str];

%xlswrite('VPINdata_day.xlsx',X_str);
