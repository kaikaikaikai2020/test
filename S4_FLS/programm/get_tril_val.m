function [x,p] = get_tril_val(X)
    m = size(X,1);
    T = m*(m-1)/2;
    x = zeros(T,1);
    p = zeros(T,2);
    c_num = 0;
    for i = 1:m
        sub_x = X(i+1:end,i);
        temp = length(sub_x);
        x(c_num+1:c_num+temp) = sub_x;
        p(c_num+1:c_num+temp,1) = (i+1:m)';
        p(c_num+1:c_num+temp,2) = i;
        
        c_num = c_num+temp;
    end
end