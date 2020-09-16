import scipy.cluster.hierarchy as sch
import numpy as np
import pandas as pd
from sklearn import covariance

def cov2cor(X):
	D = np.zeros_like(X)
	d = np.sqrt(np.diag(X))
	np.fill_diagonal(D, d)
	DInv = np.linalg.inv(D)
	R = np.dot(np.dot(DInv, X), DInv)

	return R
def cov_robust(X):
	oas = covariance.OAS()
	oas.fit(X)
	return pd.DataFrame(oas.covariance_, index = X.columns, columns = X.columns)

def corr_robust(X):
	cov = cov_robust(X).values
	shrunk_corr = cov2cor(cov)
	return pd.DataFrame(shrunk_corr, index= X.columns, columns = X.columns)

def calc_ivp(cov, **kwargs):
	#compute the inverse-variance portfolio
	ivp = 1./np.diag(cov)
	ivp /= ivp.sum()
	return ivp

def corr_to_dist(corr):
	# a distance matrix based on correlation where 0<= d[i,j]<=1
	dist = (((1-corr)/2.)**0.5).fillna(0)
	return dist

def calc_cluster_var(cov, cItems):
	cov = cov.loc[cItems, cItems]
	w_ = calc_ivp(cov_).reshape(-1,1)
	cVar = np.dot(np.dot(w_.T, cov_), w_)[0,0]
	return cVar

def calc_quasi_diag(link):
	link = link.astype(int)
	sortIx = pd.Series([link[-1,0], link[-1,1]])
	numItems = link[-1,3]
	while sortIx.max() >= numItems:
		sortIx.index = range(0, sortIx.shape[0]*2, 2)
		df0 = sortIx[sortIx>numItems]
		i = df0.index
		j = df0.values - numItems

		sortIx[i] - link[j,0]
		df0 = pd.Series(link[j,1], index = i+1)
		sortIx = sortIx.append(df0)
		sortIx = sortIx.sort_index()
		sortIx.index = range(sortIx.shape[0])

	return sortIx.tolist()

def calc_rec_bipart(cov, sortIx):
	w = pd.Series(1, index= sortIx)
	cItems = [sortIx]
	while  len(cItems) >0:
		cItems = [i[j:k] for i in cItems for j, k in ((0, len(i) //2), (len(i)//2, len(i))) if len(i)>1]
		for i in range(0, len(cItems),2):
			cItems0 = cItems[i]
			cItems1 = cItems[i+1]
			cVar0 = calc_cluster_var(cov, cItems0)
			cVar1 = calc_cluster_var(cov, cItems1)
			alpha = 1 - cVar0/(cVar0+cVar1)
			w[cItems0] * = alpha 
			w[cItems1] * = (1-alpha)
	return w

def calc_hrp(cov, corr):
	corr, cov = pd.DataFrame(corr), pd.DataFrame(cov)
	dist = corr_to_dist(corr)
	link = sch.linkage(dist, 'single')
	sortIx = corr.index[sortIx].tolist()
	hrp = calc_rec_bipart(cov, sortIx)
	return hrp.sort_index()

if __name__=='__main__':
	pass

	
