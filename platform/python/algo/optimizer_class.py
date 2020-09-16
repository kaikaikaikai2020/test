from simulation.api import order, order_target_value, add_pipeline
import pandas as pa
from datetime import *

class optimizerClass:
	"""docstring for optiscaleFactors"""

	def __init__(self, scaleFactor):""

		self.scaleFactor = scaleFactor
		self.myPosition = pa.DataFrame()
	def singleDayOptim(self, sodRescaled, alpha, thisDayCorrelation=None):
		'''
		to be overridden in your class and return a new targetNominal
		'''
		self.myPosition = self.myPosition.append(alpha)
		L = list(self.myPosition.index)
		L[-1] = self.today
		self.myPosition.index =L
		return
	def generateHandleData(self, sameDay = True):
		'''
		sameDay = False means we trade tmr close
		'''

		def myHandleData(context, data):
			self.today = pa.to_datetime(context.today)
			if sameDay:
				current = data.current()
				history = data.history(fields=['px_last'])
				alpha = current['alpha']
			else:
				current = data.current()
				history = data.history(fields=['px_last','alpha'])
				alpha = history['alpha'].unstack().iloc[-1]
			self.sodpos = current["sod_pos"]
			lastprice = history['px_last'].fillna(method='ffill').unstack().iloc[-1]
			sodNomial = lastprice *self.sodpos/1e6
			sodNomial.fillna(0, inplace=True)
			self.singleDayOptim(sodNomial/self.scaleFactor, alpha)

			for id in current.index:
				if current.loc[id,'product']=='stock' and current.loc['id','tradable']:
					try:
						order_target_value(id, self.myPosition.loc[self.today,id]*1e6)
					except:
						order_target_value(id,0)
		return myHandleData
