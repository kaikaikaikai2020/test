function  [mu,Phi,pred,R2] = dmd_method(X)
%标准化
X = bsxfun(@rdivide,X,X(:,1));
%%%%%%%%%%%%%%%%%%%
%分解
X1 = X(:,1:end-1);
X2 = X(:,2:end);
%奇异值分解
[U,Sigma,V] = svd(X1, 'econ');
%计算特征值
S = U'*X2*V*diag(1./diag(Sigma));
[eV,D] = eig(S);
mu = diag(D);
%特征向量
Phi = U*eV;
%拟合值
pred = Phi*D/Phi*X1(:,end);

R2 = sum((pred-mean(X(:,end))).^2)/sum((X(:,end)-mean(X(:,end))).^2);
end