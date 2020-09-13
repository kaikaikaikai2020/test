function re = model_cointegration(sub_x)
warning('off')
re = [];
%del nan_values
%sub_x(isnan(sum(sub_x,2)),:) = [];
%corr results
sub_r1 = corr(sub_x);
sub_r1(isnan(sub_r1))=0;
[sub_r2,sub_p] = get_tril_val(sub_r1);
%����
[sub_r3,ia] = sort(sub_r2,'descend');
sub_p3 = sub_p(ia,:); 
%���Э��
sub_h = false;
i = 1;
while ~sub_h && i <= length(sub_r3)
    [sub_h,~,~,~,reg] = egcitest(sub_x(:,sub_p3(i,:)));
    re.p = sub_p3(i,:);
    i = i + 1;
end
%��ȡ����
sub_alfa = reg.coeff(1);
sub_beta = reg.coeff(2);
sub_spread =reg.res;
re.alfa = sub_alfa;
re.beta = sub_beta;
re.spread = sub_spread;

warning('on')
end