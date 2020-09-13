%M_check_data
clear

data_sel = 2;
if eq(data_sel,1)
    load blank_16_data_matrix.mat
else
    load bank16_data_matrix_wind.mat
end

trade_time.Format = 'uuuu-MM-dd HH:mm';

sub_targ = {'民生银行','北京银行'};
ind1 = find(strcmp(targ_tick_name,sub_targ(1)));
ind2 = find(strcmp(targ_tick_name,sub_targ(2)));
sub_t = trade_time<='2011-1-11';

sub_x  = X(sub_t,[ind1,ind2]);
sub_y = sum(sub_x,2);
sub_x(isnan(sub_y),:) = [];

[h,pValue,stat,cValue,reg] = egcitest(sub_x);
a = reg.coeff(1);
b = reg.coeff(2);
resi = sub_x(:,1)-(sub_x(:,2)*b+a);
figure;plot(resi-reg.res);
