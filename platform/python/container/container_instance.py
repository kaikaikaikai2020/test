import threading
context = threading.local()
def get_container_instance():
	return getattr(context, 'container', None)

def set_container_instance(container):
	context.container = container