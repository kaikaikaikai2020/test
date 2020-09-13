%{
choose_data(1) 预测者数据
choose_data(2) 您发过来的第二组数据
choose_data(3) 同花顺数据

data_sel = 1;  5分钟数据计算
data_sel = 2;  15分钟数据计算
data_sel = 3;  30分钟数据计算
%}
clear

load data20190302.mat
load svdata20190302.mat

data_sel = 1;
title_str = {'5M','15M','30M'};

write_sel = 0;

filter_signal = 0;
stop_sel = 1;
targ_tick = {'sh600109','sz002500'};
if eq(data_sel,3)
    b = b_M30(:,end);
elseif eq(data_sel,2)
    b = b_M15(:,end);
else
    b = b_M05(:,end);
end

ind1 = strcmp(X{data_sel}.ticket,targ_tick(1));
ind2 = strcmp(X{data_sel}.ticket,targ_tick(2));
t = X{data_sel}.tradingdate(ind1);
t.Format = 'uuuu-MM-dd HH:mm';
x1 = X{data_sel}.close(ind1);
x2 = X{data_sel}.close(ind2);
spread_value = x1 - x2 .* b;
spread_value(1:2) = 0;
ind_model = t<'2013-9-7';

Mspread_value = zeros(size(spread_value));
Mspread_value(ind_model) = spread_value(ind_model)-mean(spread_value(ind_model));
Mspread_value(~ind_model) = spread_value(~ind_model)-mean(spread_value(~ind_model));

std_x = std(Mspread_value(ind_model));
lims2 = std_x * 2;




t_model = t(ind_model);
Mspread_model = Mspread_value(ind_model);
x1_model = x1(ind_model,:);
x2_model = x2(ind_model,:);
T = length(Mspread_model);
index = zeros(T,1);
action_num = index;
record = 0;
ind_record = false(T,1);



for i = 2:T
    test1 = Mspread_model(i)>=std_x&&Mspread_model(i)<lims2;
    test2 = Mspread_model(i)>=-lims2&&Mspread_model(i)<-std_x;
    if eq(stop_sel,1)
        test3 = Mspread_model(i)>=lims2 | Mspread_model(i)<=-lims2;
    else
        test3 = false;
    end
    
    %if eq(i,136);keyboard;end
    
    if  test1
        index(i)=1;
    elseif test2
        index(i) = 2;
    elseif test3
        if eq(filter_signal,1)
            if eq(index(i-1),index(i-2))
                index(i) = -1;
            else
                index(i) = index(i-1);
            end    
        else
            index(i) = -1;
        end
    else
        if eq(index(i-1),1)
            if Mspread_model(i)>0
                index(i) = index(i-1);
            else
                index(i) = 0;
            end
        elseif eq(index(i-1),2)
            if Mspread_model(i)<0
                index(i) = index(i-1);
            else
                index(i) = 0;
            end
        else
            index(i) = 0;
        end
    end  
    
    if eq(record,0)&&index(i)>0
        ind_record(i) = true;
        record = 1;
        action_num(i) = 1;
    end
    if eq(record,1)&&(index(i)<1 || (all(eq(index(i-1:i),[1;2]))) || all(eq(index(i-1:i),[2;1])))
        ind_record(i) = true;
        record = 0;
        action_num(i) = 2;
    end
end
re1 = table(t_model,Mspread_model,index,action_num,x1_model,x2_model);
re2 = re1(ind_record,:);
T = size(re2,1);
method_return = nan(T,1);
cost1 = nan(T,1);
cost2 = nan(T,1);
return1 = nan(T,1);
%re2 = addvars(re2,method_return,cost1,cost2,return1);
temp = table(method_return,cost1,cost2,return1);
re2 = [re2,temp];
t_num = floor(datenum(t_model));
for i = 1:T/2
    s_ind2 = i*2;
    s_ind1 = s_ind2-1;
    f_mark = re2.Mspread_model(s_ind1)<0;
    if f_mark
        f_mark = 1;
    else
        f_mark = -1;
    end
    s_return1 = f_mark*(re2.x1_model(s_ind2)-re2.x1_model(s_ind1))/re2.x1_model(s_ind1);
    s_return2 = -f_mark*(re2.x2_model(s_ind2)-re2.x2_model(s_ind1))/re2.x2_model(s_ind1);
    re2.method_return(s_ind2) = (s_return1+s_return2)*100;
    re2.cost1(s_ind2) = 0.32;
    
    sub_t_num = t_num(t_model>=re2.t_model(s_ind1)&t_model<=re2.t_model(s_ind2));
    sub_t_num = unique(sub_t_num);
    %re2.cost2(s_ind2) = 0.049*(length(sub_t_num)-1);
    re2.cost2(s_ind2) = 0.049*(max(sub_t_num)-min(sub_t_num));
    re2.return1(s_ind2) = re2.method_return(s_ind2)-re2.cost1(s_ind2)-re2.cost2(s_ind2);
    %keyboard 
end

return2 = cumsum(re2.return1(2:2:end));

%validation
t_val = t(~ind_model);
Mspread_val = Mspread_value(~ind_model);
x1_val = x1(~ind_model,:);
x2_val = x2(~ind_model,:);
T = length(Mspread_val);
index2 = zeros(T,1);
action_num2 = index2;
record = 0;
ind_record2 = false(T,1);
for i = 2:T
    test1 = Mspread_val(i)>=std_x&&Mspread_val(i)<lims2;
    test2 = Mspread_val(i)>=-lims2&&Mspread_val(i)<-std_x;
    if eq(stop_sel,1)
        test3 = Mspread_val(i)>=lims2 | Mspread_val(i)<=-lims2;
    else
        test3=false;
    end
   
    
    if  test1
        index2(i)=1;
    elseif test2
        index2(i) = 2;
    elseif test3
        if eq(filter_signal,1)
            if eq(index2(i-1),index2(i-2))
                index2(i) = -1;
            else
                index2(i) = index2(i-1);
            end    
        else
            index2(i) = -1;
        end
    else
        if eq(index2(i-1),1)
            if Mspread_val(i)>0
                index2(i) = index2(i-1);
            else
                index2(i) = 0;
            end
        elseif eq(index2(i-1),2)
            if Mspread_val(i)<0
                index2(i) = index2(i-1);
            else
                index2(i) = 0;
            end
        else
            index2(i) = 0;
        end
    end  
    
    if eq(record,0)&&index2(i)>0
        ind_record2(i) = true;
        record = 1;
        action_num2(i) = 1;
    end
    if eq(record,1)&&(index2(i)<1 || (all(eq(index2(i-1:i),[1;2]))) || all(eq(index2(i-1:i),[2;1])))
        ind_record2(i) = true;
        record = 0;
        action_num2(i) = 2;
    end
end
re3 = table(t_val,Mspread_val,index2,action_num2,x1_val,x2_val);
re4 = re3(ind_record2,:);
T = size(re4,1);
method_return = nan(T,1);
cost1 = nan(T,1);
cost2 = nan(T,1);
return1 = nan(T,1);
%re4 = addvars(re4,method_return,cost1,cost2,return1);
temp = table(method_return,cost1,cost2,return1);
re4 = [re4,temp];


t_num = floor(datenum(t_val));
for i = 1:T/2
    s_ind2 = i*2;
    s_ind1 = s_ind2-1;
    f_mark = re4.Mspread_val(s_ind1)<0;
    if f_mark
        f_mark = 1;
    else
        f_mark = -1;
    end
    s_return1 = f_mark*(re4.x1_val(s_ind2)-re4.x1_val(s_ind1))/re4.x1_val(s_ind1);
    s_return2 = -f_mark*(re4.x2_val(s_ind2)-re4.x2_val(s_ind1))/re4.x2_val(s_ind1);
    re4.method_return(s_ind2) = (s_return1+s_return2)*100;
    re4.cost1(s_ind2) = 0.32;
    
    sub_t_num = t_num(t_val>=re4.t_val(s_ind1)&t_val<=re4.t_val(s_ind2));
    sub_t_num = unique(sub_t_num);
    %re4.cost2(s_ind2) = 0.049*(length(sub_t_num)-1);
    re4.cost2(s_ind2) = 0.049*(max(sub_t_num)-min(sub_t_num));
    re4.return1(s_ind2) = re4.method_return(s_ind2)-re4.cost1(s_ind2)-re4.cost2(s_ind2);
    %keyboard 
end

return3 = cumsum(re4.return1(2:2:end));

[return2(end),return3(end)]

if eq(write_sel,1)
writetable(re1,sprintf('results%s.xlsx',title_str{data_sel}),'sheet','model_detail')
writetable(re2,sprintf('results%s.xlsx',title_str{data_sel}),'sheet','model_result')
writetable(re3,sprintf('results%s.xlsx',title_str{data_sel}),'sheet','val_detail')
writetable(re4,sprintf('results%s.xlsx',title_str{data_sel}),'sheet','val_result')
end