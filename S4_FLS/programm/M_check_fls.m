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
sub_t = trade_time<='2011-1-12';
t0 = datenum(trade_time(sub_t));
sub_x  = X(sub_t,[ind1,ind2]);
sub_y = sum(sub_x,2);
sub_x(isnan(sub_y),:) = [];
t0(isnan(sub_y)) = [];
t0_str = cellstr(datestr(t0,'dd-mm-yyyy'));
sub_ind = floor(linspace(1,length(t0),7));

corr(sub_x)
figure
subplot(2,1,1);
plot(sub_x);
legend(sub_targ);
ylabel('股价')
xticks(sub_ind)
xticklabels(t0_str(sub_ind))

d = 0.0001;
u = (1-d)/d;
b_FLS = wgr_fls(sub_x(:,2),sub_x(:,1),u);
b_oFLS = fls_online(sub_x(:,2),sub_x(:,1),u);

yp = sub_x(:,2).*b_FLS;
subplot(2,1,2);
plot([sub_x(:,1),yp]);
legend({'民生银行','民生银行估计值'})
ylabel('股价');
xticks(sub_ind)
xticklabels(t0_str(sub_ind))
figure
subplot(2,1,1);
plot(sub_x(:,1)-yp);
ylabel('残差')
xticks(sub_ind)
xticklabels(t0_str(sub_ind))

subplot(2,1,2)
plot(b_oFLS);
ylabel('beta');
xticks(sub_ind)
xticklabels(t0_str(sub_ind))