clear
T = 600;

ebzu = -2 + (2+2)*rand(T,1);
v =  wgn(T,1,0);

x = zeros(T,1);
for i = 2:T
    x(i) = 2+0.9*x(i-1);
end
x = x+v;

beta = zeros(T,1);
at = randn(T,1);
at = at/std(at)*0.1;
bt = randn(T,1);
bt = bt/std(bt)*0.03;
ct =-1 + (1+1)*rand(T,1);
for i = 1:T
    if eq(i,1)
        beta(i) = 3;        
    elseif i>1 && i<200
        beta(i) = beta(i-1)+at(i);
    elseif eq(i,200)
        beta(i) = beta(i-1)+2;
    elseif i>=201&&i<=400
        beta(i) = beta(i-1)+bt(i);
    else
        beta(i) = 2*sin(0.05*i)+ct(i);
    end
end
plot(beta)

y = x.*beta + ebzu;

u = (1-0.00001)/0.00001;
b = fls_online(x,y,u);
b_FLS = wgr_fls(x,y,u);

plot([beta,b,b_FLS],'LineWidth',1);
legend({'simu','on-line','off-line'})