from strategy.instrument import Instrument
import pandas as pd

class Stock(Instrument):
	def __init__(self, symbol):
		super().__init__(type='stock', symbol = symbol)
		self._restricted = False

	@property
	def restricted(self):
		return self._restricted

	@restricted.setter
	def restricted(self, val):
		self._restricted = val

	