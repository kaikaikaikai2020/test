from qpython import qconnection
from qpython.qcollection import QDictionary

class KDBClient(object):
	def __init__(self, host, port, user= None, pwd = None, pandas= False):
		self.q = qconnection.QConnection(host= host, port= port, username = user, password = pwd, pandas= pandas, numpy_temporals = True)
		self.q.open()
	def __enter__(self):
		return self

	def __exit__(self, exc_type, exc_value, traceback):
		self.q.close()
		if exc_type is not None:
			print((exc_type, exc_value, traceback))

	def execute(self, statement, *argv):
		return self.q(statement, *argv)

	def async_execute(self, statement, *argv):
		return self.q.sendAsync(statement, *argv)

	def receive(self):
		return self.q.receive()

	def close(self):
		self.q.close()

if __name__ == "__main__":
	with KDBClient() as client:
		print((client.execute('{til x)',10)))
		print((client.execute('til 10')))