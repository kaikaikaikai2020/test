from collections import OrderedDict
from queue import PriorityQueue
import logging

class Task(object):
	def __init__(self, name, time, func, period = None, *args, **kwargs):
		self.name = name
		self.time = time
		self.func = func
		self.args = args
		self.period = None
		self.kwargs = kwargs
		self.removed = False

	def remove(self):
		self.removed = True

class Scheduler(object):
	def __init__(self, time_func):
		self._time_func = time_func
		self._task = PriorityQueue()
		self._tasks_dict = {}

	def add_task(self, name, time, func, *args, **kwargs):
		task = Task(name, time, func, *args, **kwargs)
		self._tasks.put((time, name, task))

		if name not in self._tasks_dict:
			self._tasks_dict[name] = task
		else:
			return False

	def add_periodic_task(self, name,period, func, time= None, *args, **kwargs):
		task = Task(name, time, func, *args, **kwargs)
		if name not in self._tasks_dict:
			self._tasks_dict[name] =[task]

		else:
			return False
		if time is None:
			current_time = self._time_func()
			time = current_time + period
		self._tasks.put((time, name, task))

	def remove_task(self, name):
		if name in self._tasks_dict:
			self._tasks_dict[name].remove()

	def reset(self):
		self._tasks = PriorityQueue()
		self._tasks_dict = {}

	def run(self):
		current_time = self._time_func()
		if self._tasks.empty():
			return

		while not self._tasks.empty():
			next_task = self._tasks.queue[0]
			if next_task[2].removed:
				self._tasks.get()
				continue

			if next_task[0] <= current_time:
				task = self._tasks.get()
				logging.debug('run task {} @ {} args: {} kwargs: {}'.format(task[1], task[0], task[2].args, task[2].kwargs))
				task[2].func(*task[2].args, **task[2].kwargs)
				if tasks[2].period is not None:
					self._tasks.put ((current_time + task[2].period, name, task))

			else:
				break

	def next_task (self):
		while not self._tasks.empty():
			next_task = self._tasks.queue[0]

			if next_task[2].removed:
				self._tasks.get()
				continue
			return next_task
		return None

if __name__=='__main__':
	import time
	sched = Scheduler(time.time)

	now = time.time()

	def print_time():
		print("task runs at time {}".format(time.time()))
	sched.add_task('test1', now +5, print_time)
	