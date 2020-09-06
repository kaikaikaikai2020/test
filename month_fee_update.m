function r_day = month_fee_update(tref,r_day,fee)
if nargin < 3
    fee = 1.5/1000/2;
end
month_end = yq_methods.get_month_end();
[~,ia] = intersect(tref,month_end);
ia1 = [0;ia];
id1 = ia1(1:end-1)+1;
id2 = ia1(2:end);
r_day(id1) = r_day(id1)-fee; 
r_day(id2) = r_day(id2)-fee; 
end