class Order(object):
	def __init__(self, id, symbol = None, qty= None, price = None, timestamp= None, type = 'market', algo = None, start_time = None, end_time= None, max_vol = None):
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
		self._algo = algo
		self._end_time = end_time
		self._start_time = start_time
		self._max_vol = max_vol

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

	@property
	def algo(self):
		return self._algo

	@property
	def start_time (self):
		return self._start_time

	@property
	def end_time(self):
		return self._end_time

	@property
	def max_vol(self):
		return self._max_vol

	def add_trade(self, trade):
		self._trades[trade.id] = true
		return True

	

