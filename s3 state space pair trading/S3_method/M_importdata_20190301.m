%补充数据
clear
% pn = 'H:\datasets\历史分钟数据\历史分钟数据\2013\2013-07-01';
% fn = '2013-07-01 5min.csv';
var_name = {'ticket','tradingdate','open','high','low','close','volume','amount'};
var_type = [{'string','datetime'},repmat({'double'},1,6)];

[~,~,x] = xlsread('SZ002500整理.xlsx');
t1 = datenum(x(2:end,1),'yyyy/mm/dd');
t2 = datenum(cellfun(@num2str,x(2:end,2),'UniformOutput',false),'HHMM');
t3 = t1 + (t2-floor(t2));
t3 = cellstr(datestr(t3,'yyyy-mm-dd HH:MM'));
T = size(x,1)-1;
X = cell(T,8);
X(:,1) = {'sz002500'};
X(:,2) = t3;
X(:,3:8) = x(2:end,3:8);
t = datetime(X(:,2),'InputFormat','uuuu-MM-dd HH:mm');
sub_X1 = cell2table(X(:,1),'VariableNames',var_name(1));
sub_X2 = table(t,'VariableNames',var_name(2));
sub_X3 = cell2table(X(:,3:end),'VariableNames',var_name(3:end));
X1 = [sub_X1,sub_X2,sub_X3];

[~,~,x] = xlsread('SH600109.csv');
t1 = datenum(x(2:end,1),'yyyy/mm/dd');
t2 = datenum(cellfun(@num2str,x(2:end,2),'UniformOutput',false),'HHMM');
t3 = t1 + (t2-floor(t2));
t3 = cellstr(datestr(t3,'yyyy-mm-dd HH:MM'));
T = size(x,1)-1;
X = cell(T,8);
X(:,1) = {'sh600109'};
X(:,2) = t3;
X(:,3:8) = x(2:end,3:8);
t = datetime(X(:,2),'InputFormat','uuuu-MM-dd HH:mm');
sub_X1 = cell2table(X(:,1),'VariableNames',var_name(1));
sub_X2 = table(t,'VariableNames',var_name(2));
sub_X3 = cell2table(X(:,3:end),'VariableNames',var_name(3:end));
X2 = [sub_X1,sub_X2,sub_X3];
X{1} = [X1;X2];



%xlswrite('tempSZ002500.xlsx',X)
%X1 = cell2table(X,'VariableNames',var_name);
