import zmq
import time

class Client(object):
	def __init__(self, broker_ip, router_port= 6555, pub_port =6557):
		self._context = zmq.Context()
		self._req = self._context.socket(zmq.REQ)
		self._req.connect("tcp://{}:{}".format(broker_ip, router_port))

		self._sub = self._context.socket(zmq.SUB)
		self._req.connect("tcp://{}:{}".format(broker_ip, pub_port))
		self._sub.setsockopt(zmq.SUBSCRIBE, b'')

		self._poller = zmq.Poller()
		self._poller.register(self._req, zmq.POLLIN)
		self._poller.register(self._sub, zmq.POLLIN)

	def send_req(self, msg):
		self._req.send_string(msg)

	def process_req(self):
		msg = self._req.recv_multipart()
		self.process_rep_msg(msg)

	def process_sub(self):
		msg = self._sub.recv_multipart()
		self.process_pub_msg(msg)

	def process_rep_msg(self, msg):
		print('rep', msg)

	def process_pub_msg(self, msg):
		print('pub',msg)

	def send_hb(self):
		self._req.send_string('heartbeat')

	def run(self):
		while True:
			self.send_hb()
			self.process_req()
			try:
				socks = dict(self._poller.poll(timeout=5000))

			except KeyboardIntercept:
				break

			if socks.get(self._req) == zmq.POLLIN:
				self.process_req()
			if socks.get(self._sub) == zmq.POLLIN:
				self._process_sub()

if __name__ == '__main__':
	client = Client(broker_ip = '10.81.32.13')
	client.run()