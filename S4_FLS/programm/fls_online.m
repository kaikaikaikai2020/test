function b = fls_online(x,y,u)
    if nargin < 3
        u = 1;
    end
    Ip=1;
    T = length(x);

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
    b(1) = y(1)/x(1);
end