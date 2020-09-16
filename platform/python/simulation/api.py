from .algo_instance import get_algo_instance
from strategy.strategy_instance import get_strategy_instance
from strategy.universe import Universe
from strategy.logger import get_logger as strat_get_logger
from .backtest_instance import get_backtest_instance
from .backtest import Backtest
from .result import result
from .algorithm import Algorithm


def order(symbol, qty, price = None):
	bt = get_backtest_instance()
	return bt.order(symbol, qty, price)

def order_value (symbol, value, price= None):
	bt = get_backtest_instance()
	return bt.order_value(symbol, value, price)

def order_target(symbol, target, price= None):
	bt = get_backtest_instance()
	return bt.order_target(symbol, target, price)

def order_target_value(symbol, target_value, price= None):
	bt = get_backtest_instance()
	return bt.order_target_value(symbol, target_value, price)

def create_algorithm(init= None, handle_data = None, name = None):
	return Algorithm(init= init, handle_data= handle_data, name= name)

def add_pipeline(name, func, *args, **kwargs):
	algo = get_algo_instance()
	algo.add_pipeline(name, func, *args, **kwargs)

def load_result(path = None, id = None, input_data= True, pipeline = True):
	return Result.load(path, id, input_data, pipeline)


def display_summary(result):
	result.display_summary()

def plot_result(result):
	result.plot()

def get_alg_params():
	bt = get_backtest_instance()
	return bt.get_alg_params()

def schedule_task(name, rule, func, *args, **kwargs):
	alg = get_algo_instance()
	return alg.schedule_task(name, rule, func, *args, **kwargs)

def close_all_positions():
	bt = get_backtest_instance()
	return bt.close_all_positions()

def is_tradable(sym):
	bt = get_backtest_instance()
	return bt.is_tradable(sym)
