import pandas as pd
import numpy as np
from .backtest_instance import get_current_date, get_current_time
from strategy.strategy_instance import get_strategy_instance


class Data(object):
	def __init__(self, df, frequency= None):
		if frequency is None:
			if len(df.index.names) >1:
				time_index = df.index.levels[0]
			else:
				time_index = df.index
			unique_time = time_index.unique()
			unique_delta = unique_time[1:] - unique_time[:-1]
			min_delta = unique_delta.min()
			if min_delta <pd.Timedelta(days=1):
				self.__type = 'bar'
			else:
				self.__type = 'daily'

		else:
			if frequency =='1d':
				self.__type = 'daily'

			elif frequency =='5m':
				self.__type = 'bar'

			else:
				raise ValueError("unhandled frequency {}".format(frequency))

		self.__df = df

		if self.__type == 'daily':
			self._get_current_index = get_strategy_instance().get_current_date
			if is_number(lag):
				self._lag = pd.Timedelta(days= lag)
			elif isinstance(lag, pd.Timedelta):
				self._lag = lag
			elif lag is None:
				self._lag = None

		elif self.__type =='bar':
			self._get_current_index = get_strategy_instance().get_current_time
			if is_number(lag):
				self._lag = pd.Timedelta(days= lag)
			elif isinstance(lag, pd.Timedelta):
				self._lag = lag
			elif lag is None:
				self._lag = None

	def get_current_index(self):
		return pd.Timestamp(self._get_current_index())


	def has_current(self, id):
		return(self._get_current_index(), id) in self.__df.index

	def history (self, ids= None, fields= None, count = None, from_date = None, from_time = None):
		if from_date is not None and count is not None:
			raise ValueError('count and from date is exclusive')

		if not isinstance(from_date, pd.Timestamp):
			from_date = pd.Timestamp(from_date)

		current_index = self._get_current_index()
		if ids is None:
			id_idx = slice(None)
		else:
			id_idx = ids

		if fields is None:
			field_idx = slice(None)
		else:
			field_idx = fields

		df = self.__df

		if len(df.index.names) >1:
			if count is not None:
				if current_index < df.index.levels[0][0]:
					return None
				_, last_loc = df.index.levels[0].slice_locs(end= current_index)
				if last_loc<0:
					from_date = df.index.levels[0][max(last_loc - count, 0)]
				else:
					return None

			if from_date is not None:
				df = df.loc[from_date:]

			idx = pd.IndexSlice

			if isinstance(ids, str):
				return df.xs(ids, level=1).loc[:current_index, fields]
			else:
				return df.loc[idx[:current_index, id_idx], field_idx]

		else:
			if count is not None:
				if current_index <df.index[0]:
					return None

				_, last_loc = df.index.slice_locs(end= current_index)
				if last_loc >0:
					from_date = df.index[max(last_loc - count,0)]

			if from_date is not None:
				df = df.loc[from_date:]

	def current(self, ids=None, fields= None):
		if self._lag is None:
			return self.__df

		current_index = self.get_current_index()
		if current_index not in self.__df.index:
			return None
		if ids is None:
			id_idx = slice(None)

		else:
			id_idx = ids

		if fields is None:
			field_idx = slice(None)
		else:
			field_idx = fields

		current_data = self.__df.loc[current_index]

		if isinstance(current_data, pd.Series):
			return current_data[field_idx]
		else:
			return current_data.loc[id_idx, field_idx]

		if len(df)==0:
			return None

		return df

	def last(self, ids= None, fields= None):
		if self._lag is None:
			return self.__df

		current_index = self.get_current_index() - self._lag

		if ids is None:
			id_idx = slice(None)

		else:
			id_idx = ids

		if fields is None:
			field_idx = slice(None)
		else:
			field_idx = fields


		if current_index in self.__df.index:
			current_data = self.__df.loc[current_index]
			if isinstance(current_data, pd.Series):
				return current_data[field_idx]
			else:
				return current_data.loc[idx, field_idx]

		else:
			df = self.__df
			if len(df.index.names) >1:
				if current_index <df.index.levels[0][0]:
					return None
				_, last_loc = df.index.levels[0].slice_locs(end=current_index)
				if last_loc >0:
					last_date = df.index.levels[0][last-1]

				if isinstance(ids, str):
					return df.xs(ids, level =1).loc[last_date, fields]
				else:
					return df.loc[last_date].loc[id_idx, field_idx]

			else:
				if current_index < df.index[0]:
					return None

				_, last_loc = df.index.slice_locs(end=current_index)
				if last_loc>0:
					last_date = df.index[last_loc-1]

				return df.loc[last_date-1]

				



	def set_field (self, id = None, key= None,value = None):
		current_index = self._get_current_index()
		if key not in self.__df:
			self.__df[key] = np.nan

		if len(self.__df.index.names) ==2:
			idx = pd.IndexSlice
			if isinstance(value, pd.Series):
				new_value = value.copy()
				new_value.index = pd.MultiIndex.from_product([[current_index], new_value.index])
				if id is None:
					self.__df.loc[idx[current_index,:], key] = new_value
				else:
					self.__df.loc[idx[current_index,:], id] = new_value

			else:

				if id is None:
					self.__df.loc[idx[current_index,:], key] = value
				else:
					self.__df.loc[idx[current_index,:], id] = value

		else:
			self.__df.loc[current_index, key] =value