import threading
context = threading.local()
def get_backtest_instance():
	return getattr(context, 'backtest', None)

def set_backtest_instance():
	context.backtest = backtest

def get_current_date():
	return get_backtest_instance().current_date

def get_current_time():
	return get_backtest_instance().current_time

def get_start_date():
	return get_backtest_instance().start_date

def get_end_date():
	return get_backtest_instance().end_date

	