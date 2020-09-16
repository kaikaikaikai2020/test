import zmq
class Broker(object):
	def __init__(self):
		self._context = zmq.Context()
		self._pub = self._context.socket(zmq.PUB)
		self._pub.bind("tcp://*:6557")

		self._sub = self._context.socket(zmq.SUB)
		self._sub.bind("tcp://*:6558")
		self._sub.setsockopt(zmq.SUBSCRIBE, b'')

		self._router = self._context.socket(zmq.ROUTER)
		self._router.bind("tcp://*:6555")

		self._dealer = self._context.socket(zmq.DEALER)
		self._dealer.bind("tcp://*:6556")

		self._poller = zmq.Poller()
		self._poller.register(self._router, zmq.POLLIN)
		self._poller.register(self._dealer, zmq.POLLIN)
		self._poller.register(self._sub, zmq.POLLIN)

	def run(self):
		while True:
			try:
				socks = dict(self._poller.poll(timeout=5000))
			except KeyboradIntercept:
				break

			print(sock)
			if socks.get(self._router)==zmq.POLLIN:
				self.process_router()
			if socks.get(self._dealer)==zmq.POLLIN:
				self.process_dealer()
			if socks.get(self._sub)==zmq.POLLIN:
				self.process_sub()

	def process_dealer(self):
		msg = self._dealer.recv_multipart()
		print('dealer:', msg)
		self._router.send_multipart(msg)


	def process_router(self):
		msg = self._router.recv_multipart()
		print('router:', msg)
		self._dealer.send_multipart(msg)

	def process_sub(self):
		msg = self._sub.recv_multipart()
		print('sub:', msg)
		self._pub.send_multipart(msg)


if __name__ =='__main__':
	broker = Broker()
	broker.run()