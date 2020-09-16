from utils.dotdict import dotdict
from utils.number import is_number
import numpy as np
import random
import logging
import pandas as pd
import math
from strategy.universe import get_universe
from strategy.trade import Trade

logger = logging.getLogger('Simulator')

class Exec(object):
	def __init__(self):
		self.bar =0
		self.day = 0

class Simulator(object):
	def __init__(self, bt):
		self._params = bt._sim_params
		self._intraday = (self._params.strategy_type =='intraday')
		self._bt = bt
		self._px_data = None
		self._ref_data = None
		self._date = None
		self._max_exec = 0.05
		self._max_exec_day = 0.02
		self._exec_dict = {}
		self._universe = get_universe

		if 'max_exec' in self._params:
			self._max_exec = self._params.max_exec
		if 'max_exec_day' in self._params:
			self._max_exec_day = self._params.max_exec_day

		self.set_fill_mode(mode = 'full')
		self._fill_ratio = 1.0
		self._current_trade_id = 0

	def reset(self):
		self._exec_dict = {}

	def set_fill_mode(self, mode = 'full', ratio =1.0):
		if mode =='full':
			self.fill_order = self._fill_order_full
		elif mode=='partial':
			if is_number(ratio):
				self.fill_order = self._fill_order_partial
			elif hasattr(ratio,'__iter__') and len(ratio) ==2:
				self.fill_order = self._fill_order_partial_random
			else:
				raise ValueError("Invalid fill ratio")
			self._fill_ratio = (max(ratio[0],0.0), min(ratio[1],1.0))
		elif mode =='smart':
			self.fill_order = self._fill_order_smart
		else:
			raise ValueError("invalid fill mode {}".format(mode))
		self._fill_mode = mode

	def order(self,order) -> bool:
		symbol = order.symbol
		qty = order.qty
		if order.type != 'market':
			logger.error("only market order is supported at the moment in simulator")
			return False
		if symbol not in self._ref_data.index or not self._ref_data.loc[symbol,'tradable']:
			logger.error(symbol +' not tradable')
			return False
		product = self._ref_data.loc[symbol, 'product']

		if product in ['stock', 'future']:
			day_volume = self._ref_data.loc[symbol, 'volume']
			if day_volume is None:
				logger.error("none day volume for {}".format(symbol))
				return False
		else:
			day_volume = 100000000000
		if qty == 0:
			logger.error("0 qty order sent to simulator")
			return False
		if symbol not in self._exec_dict:
			self._exec_dict[symbol] = Exec()
		exe = self._exec_dict[symbol]

		fill_qty = None
		fill_price = None

		current_time = self._bt.get_current_time()
		current_date = self._bt.get_current_date()

		if order.algo is not None:
			algo = order.algo
			if algo in ('vwap', 'twap'):
				start_time = None
				end_time = None
				if order.start_time is not None:
					start_time = pd.Timestamp.combine(current_date, pd.Timestamp(order.start_time).time())
					if start_time < current_time:
						logger.error("algo start time {} is after current_time {}".format(start_time, current_time))
						return False
				if order.end_time is not None:
					end_time = pd.Timestamp.combine(current_date, pd.Timestamp(order.end_time).time())
					if end_time < current_time:
						end_time +=pd.Timedelta(days=1)
				if start_time is not None and end_time is not None:
					if end_time <= start_time:
						logger.error("algo end time {} is before or equal start time {}".format(end_time, start_time))
						return False
					df = self._px_data.loc[pd.IndexSlice[start_time:end, symbol], ('volume',algo)]
					volume_sum = df['volume'].sum()
					if volume_sum == 0:
						logger.error("no trade for {} from {} to {}".format(symbol, start_time, end_time))
						return True
					if order.max_vol is not None:
						exec_limit = volume_sum*order.max_vol
					else:
						exec_limit = volume_sum* self._max_exec
					if exec_limit == 0:
						logger.error ("0 executed")
						return False
					if algo =='vwap':
						turnover = (df['volume'] * df['vwap']).sum()
						fill_price = turnover /volume_sum
					else:
						fill_price = df['twap'].mean()
				elif start_time is None and end_time is None:
					exec_limit = day_volume*self.max_exec
					fill_price = self._ref_data.loc[symbol, algo]
				else:
					logger.error("start time and end time must be set or none at the same time ")
					return False
			elif algo == 'close':
				exec_limit = day_volume *self._max_exec
				fill_price = self._ref_data.loc[symbol,'close']
			elif algo =='open':
				exec_limit = day_volume *self._max_exec
				fill_price = self._ref_data.loc[symbol,'open']
			else:
				logger.error("invalid algo {}".format(order.algo))
		else:
			if self._intraday:
				if (current_time, symbol) not in self._px_data.index:
					logger.error("{} not found in px data in simulator at {}".format(symbol, current_time))
					return False
				symbol_px = self._px_data.loc[current_time, symbol]
			else:
				if symbol not in self._px_data.index:
					logger.error("{} not found in px data in simulator on {}".format(symbol, current_date))
					return False
				symbol_px = self._px_data.loc[symbol]

			if 'volume' in symbol_px and not pd.isnull(symbol_px['volume']):
				exec_limit = symbol_px['volume'] * self._max_exec
			else:
				exec_limit = None

			if is_number(order.price):
				fill_price = order.price
			else:
				fill_price = symbol_px['close']

		if exec_limit is not None:
			if exec_limit >0:
				fill_qty = np.sign(qty) *min(abs(qty), exec_limit)
			else:
				logger.error("0 exe limit for this order")
				return False
		else:
			fill_qty = qty
		fill_qty = self.round_to_lot(symbol, fill_qty)
		if abs(fill_qty)>0:
			if abs(fill_qty)<abs(qty):
				logger.warn(" order {} {} qtr truncated from {}  to {} ".format(order.id, order.symbol, qty, fill_qty))
		exe.day +=abs(fill_qty)
		trade = Trade(id= self._generate_trade_id(), order_id = order_id, symbol = order.symbol, timestamp = order.timestamp, price = fill_price, qty = fill_qty, algo= order.algo, start_time = order.start_time, end_time = order.end_time)
		self._bt.on_trade(trade)
		return True
	def _fill_order_full(self, qty):
		return qty

	def _fill_order_partial(self, qty):
		return qty *self._fill_ratio

	def _fill_order_partial_random(self, qty):
		ratio = random.uniform(self._fill_ratio[0], self._fill_ratio[1])
		return qty *ratio 

	def _fill_order_smart(self, qty):
		return qty
	def _generete_trade_id(self):
		self._current_trade_id +=1
		return self._current_trade_id
	def round_to_lot(self, symbol, qty):
		inst = self._universe.get_inst(symbol)
		if inst is not None:
			lot = inst.lot_size
			return int(math.floor(qty/lot +0.5))* lot
		return int(math.floor(qty+0.5))


