function [X,b_M05,b_M15,b_M30] = choose_data(data_sel)

if eq(data_sel,1)
    load data_S3 X
    load sv b_M05 b_M15 b_M30
elseif eq(data_sel,2)
    load data_S3_add.mat X
    load sv_data2 b_M05
    b_M15 = [];
    b_M30 = [];
    tt_data = {'2013-7-1','2013-10-22','2013-9-7'};
    tt1 = tt_data{1};
    tt2 = tt_data{2};

    X{1} = X{1}(X{1}.tradingdate>= tt1 &X{1}.tradingdate<= tt2,:);
else
    load data20190302.mat X
    load svdata20190302.mat b_M05 b_M15 b_M30
end