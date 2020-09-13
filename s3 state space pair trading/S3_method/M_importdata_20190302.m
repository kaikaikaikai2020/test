%²¹³äÊý¾Ý
clear
load data_S3.mat

targ_tick = {'sh600109','sz002500'};
var_name = {'5M','15M','30M'};
for i = 1:3
    x =xlsread('ifind_data.xlsx',var_name{i});
    ind1 = strcmp(X{i}.ticket,targ_tick(1));
    ind2 = strcmp(X{i}.ticket,targ_tick(2));
    X{i}.close(ind1)=x(:,1);
    X{i}.close(ind2)=x(:,2);
end
save data20190302 X tref
