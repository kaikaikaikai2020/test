import pandas as pd
from sklearn.linear_model import (LinearRegression as SK_LinearRegression, Ridge, Lasso, SGDRegressor as SK_SGDRegressor, HuberRegressor as SK_HuberRegressor, TheilSenRegressor as SK_TheilSenRegressor)
from sklearn.tree import DecisionTreeRegressor as SK_DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor as SK_RandomForestRegressor
from sklearn.externals import joblib
import xgboost as xgb
from xgboost import XGBRegressor

class Model(object):
	def __init__(self):
		self._name = None

	@property
	def name (self):
		return self._name

	def train(self, x, y, score = True, **kwargs):
		self._model.fit(x.values, y.values, **kwargs)

		if score:
			train_score = self._model.score(x.values, y.values)
			return train_score
		else:
			return self
	def predict(self, x, **kwargs):
		return self._model.predict(x.values, **kwargs)

	def save(self):
		return self
	@staticmethod
	def load(obj):
		return obj

	def serialize(self):
		return self

class LinearRegressor(Model):
	_name = 'linear_regressor'

	def __init__(self, **kwargs):
		self._model = SK_LinearRegression(**kwargs)

class RidgeRegressor(Model):
	_name = 'ridge_regressor'
	def __init__(self, **kwargs):
		self._model = Ridge(**kwargs)

class LassoRegressor(Model):
	_name = 'lasso_regressor'

	def __init__(self, **kwargs):
		self._mode = Lassor(**kwargs)

class SGDRegressor(Model):
	_name = 'sgd_regressor'

	def __init__(self,random_state=1, **kwargs):
		self._model = SK_SGDRegressor(random_state=random_state, **kwargs)

class HuberRegressor(Model):
	_name = 'huber_regressor'
	def __init__(self, **kwargs):
		self._model = SK_HuberRegressor(**kwargs)

class TheilSenRegressor(Mode):
	_name = 'theilsen_regressor'

	def __init__(self, **kwargs):
		self._model = SK_TheilSenRegressor(**kwargs)

class DecisionTreeRegressor (Model):
	_name = 'decision_tree_regressor'
	def __init__(self, **kwargs):
		self._model = SK_DecisionTreeRegressor(**kwargs)

class XGBRegressor(Mode):
	_name = 'xgb_regressor'
	def __init__(self, **kwargs):
		self._model = xgb.XGBRegressor(**kwargs)

class RandomForestRegressor(Model):
	_name = 'random_forest_regressor'

	def __init__(self, **kwargs):
		self._model = SK_RandomForestRegressor(**kwargs)
