%M_check_data
clear
data_sel = 2;
if eq(data_sel,1)
    load blank_16_data_matrix.mat
else
    load bank16_data_matrix_wind.mat
end

trade_time.Format = 'uuuu-MM-dd HH:mm';
tref_all = datenum(trade_time);
tref = unique(floor(tref_all));
T = length(tref);
wid= 60;

re_corr = zeros(T,size(X,2));

for i = wid
    sub_t0 = tref(i-wid+1);
    sub_t1 = tref(i)+1;
    sub_ind = tref_all>sub_t0&tref_all<sub_t1;
    sub_X = X(sub_ind,:);
    sub_X = sub_X(~isnan(sum(sub_X,2)),:);
    r = corr(sub_X);
    r1 = tril(r,-1);
    
end

sub_t0 = 0;
sub_t1 = datenum(2011,1,11)+1;
sub_ind = tref_all>sub_t0&tref_all<sub_t1;
sub_X = X(sub_ind,:);
sub_X = sub_X(~isnan(sum(sub_X,2)),:);
r3 = corr(sub_X);
r4 = tril(r3,-1);
r5 = r4(:);
r5 = r5(~eq(r5,0));
figure
histogram(r5)
re = r_static(r5);
function re = r_static(r)
V = [0.9,0.92,0.95,0.97,0.98];
re = zeros(size(V));
for i = 1:length(re)
    re(i) = sum(r>V(i));
end
end