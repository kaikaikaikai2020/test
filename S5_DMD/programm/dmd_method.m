function  [mu,Phi,pred,R2] = dmd_method(X)
%��׼��
X = bsxfun(@rdivide,X,X(:,1));
%%%%%%%%%%%%%%%%%%%
%�ֽ�
X1 = X(:,1:end-1);
X2 = X(:,2:end);
%����ֵ�ֽ�
[U,Sigma,V] = svd(X1, 'econ');
%��������ֵ
S = U'*X2*V*diag(1./diag(Sigma));
[eV,D] = eig(S);
mu = diag(D);
%��������
Phi = U*eV;
%���ֵ
pred = Phi*D/Phi*X1(:,end);

R2 = sum((pred-mean(X(:,end))).^2)/sum((X(:,end)-mean(X(:,end))).^2);
end