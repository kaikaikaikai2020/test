%M_check_data
clear

data_sel = 2;
if eq(data_sel,1)
    load blank_16_data_matrix.mat
else
    load bank16_data_matrix_wind.mat
end

trade_time.Format = 'uuuu-MM-dd HH:mm';
figure
plot(trade_time,X,'linewidth',2);
legend(targ_tick_name,'location','bestoutside')
ylabel('Close price')
set(gca,'fontsize',12);

% figure;
% for i = 1:16
%     subplot(4,4,i);plot(trade_time,X(:,i));
%     title(targ_tick_name{i})
%     ylabel('Close price')
% set(gca,'fontsize',12);
% end

sub_targ = {'民生银行','北京银行'};
ind1 = find(strcmp(targ_tick_name,sub_targ(1)));
ind2 = find(strcmp(targ_tick_name,sub_targ(2)));
sub_t = trade_time<='2011-1-11';
figure
plot(X(sub_t,[ind1,ind2]),'LineWidth',2);
legend(sub_targ);

sub_x  = X(sub_t,[ind1,ind2]);
sub_y = sum(sub_x,2);
sub_x(isnan(sub_y),:) = [];
corr(sub_x)

d = 0.0001;
u = (1-d)/d;
b_FLS = wgr_fls(sub_x(:,2),sub_x(:,1),u);
b_oFLS = fls_online(sub_x(:,2),sub_x(:,1),u);
figure;plot([b_FLS,b_oFLS]);
figure;
plot(sub_x(:,1)-sub_x(:,2).*b_oFLS);
