from container.container_instance import set_container_instance
from algorithm.algo_instance import set_algo_instance

from utils.dotdict import dotdict, to_dotdict

class Container(object):
	def __init__(self, alg, alg_params = None):
		set_container_instance(self)
		self._alg = alg

		if alg_params is not None:
			self._alg_params = to_dotdict(alg_params)
		else:
			self._alg_params = None

		set_algo_instance(alg)

	def order(self, symbol, qty, price = None):
		pass
	def order_value (self, symbol, value, price= None):
		pass

	def order_target(self, symbol, target, price = None):
		pass

	def order_target_value(self, symbol, target_value, price= None):
		pass
	def add_pipeline(self, name, func, *args, **kwargs):
		pass

	def round_to_lot(self, symbol, qty):
		pass
	def get_alg_params(self):
		return self._alg_params
	def close_all_positions (self):
		pass

	def is_tradable(self, sym):
		pass
