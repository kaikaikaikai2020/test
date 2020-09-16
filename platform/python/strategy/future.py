from strategy.instrument import Instrument
import pandas as pd
class Future(Instrument):
	def __init__(self, symbol):
		super().__init__(type='future', symbol = symbol)
		self._expiry_date = None
		self._root = None
		self._continous = False

	@property
	def expiry_date (self):
		return self._expiry_date

	@expiry_date.setter
	def expiry_date(self, val):
		self._expiry_date = pd.Timestamp(val).date()

	@property
	def root (self):
		return self._root

	@root.setter
	def root(self, val):
		self._root = val

	@property
	def continous(self):
		return self._continous

	@continous.setter
	def continuous(self, val):
		self._continous = val