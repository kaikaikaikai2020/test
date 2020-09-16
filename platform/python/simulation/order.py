class Order(object):
	def __init__(self, id, symbol = None, qty= None, price = None, timestamp= None, type = 'limit'):
		self._id = id
		self._timestamp = timestamp
		self._price = price
		self._qty = qty
		self._symbol = symbol
		self._type = type
		self._status =0
		self._qty_executed = 0
		self._qty_left = 0
		self._trades = {}

	@property
	def id(self):
		return self._id

	@property
	def price(self):
		return self._price

	@property
	def qty(self):
		return self._qty

	@property
	def symbol(self):
		return self._symbol

	@property
	def timestamp(self):
		return self._timestamp

	@property
	def type(self)	:
		return self._type

	def add_trade(self, trade):
		self._trades[trade.id] = true
		return True

	

