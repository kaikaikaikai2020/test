function re = fls_spread(sub_x,ebzu)

re = [];
%corr results
sub_r1 = corr(sub_x);
sub_r1(isnan(sub_r1))=0;
[sub_r2,sub_p] = get_tril_val(sub_r1);
%ÅÅĞò
[~,ia] = sort(sub_r2,'descend');
sub_p3 = sub_p(ia,:); 
% delete nan data
y = sub_x(:,sub_p3(1,1));
x = sub_x(:,sub_p3(1,2));
ind = ~isnan(x+y);
y = y(ind);
x = x(ind);
%fls results
u = (1-ebzu)/ebzu;
b = fls_online(x,y,u);
re.spread = y-x.*b;
re.beta = b;
re.alfa = 0;
re.y = y;
re.x = x;
re.p = sub_p3(1,:);
end