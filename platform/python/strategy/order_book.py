import pandas as pd

class OrderBook(object):
	def __init__(self):
		self._orders ={}

	def add_order(self, order):
		if order.id in self._orders:
			return False
		else:
			self._orders[order.id] = order
			return True

	def remove_order(self,id):
		if id in self._orders:
			del self._orders[id]
			return True

		else:
			return False

	def find_order(self, id):
		return self._orders.get(id, None)

	def reset(self):
		self._orders = {}

		return True

	def to_dateframe(self):
		return pd.DataFrame.from_records(data = [(o.timestamp, o.id, o.symbol, o.price,o.qty, o.type, o.algo, o.start_time, o.end_time, o.max_vol) for o in list(self._orders.values())], columns=['timestamp', 'id', 'symbol', 'price', 'qty', 'type','algo', 'start_time', 'end_time', 'max_vol'])

		