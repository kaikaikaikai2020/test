clear
T = 20;
x = (1:T)';
%b0 = ones(T,1)*2;
b0=2+rand(T,1);
y = x.*b0;
u = 1;
Ip=1;

b = zeros(T,1);
s = zeros(T+1,1);
S = s;
s0=1;
S0=1;
for i = 1:T
    if i > 1
        S(i) = u/((S(i-1)+u*Ip+x(i)*x(i)))*(S(i-1)+x(i)*x(i));
        s(i) = u/((S(i-1)+u*Ip+x(i)*x(i)))*(s(i-1)+x(i)*y(i));
        b(i) = 1/(S(i-1)+x(i)*x(i))*(s(i-1)+x(i)*y(i));
    else
        S(i) = u/((S0+u*Ip+x(i)*x(i)))*(S0+x(i)*x(i));
        s(i) = u/((S0+u*Ip+x(i)*x(i)))*(s0+x(i)*y(i));
        b(i) = 1/(S0+x(i)*x(i))*(s0+x(i)*y(i));
    end
end

b_FLS = wgr_fls(x,y,1);

plot([b0,b,b_FLS]);