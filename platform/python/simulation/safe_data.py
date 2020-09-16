import pandas as pd
from .backtest_instance import get_current_date

class SafeData(object):
	def __init__(self, df):
		self.__df = df

	def has_current(self, id):
		return (get_current_date(), id) in self.__df.index

	def current(self, ids= None, fields = None):
		current_date = get_current_date()
		if ids is None:
			id_idx = slice(None)

		else: 
			id_idx = ids

		if fields is None:
			field_idx = slice(None)

		else:
			field_idx = fields

		current_data = self.__df.loc[current_date]
		return current_data.loc[id_idx, field_idx]

	def history(self, ids= None, fields= None):
		current_date = get_current_date()
		if ids is None:
			id_idx = slice(None)

		else: 
			id_idx = ids

		if fields is None:
			field_idx = slice(None)

		else:
			field_idx = fields

		idx = pd.IndexSlice
		if isinstance(ids, str):
			return self.__df.xs(ids, level=1).loc[:current_date, fields]
		else:
			return self.__df.loc[idx[:current_date], field_idx]
