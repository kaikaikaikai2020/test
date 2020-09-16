from strategy.instrument import Instrument
from strategy.future import Future
from strategy.stock import Stock
from strategy.index import Index
from strategy.currency import Currency
from strategy.strategy_instance import get_strategy_instance

from utils.singleton import Singleton

import datetime
import logging
logger = logging.getLogger('Universe')

class Universe(object, metaclass = Singleton):
	def __init__(self):
		self.reset()

	def reset(self):
		self._insts = {}
		self._stocks = {}
		self._futures = {}
		self._future_roots = set()
		self._currencies = {}
		self._indices = {}

	def add_stocks(self, symbols):
		for s in symbols:
			inst = Stock(symbol= s)
			self._stocks[s] = inst
			self._insts[s] inst

	def add_indices(self, symbols):
		for s in symbols:
			inst = Index(symbol=s)
			self._indices[s] = inst
			self._insts[s] = inst

	def add_future_root(self, symbols):
		for s in symbols:
			if '%' in s:
				s = s.split('%')[0]

			self._future_roots.add(s)

	def add_futures(self, symbols):
		for s in symbols:
			if s not in self._futures:
				inst = Future(symbol=s)
				self._futures[s] = inst
				self._insts[s] = inst
			else:
				logger.warning("{} alreayd in the universe".format(s))

	def add_future(self, symbol, future=None):
		if symbol in self._futures:
			logger.warning("{} already in universe".format(symbol))

			return self._futures[future]

		if future is None:
			future = Future(symbol = symbol)

		self._futures[symbol] = future
		self._insts[symbol] = future
		return future
	def add_currencies(self, symbols):
		for s in symbols:
			inst = Currency(symbol=s)
			self._currencies[s] = inst
			self._insts[s] = inst

	def add_currency(self, symbol, inst= None):
		if symbol in self._currencies:
			logger.warning("{} already in universe".format(symbol))
			return

		if inst is None:
			inst = Currency(symbol = symbol)

		self._currencies[symbol]= inst
		self._insts[symbol] = inst

	def get_inst_list(self):
		return list(self._insts.keys())

	def get_stock_list(self):
		return list(self._stocks.keys())

	def get_future_list(self):
		return list(self._futures.keys())

	def get_currency_list(self):
		return list(self._currencies.keys())

	def get_future_root_list(self):
		return list(self._futures_roots)

	def get_inst(self, symbol):
		return self._insts.get(symbol, None)

	def get_stock(self, symbol):
		return self._stocks.get(symbol, None)

	def get_future(self,symbol):
		return self._futures.get(symbol, None)

	def get_index(self, symbol):
		return self._indices.get(symbol, None)

	def get_currency(self,symbol):
		return self._currencies.get(symbol, None)

	def iterate_insts(self, func):
		for k, v in self._insts.items():
			func(v)

	def iterate_stocks(self, func):
		for k, v in self._stocks.items():
			func(v)

	def iterate_futures(self, func):
		for k, v in self._futures.items():
			func(v)

	def iterate_currencies(self, func):
		for k, v in self._currencies.items():
			func(v)

	def iterate_indices(self, func):
		for k, v in self._indices.items():
			func(v)

	def load(self, universe):
		for p in universe:
			if p =='indices':
				self.load_indices(universe['indices'])
			elif p =='stocks':
				self.load_stocks(universe['stocks'])
			elif p =='futures':
				self.load_futures(universe['futures'])
			elif p =='currencies':
				self.load_currencies(universe['currencies'])

			else:
				raise ValueError("un support product {} ".format(p))


	def load_indices_constituents(self, symbols):
		from datasets.bloomberg.bloomberg import idx_con
		data = idx_con.get(symbol, self.universe_start_date, self.end_date)

		if self.symbology != idx_con.symbology:
			from datasets.symbology import add_symbology
			data = add_symbology(data.reset_index(), idx_con.symbology, self.symbology)
			index_names = [self.symbology if name == idx_con.symbology else name for name in index_names]
			data = data.set_index(index_names)

		return data

	def load_stocks(self, universe):
		if 'countries' in universe:
			pass

		if 'indices' in universe:
			pass

		if 'symbols' in universe:
			self.add_stocks(universe['symbols'])

	def load_currencies(self, universe):
		if 'symbols' in universe:
			self.add_currencies(universe['symbols'])

	def load_futures(self, universe):
		if 'symbols' in universe:
			self.add_futures(universe['symbols'])

	def load_indices(self, universe):
		if 'symbols' in universe:
			self.add_indics(universe['symbols'])

	@staticmethod
	def get_continuous_future_from_root(root):
		if '=' in root:
			root_split = root.split(' ')
			return root_split[0] +'1 '+root_split[1] + ' Equity'
		else:
			return root +'1 Index'

	def get_continuous_future(self, root):
		return self._futures[Universe.get_continuous_future_from_root(root)]

	def get_futures_from_root(self, root):
		futures = []
		id_sets = set()
		for k, v in self._futures.items():
			if v.root == root and id(v) not in id_sets:
				id_sets.add(id(v))
				futures.append(v)
		return futures

	def get_front_month_future(self, root, roll=3):
		strategy_instance = get_strategy_instance()
		if strategy_instance is not None:
			current_date = strategy_instance.get_current_date()
		else:
			current_date = datetime.datetime.now().date()

		front_future = None
		front_expiry_date = datetime.date(2030,1,1)
		for k, v in self._futures.items():
			if root == v.root and k!= root:
				if v.expiry_date - datetime.timedelta(days= roll)>-current_date:
					if v.expiry_date <front_expiry_date:
						front_expiry_date = v.expiry_date
						front_future =v 
		return front_future


	@staticmethod
	def get_root_future(sym):
		pass

	@property
	def insts (self):
		return self._insts

	@property
	def stocks(self):
		return self._stocks

	@property
	def futures(self):
		return self._futures

	@property
	def currencies(self):
		return self._currencies
	@property
	def indices(self):
		return self._indices

def get_universe():
	return Universe()

if __name__=='__main__':
	universe = Universe()
	
