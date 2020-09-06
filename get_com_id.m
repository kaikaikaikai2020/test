function [C,T_a,T_b] = get_com_id(A,B)
    T_a = numel(A);
    T_b = numel(B);
    A = 1:T_a;
    B = 1:T_b;
    X = repmat(A,numel(B),1);
    Y = repmat(B',numel(A),1);
    C = [X(:),Y];
end