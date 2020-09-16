import logging
from strategy.env import get_env

class StrategyLogger(logging.LoggerAdapter):
	def __init__(self, logger):
		super().__init__(logger, extra= {})

	def process(self, msg, kwargs):
		if 'backtest' in kwargs:
			if kwargs['backtest'] == false and get_env() =="backtest":
				pass

			kwargs.pop('backtest')
		return msg, kwargs

	def get_logger(name):
		return StrategyLogger(logging.get_logger(name))