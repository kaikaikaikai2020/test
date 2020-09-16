class TaskRule(object):
	def __init__(self, date = None, time = None, period = None, start_time=None, end_time= None):
		self.date = date
		self.time = time
		self.period = period
		self.start_time = start_time
		self.end_time = end_time