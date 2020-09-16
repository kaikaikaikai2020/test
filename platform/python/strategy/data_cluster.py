import pandas as pd
import numpy as np
import logging

from strategy.data import Data

class DataCluster(object):
	def __init__(self):
		self.__main = None
		self.__cluster = {}

	def __iter__(self):
		return iter(self.__cluster)

	def has_current(self, id):
		return self.__main.has_current(id)

	def current(self, ids= None, fields= None):
		return self.__main.current(ids=ids, fields= fields)

	def history(self, ids= None, fields = None):
		return self.__main.history(ids= ids, fields= fields)

	def add_data(self, name, data, frequency= None, overwrite= True):
		if name in self.__cluster:
			if not overwrite:
				raise ValueError(name +' already added')

		if isinstance(data, pd.DataFrame):
			data = Data(data, frequency= frequency)

		self.__cluster[name] = data

	def get_data(self, name):
		if name not in self.__cluster:
			print(name + " not exist ")
			return None

		return self.__cluster[name]

	def set_main_data(self, name):
		main = self.get_data(name)
		if main is None:
			raise ValueError("fail to get data {}".format(name))
		self.__main = main

	def set_field(self, name = None,id = None, key= None, value = None):
		d = self.get_data(name)
		if d is None:
			raise ValueError(name + ' not added yet')

		d.set_field(id= id, key = key, value = value)

	def __contains__(self, key):
		return key in self.__cluster

	
	@property
	def names (self):
		return list(self.__cluster.keys())

		
