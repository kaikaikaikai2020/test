import pandas as pd
class TradeBook(object):
	def __init__(self):
		self._trades = {}

	def add_trade(self, trade):
		if trade.id in self._trades:
			return False

		else:
			self._trades[trade.id] = trade
			return True

	def remove_trade(self, id):
		if id in self._trades:
			del self._trades[id]

			return True
		else:
			return False

	def find_trade(self, id):
		return self._trades.get(id, None)

	def reset(self):
		self._trades={}
		return True

	def to_dateframe(self):
		return pd.DataFrame.from_records(data= [(t.timestamp, t.id, t.order_id, t.symbol, t.price, t.qty) for t in list(self._trades.values())], columns=['timestamp', 'id', 'order_id', 'symbol', 'price','qty'])

