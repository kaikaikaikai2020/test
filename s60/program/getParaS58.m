function [s,r] = getParaS58(y)
%y = fillmissing(y,'previous');
wid_year = 250;
temp = y(2:end,:)./y(1:end-1,:)-1;
%temp(isinf(sum(temp,2))|isnan(sum(temp,2)),:) = [];
temp(isinf(temp)) =0;
temp(isnan(temp)) = 0;
%v(9) = ((mean(temp)-(exp(log(1.03)/252)-1)))/(std(temp))*sqrt(wid_year);
s = (mean(temp))./(std(temp))*sqrt(wid_year); %20200504更新 无风险收益记为0
s(isnan(s)) = -inf;
temp(1,:) = 0;
r = cumprod(1+temp);
r = r(end,:);
