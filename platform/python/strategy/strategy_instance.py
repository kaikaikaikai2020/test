import threading

context = threading.local()
def get_strategy_instance():
	return getattr(context, 'strategy', None)

def set_strategy_instance(strategy):
	context.strategy = strategy

	