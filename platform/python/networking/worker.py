import zmq
import time

class Work(object):
	def __init__(self, broker_ip, dealer_port= 6556, sub_port =6558):
		self._context = zmq.Context()
		self._req = self._context.socket(zmq.REP)
		self._req.connect("tcp://{}:{}".format(broker_ip, dealer_port))

		self._pub = self._context.socket(zmq.PUB)
		self._pub.connect("tcp://{}:{}".format(broker_ip, sub_port))
		

		self._poller = zmq.Poller()
		self._poller.register(self._req, zmq.POLLIN)


	def process_req(self):
		msg = self._req.recv()
		self.process_rep_msg(msg)

	def process_req_msg(self, msg):
		print('req:', msg)
		if msg == b'heartbeat':
			self.send_hb()

	def send_hb(self):
		self._rep.send_string('heartbeat')

	def pub_hb(self):
		self._pub.send_string('heartbeat')


	def run(self):
		while True:
			try:
				socks = dict(self._poller.poll(timeout=5000))

			except KeyboardIntercept:
				break
			print(socks)
			if len(socks) ==0:
				self.pub_hb()
			else:
				if socks.get(self._rep) == zmq.POLLIN:
					self.process_rep
if __name__ == '__main__':
	worker = Worker(broker_ip = '10.81.32.13')
	worker.run()