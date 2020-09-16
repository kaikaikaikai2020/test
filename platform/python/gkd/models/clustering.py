from sklearn.mixture import GaussianMixture as SK_GaussianMixture, BayesianGaussianMixture as SK_BayesianGaussianMixture
from sklearn.cluster import KMeans as SK_Kmeans
from pyclustering.cluster.center_initializer import kmeans_plusplus_initializer
from pyclustering.cluster.fcm import fcm

import pandas as pd
import numpy as np
class Model(object):
	def __init__(self):
		self._name = None
	@property
	def name (self):
		return self._name

	def train(self, x, **kwargs):
		if isinstance(x, pd.DataFrame):
			return self._model.fit_predict(x.values, **kwargs)
		else:
			return self._model.fit_predict(x, **kwargs)

	def predict(self, x, **kwargs):
		return self._model.predict(x.values, **kwargs)

	def save(self):
		return self

	@staticmethod
	def load(obj):
		return obj
	def serialize(self):
		return self
class GuassianMixture(Model):
	_name = 'gaussian_mixture'

	def __init__(self, **kwargs):
		self._model = SK_GaussianMixture(**kwargs)

class BayesianGuassianMixture(Model):
	_name = 'bayesian_gaussian_mixture'

	def __init__(self, **kwargs):
		self._model = SK_BayesianGaussianMixture(**kwargs)

class KMeans(Model):
	_name = 'kmeans'

	def __init__(self, **kwargs):
		self._model = SK_Kmeans(**kwargs)

class FuzzyCMean(Model):
	_name = 'fuzzy_cmeans'
	def __init__(self, **kwargs):
		pass

	def train(self, x, n_clusters, **kwargs):
		if isinstance(x, pd.DataFrame):
			x = x.values

		initial_centers = kmeans_plusplus_initializer(x, n_clusters, kmeans_plusplus_initializer.FaRTHEST_CENTER_CANDIDATE).initialize()
		self._model = fcm(x, initial_centers= initial_centers, **kwargs)
		self._model.process()

		return np.array(self._model.get_membership())

def match_clusters (lhs, rhs):
	count_map = {}
	for i, j in zip(lhs, rhs):
		if i not in count_map:
			count_map[i] ={}
		if j not in count_map[i]:
			count_map[i][j] =0

		count_map[i][j] +=1
		



