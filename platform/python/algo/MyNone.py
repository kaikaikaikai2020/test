import pandas as pa

class MyNone:
	def __getitem__(self, i):
		return None

class mySeries:
	def __init(self, list_data, dates, symbols, isCorrelation=True):
		self.list_data = list_data
		self.dates = dates
		self.symbols = symbols
		self.shiftage = 0
		self.isCorrelation = isCorrelation
	def formatage(self, data):

		if self.isCorrelation:
			return pa.DataFrame(data, self.symbols, self.symbols)
		else:
			return pa.Series (data, self.symbols)

	def __getitem__(self, i):

		if i -self.shiftage >=0:
			return self.formatage(self.list_data[i-self.shiftage])
		else:
			return self.formatage(self.list_data[0])
	def shift(self, i =1):
		self.shiftage+=i

	def getByDate(self, date):
		i = self.dates.searchsorted(date)
		if i>0:
			i -=1
		return self.__getitem__(i)
	def getBySymbolsAndDates(self, date, SymbolsList):
		X = self.getByDate(date)
		if self.isCorrelation:
			return X.loc[SymbolsList, SymbolsList]
		else:
			return X.loc[SymbolsList]
	
