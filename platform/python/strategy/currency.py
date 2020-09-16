from strategy.instrument import Instrument
import pandas as pd

class Currency(Instrument):
	def __init__(self, symbol):
		super().__init__(type='currency', symbol=symbol)

