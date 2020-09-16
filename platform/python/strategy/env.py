from strategy.strategy_instance import get_strategy_instance
from backtester.backtester import Backtester

def get_env():
	strat_instance = get_strategy_instance()
	if strat_instance is not None:
		strat_impl = strat_instance.get_impl()
		if strat_impl is not None:
			return 'backtest' if isinstance(strat_impl, Backtester) else 'engine'
		else:
			return None

	return None