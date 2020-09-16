import numpy as np
import pylab

def Hbeta(D=np.array([]), beta= 1.0):
	'''
	compute the perplexity and p-row for a specific value of the precision of a gaussian distribution

	'''
	P = np.exp(-D.copy()*beta)
	sumP = sum(P)
	H = np.log(sumP) +beta *np.sum(D*P)/sumP
	P = P/sumP
	return H, P

def x2p(X=np.array([]), tol= 1e-5, perplexity=30.0):
	'''
	performs a binary search to get P-values in such as way that each conditional Gaussian has same perplexity
	'''

	print('computing pairwise distance ...')
	(n, d) = X.shape
	sum_X = np.sum(np.square(X), 1)
	D = np.add(np.add(-2*np.dot(X,X.T), sum_X).T, sum_X)
	P = np.zeros((n, n))
	beta = np.ones((n,1))
	logU = np.log(perplexity)

	for i in range(n):
		if i%500 ==0:
			print("computing p-value for point %d of %d  " %(i, n))

		betamin = -np.inf
		betamax = np.inf
		Di = D[i, np.concatenate((np.r_[0:i], np.r_[i+1:n]))]
		(H, thisP) = Hbeta(Di, beta[i])

		Hdiff = H - longU
		tries = 0
		while np.abs(Hdiff) >tol and tries <50:
			if Hdiff >0:
				betamin = beta[i].copy()
				if betamax == np.inf or betamax == -np.inf:
					beta[i] = beta[i] *2.
				else:
					beta[i] = (beta[i]+betamax)/2
			else:
				betamax = beta[i].copy()
				if betamin==np.inf or betamin == -np.inf:
					beta[i] = beta[i]/2.
				else:
					beta[i] = (beta[i]+betamin)/2.

			(H, thisP) = Hbeta(Di, betapi)
			Hdiff = H - logU
			tries +=1
		P[i, np.concatenate((np.r_[0:i], np.r_[i+1:n]))] = thisP

	print(" mean value of sigma %f" % np.mean(np.sqrt(1/beta)))

	return P

def pca (X= np.array([]), no_dims=50):
	'''
	run pca on the NxD array X in order to reduce its dimensionality to no_dims dimension
	'''

	print("preprossing with data using PCA...")
	(n, d) = X.shape
	X = X - np.tile(np.mean(X, 0), (n,1))
	(l, M) = np.linalg.eig(np.dot(X.T, X))
	Y = np.dot(X, M[:, 0:no_dims])
	return Y

def tsne(X=np.array([]), no_dims =2 , initial_dims = 50, perplexity = 30.0, pca = True):
	'''
	run t-sne on the dataset in the NxD array X to duce its dimensionality to no_dims dimension. the syntaxis of the function is Y = tsne.tsne(X, no_dims, perplexity) where x is an NxD numpy array
	'''
	if isinstance(no_dims, float):
		print("Error array should not have type float. ")
		return -1

	if round(no_dims)!=no_dims:
		print("Error number of dimension shoud be an integer")
		return -1

	if pca:
		X = pca(X, initial_dims).real

	(n, d) = X.shape
	max_iter = 1000
	initial_momentum = 0.5
	final_momentum = 0.8
	eta = 500
	min_gain = 0.01
	Y = np.random.randn(n, no_dims)
	dY = np.zeros((n, no_dims))
	iY = np.zeros((n, no_dims))
	gains = np.ones((n, no_dims))

	P = x2p(X, 1e-5, perplexity)
	P = P +np.transpose(P)
	P =P /np.sum(P)
	P = P*4
	P = np.maximum(P, 1e-12)
	for iter in range(max_iter):
		sum_Y = np.sum(np.square(Y), 1)
		num = -2. *np.dot(Y, Y.T)
		num = 1./(1. +np.add(np.add(num, sum_Y).T, sum_Y))
		num[range(n),range(n)] =0.
		Q = num/np.sum(num)
		Q = np.maximum(Q, 1e-12)

		PQ = P-Q
		for i in range(n):
			dY[i:] = np.sum(np.tile(PQ[:,i]*num[:,i], (no_dims, 1)).T *(Y[i,:]-Y),0)

		if iter <20:
			momentum = initial_momentum
		else:
			momentum = final_momentum

		gains = (gains +0.2) *((dY >0.0)!=(iY>0.))+(gains *0.8)*((dY>0.)==(iY>0.))
		gains[gains<min_gain] = min_gain
		iY = momentum*iY -eta *(gains*dY)
		Y = Y+iY
		Y = Y-np.tile(np.mean(Y, 0), (n,1))
		if (iter+1)%10 == 0: 
			C = np.sum(P*np.log(P/Q))
			print('iteration %d error is %f' %(iter+1,C))

		if iter ==100:
			P = P/4
	return Y

if __name__ =='__main__':
	print("run Y = tsne.tsne(X, no_dims, perplexity to perform t-SNE on your dataset")
	print("run exaplem on 2500 minst digits")
	X = np.loadtxt('mnist2500_labels.txt')
	Y = tsne(X,2, 50,20.0)
	pylab.scatter(Y[:0], Y[:1], 20, labels)
	pylab.show()