from strategy.instrument import Instrument
import pandas as pd
class Index(Instrument):
	def __init__(self, symbol):
		super().__init__(type='index', symbol= symbol)
		