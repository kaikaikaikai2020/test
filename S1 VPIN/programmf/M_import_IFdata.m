%import IF data
clear
fn = 'F:\works2019\SOME\项目\VPIN\CSI300 and future 1min data\IF\IF主力连续.csv';
[~,~,X] = xlsread(fn);

t_date = X(2:end,3);
t = datenum(X(2:end,3));
p_open = cell2mat(X(2:end,4));
p_high = cell2mat(X(2:end,5));
p_low = cell2mat(X(2:end,6));
p_close = cell2mat(X(2:end,7));
volume = cell2mat(X(2:end,8));
trading_volume = cell2mat(X(2:end,9));
position = cell2mat(X(2:end,10));

%save IFmain_all t p_open p_high p_low p_close volume trading_volume position t_date