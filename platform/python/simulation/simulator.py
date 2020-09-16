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
		self._bt = bt
		self._px_data = None
		self._ref_data = None
		self._date = None
		self._max_exec = None
		self._exec_dict = {}
		self._universe = get_universe

		if 'max_execution' in self._params:
			self._max_exec = self._params.max_execution

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

	def order(self,order):
		symbol = order.symbol
		qty = order.qty

		if symbol not in self._ref_data.index or not self._ref_data.loc[symbol,'tradable']:
			logger.error(symbol +' not tradable')
			return False

		if qty == 0:
			print("0 qty order sent to simulator")
			return False

		day_order = True if isinstance(order.price, str) else False

		if not day_order and symbol not in self._px_data.index:

			print("symbol {} not in the universe".format(symbol))
			return False

		if symbol not in self.exec_dict:
			self._exec_dict[symbol] = Exec()

		exe = self._exec_dict[symbol]

		if self._max_exec is not None:
			if day_order:
				px_data = self._ref_data
			else:
				px_data = self._px_data

		exec_cap = px_data.loc[symbol, 'volume'] *self._max_exec

		if abs(qty) + exe.bar >exec_cap:
			exec_allowed = exec_cap - cur_exec

			filled_qty = self._bt.round_to_lot(symbol, np.sign(qty)*exec_allowed)

			if abs(filled)>0:
				print("order qty trncated from {} to {}".format(qty, filled_qty))

			else:
				print("nth filled due to hit the bar exeecution limit {}".format(exec_cap))

				return False
		else:
			filled_qty = qty
		exe.bar +=abs(filled_qty)
		exe.day +=abs(filled_qty)

		trade = Trade(id=self._generate_trade_id(), order_id = order.id, symbol = order.symbol, timestamp = order.timestamp, price = order.price, qty= filled_qty)
		self._bt.on_trade()
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


