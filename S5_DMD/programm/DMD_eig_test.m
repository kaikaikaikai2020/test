clear
load test_data2015.mat
%load test_data2015_update.mat

t = 1:size(X,2);
dt = 1;
a = mapminmax(X);
a = max(a,[],2);

X(a>1,:) = [];

%��׼��
X = bsxfun(@rdivide,X,X(:,1));
%X(X(:,end)<1,:) = [];
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

a = sum((pred-mean(X(:,end))).^2)/sum((X(:,end)-mean(X(:,end))).^2)

[hz,hp,ht] = zplane(mu(4:end),mu(1:3));
ht.LineStyle = '-';
ht.LineWidth = 3;
hp.Marker = 'o';
hp.MarkerFaceColor = 'r';
uistack(ht,'bottom');
