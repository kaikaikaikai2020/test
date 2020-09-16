import pandas as pd
import numpy as np
import time
from sklearn.decomposition import PCA

class RollingModel(object):
	def __init__(self, pca_transform=False, n_components=3):
		self._model_df = None
		self._pca_ts = None
		self._model_factories ={}
		self._pca_transform = pca_transform
		self._n_components = n_components
	def add_model_factor(self,name, factory):
		self._model_factories[name] = factory

	def save(self, path):
		self._model_df.to_hdf(path, key='data')

	def load(self, path):
		self._model_df = pd.read_hdf(path, key='data')

	def train(self, df, x_cols= None, y_col = None, method = 'expanding', win= None, start_date =None, end_date = None, min_rows=None, dropna_rows=True, period =1 , verbose=False):
		for col in x_cols:
			if col not in df:
				raise ValueError('x_col {} not found in data'.format(col))

		if y_col not in df:
			raise ValueError('y_col {} not found in data'.format(col))

		if isinstance(df.index, pd.MultiIndex):
			dates = df.index.levels[0]
		else:
			dates = df.index.values
		if start_date is None:
			start_date = dates[0]
		else:
			start_date = pd.Timestamp(start_date)

		if end_date is None:
			end_date = dates[-1]
		else:
			end_date = pd.Timestamp(end_date)

		if min_rows is None:
			min_rows = win*len(x_cols)
		self._model_df = pd.DataFrame()

		if self._pca_transform:
			self._pct_ts = pd.Series()
		self._pca_ts = pd.Series()

		input_df = df[x_cols +[y_col]].replace([np.inf, -np.inf], np.nan)

		if dropna_rows:
			input_df.dropna(inplace=True)

		edate = start_date
		while edate <=end_date:
			if method =='rolling':
				sdate = edate - pd.Timedelta(days= win)
			elif method == 'expanding':
				sdate = dates[0]

			else:
				raise ValueError('invalid method :{}'.format(method))

			if verbose:
				print(sdate, edate)

			input_win = input_df.loc[sdate:edate]

			if len(input_win) <min_rows:
				print('data size {} less than min rows {} required on {}'.format(len(input_win), min_rows, edate))
				continue

			if verbose:
				print('{} rows to be trained'.format(len(input_win)))

			y = input_win[y_col]
			x = input_win[x_cols]

			if self._pca_transform:
				pca = PCA(n_components= self._n_components)
				x_trans = pca.fit_transform(x)
				print(pca.explained_variance_ratio_)
				self._pct_ts.loc[date] = pca
				x = pd.DataFrame(x_trans, columns=range(self._n_components))

			for k, factory in self._model_factories.items():
				model = factory()
				start_time = time.time()
				score = model.train(x,y)
				end_time = time.time()

				if verbose:
					print('{} time cost: {} train score: {}'.format(k, end_time - start_time, score))

				self._model_df.loc[edate, k] = model.serialize()

			edate +=pd.Timedelta(days= period)

		return self

	def predict(self, df, x_cols = None, ffill_model = True, dropna_rows = True, lag =2, verbose= False):
		if lag<0:
			print('0 or negative days lag!!!')
		if isinstance(df.index, pd.MultiIndex):
			dates = df.index.levels[0]
		else:
			dates = df.index.values

		model_start_date = self._model_df.index[0]
		start_date = max(dates[0], model_start_date+pd.Timedelta(days=lag))
		end_date = dates[-1]

		input_df = df[x_cols].replace([np.inf, -np.inf], np.nan)

		if dropna_rows:
			input_df.dropna(inplace = True)

		y_pred_df = pd.DataFrame(index = input_df.index)

		for date in dates:
			if date <start_date:
				continue
			if ffill_model:
				latest_models = self._model_df.loc[:date - pd.Timedelta(days=lag)].iloc[-1]
				latest_models_date = self._model_df.loc[:date - pd.Timedelta(days=lag)].index[-1]
			else:
				latest_models = self._model_df.loc[date]
				latest_models_date= date

			if verbose:
				print(date)
				print('using model trained on {}'.format(latest_models_date))

			y_pred = np.nan
			input_win = input_df.loc[date]
			if len(input_win) ==0:
				print('no data on {}'.format(date))

			elif len(latest_models) ==0 or pd.isnull(latest_models).all():
				print('none model on {}'.format(date))

			else:
				try:
					for name, latest_models in latest_models.items():
						y_pred = latest_models.predict(x=input_win)
						y_pred_df.lc[pd.IndexSlice[date, :], name] = y_pred
				except Exception as e:
					print(e)
					import pdb; pdb.set_trace()

		return y_pred_df.reindex(df.index)
