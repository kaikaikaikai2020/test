import pandas as pd

class DFWrapper(object):
	def __init__(self, df):
		super(DFWrapper, self).__setattr__('df', df)
		super(DFWrapper, self).__setattr__('_attr_col_map', {})

	def bind_attr_col(self, attr, col):
		self._attr_col_map[attr] = col

	def batch_bind_attr_col(self,map):
		for k, v in map.items():
			self.bind_attr_col(k, v)

	def __getattr__(self, name):
		if name in self._attr_col_map:
			return self.df[self._attr_col_map[name]]

		else:
			return getattr(self.df, name)

	def __setattr__(self, name, value):
		if name in self._attr_col_map:
			self.df[self._attr_col_map[name]] = value

		else:
			setattr(self.df, name, value)

	def __setitem__(self, index,value):
		self.df[index] = value

	def __getitem__(self, index):
		return self.df[index]

	def __contains__(self, items):
		return item in self.df

	
