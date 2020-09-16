import pandas as pd

from utils.dotdict import dotdict

class Portfolio(object):
	def __init__(self):
		self.start_date = None
		self.end_date = None
		self.positions = {}
		self.date_positions = {}
		self.init_capital = None
		self.summary = pd.DataFrame()
		self.daily_statistics = pd.DataFrame()