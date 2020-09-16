from .algo_instance import get_algo_instance
from strategy.strategy_instance import get_strategy_instance
from strategy.universe import Universe
from strategy.logger import get_logger as strat_get_logger

def order(symbol, qty, price = None, algo=None, start_time = None, end_time = None, max_vol = None):
	strat = get_strategy_instance()
	return strat.order(symbol, qty, price= price, algo = algo, start_time= start_time, end_time=end_time, max_vol=max_vol)

def order_value (symbol, qty, price= None,algo=None, start_time = None, end_time = None, max_vol = None):
	strat = get_strategy_instance()
	return strat.order_value(symbol, qty, price= price, algo = algo, start_time= start_time, end_time=end_time, max_vol=max_vol)

def order_target(symbol, qty, price= None,algo=None, start_time = None, end_time = None, max_vol = None):
	strat = get_strategy_instance()
	return strat.order_target(symbol, qty, price= price, algo = algo, start_time= start_time, end_time=end_time, max_vol=max_vol)

def order_target_value(symbol, qty, price= None,algo=None, start_time = None, end_time = None, max_vol = None):
	strat = get_strategy_instance()
	return strat.order_target_value(symbol, qty, price= price, algo = algo, start_time= start_time, end_time=end_time, max_vol=max_vol)

def add_pipeline(name, func, *args, **kwargs):
	algo = get_algo_instance()
	algo.add_pipeline(name, func, *args, **kwargs)

def round_to_lot(symbol, qty):
	strat = get_strategy_instance()
	return strat.round_to_lot(symbol, qty)

def get_alg_params():
	strat = get_strategy_instance()
	return strat.get_alg_params()

def create_task_rule(date = None, time = None, period = None, start_time=None, end_time= None):
	from algorithm.task_rule import TaskRule
	return TaskRule(date, time, period, start_time= start_time, end_time= end_time)

def schedule_task(name, rule, func, *args, **kwargs):
	alg = get_algo_instance()
	return alg.schedule_task(name, rule, func, *args, **kwargs)

def close_all_positions():
	strat = get_strategy_instance()
	return strat.close_all_positions()

def is_tradable(sym):
	strat = get_strategy_instance()
	return strat.is_tradable(sym)

def get_current_time():
	strat = get_strategy_instance()
	return strat.get_current_time()

def get_current_date():
	strat = get_strategy_instance()
	return strat.get_current_date()

def get_trade_date():
	strat = get_strategy_instance()
	return strat.get_trade_date()

def get_universe():
	return Universe()

def is_live() -> bool:
	strat = get_strategy_instance()
	return strat.is_live()

def get_log_path() -> str:
	strat = get_strategy_instance()
	return strat.log_path

get_logger = strat_get_logger



