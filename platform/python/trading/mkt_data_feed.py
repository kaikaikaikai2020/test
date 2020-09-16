from sharememory.intradaydataclient3 import bloombergClient

from config.config import Config

class MktDataFeed(object):
	def __init__(self):
		cfg= Config().get()
		if 'MktDataFeed' not in cfg:
			raise ValueError("MktDataFeed not found in config")

		bbg_broker = cfg['MktDataFeed']['bloomberg_broker']
		self._bbg_client = bloombergClient(bbg_broker)

	def subscribe(self, symbols):
		self._bbg_client.requestMoreInstrument(newInstrumentList = symbols, depth=5)

	def get_last_price(self, symbol):
		return self._bbg_client.getPrice(symbol)

	def get_bid_price(self, symbol):
		return self._bbg_client.getBid(symbol)

	def get_ask_price(self, symbol):
		return self._bbg_client.getAsk(symbol)

	def get_bid_size(self, symbol):
		return self._bbg_client.getBidVolume(symbol,1)
	def get_ask_size(self, symbol):
		return self._bbg_client.getAskVolume(symbol,1)
	def get_is_suspended(self, symbol):
		return self._bbg_client.getIsSuspended(symbol) ==True

	def get_vwap(self, symbol):
		return self._bbg_client.getVwap(symbol)

	def get_currency(self, symbol):
		return self._bbg_client.getCrncyName(symbol)

	def get_lot_size(self, symbol):
		return self._bbg_client.getLotSize(symbol)

	def get_contract_size(self, symbol):
		return self._bbg_client.getContractSize(symbol)

	def get_prev_close(self, symbol):
		return self._bbg_client.getPrevClosePrice(symbol)

	def get_open_price(self, symbol):
		return self._bbg_client.getOpen(symbol)

