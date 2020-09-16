class Trade(object):
	def __init__(self, id, order_id, symbol= None, qty= None, price = None, timestamp = None, algo = None, start_time= None, end_time = None):
		self._id = id
		self._order_id = order_id
		self._timestamp = timestamp
		self._price = price
		self._qty = qty
		self._symbol = symbol
		self._algo = algo
		self._start_time = start_time
		self._end_time = end_time


	@property
	def id (self):
		return self._id

	@property
	def order_id (self):
		return self._order_id

	@property
	def price (self):
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
	def algo(self):
		return self._algo

	@property
	def start_time(self):
		return self._start_time

	@property
	def end_time(self):
		return self._end_time


