function X = fls(A, b, mu, ncap, smoothed)

if isempty(mu)
    mu = 1;
end

if isempty(ncap)
    ncap = length(b);
end

if isempty(smoothed)
    smoothed = true;
end

[m,n] = size(A);

M = zeros(n, n, ncap);
E = zeros(n, ncap);
X = zeros(n, ncap);
R = eye(n) * mu;

for j = 1:ncap
    Z = linsolve( qr( R + tcrossprod(A(j,:)) ), eye(n) );
    M(:,:,j) = mu * Z;               % (5.7b)
    v = b(j) * A(j,:);

    if (j == 1) 
        p = zeros(n,1);
    else
        p = mu * E(:,j-1);
    end

    w = p + v;

    E(:,j) = Z * w;                  % (5.7c)
    R = -mu * mu * Z;

    diag_ind = eq(eye(size(R)),1);
    R(diag_ind) = R(diag_ind) + 2*mu;
end

% Calculate eqn (5.15) FLS estimate at ncap
Q = -mu * M(:,:,ncap-1);

diag_ind = eq(eye(size(Q)),1);
Q(diag_ind) = Q(diag_ind)+mu;
Ancap = A(ncap,:);

C = Q + Ancap' * Ancap;
d = mu * E(:,ncap-1) + b(ncap)*Ancap';
X(:,ncap) = C * d;
X(:,ncap) = linsolve(qr(C),d);

if smoothed
    % Use eqn (5.16) to obtain smoothed FLS estimates for
    % X[,1], X[,2], ..., X[,ncap-1]

    for j = 1:ncap-1
        l = ncap - j;
        X(:,l) = E(:,l) + M(:,:,l) * X(:,l+1);
    end
else
    X = X(:,ncap);
end

end

function resp = tcrossprod(A)
resp = A * A';
end