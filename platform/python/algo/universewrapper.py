class universewrapper:
	def __init__(self):
		self.universe={}
	def addIndices(self, indiceList):
		if not self.universe.has_key('stocks'):
			self.universe['stocks']={}
		if isinstance(indiceList, (str, unicode)):
			self.universe['stocks']['indices'] = self.universe['stocks'].get('indices', [])+[indiceList]
		else:
			self.universe['stocks']['indices'] = self.universe['stocks'].get('indices', [])+indiceList
	def addFutures(self, futureList):
		if not self.universe.has_key('futures'):
			self.universe['futures']={}
		if isinstance(futureList, (str, unicode)):
			self.universe['futures']['symbols'] = self.universe['futures'].get('symbols', [])+[futureList]
		else:
			self.universe['futures']['symbols'] = self.universe['futures'].get('symbols', [])+futureList
	def addCurrencies(self, crncyList):
		if not self.universe.has_key('currencies'):
			self.universe['currencies']={}
		if isinstance(futureList, (str, unicode)):
			self.universe['currencies']['symbols'] = self.universe['currencies'].get('symbols', [])+[crncyList]
		else:
			self.universe['currencies']['symbols'] = self.universe['currencies'].get('symbols', [])+crncyList

	def getUniverse(self):
		return self.universe
		