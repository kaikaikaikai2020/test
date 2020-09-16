import threading
context = threading.local()
def get_algo_instance():
	return getattr(context,'algo', None)
def set_algo_instance(algo):
	context.algo = algo