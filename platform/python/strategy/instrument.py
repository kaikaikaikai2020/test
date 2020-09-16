class Instrument(object):
	def __init__(self, type, symbol):
		self._type = type
		self._symbol = symbol
		self._bid_price = None
		self._ask_price = None
		self._bid_size = None
		self._ask_size = None
		self._prev_last_price = None
		self._last_price = None
		self._last_change_time = None
		self._vwap = None
		self._prev_close = None
		self._lot_size = 1
		self._contract_size = 1
		self._currency = None
		self._adv = None
		self._open_price = None
		self._sod_pos = 0
		self._day_pos = 0
		self._suspended = False
		self._bb_key = None
		self._ric = None
		self._sub_mkt_data = True
	@property
	def type(self):
		return self._type

	@property
	def symbol(self):
		return self._symbol

	@property
	def bid_price(self):
		return self._bid_price

	@property
	def ask_price(self):
		return self._ask_price

	@property
	def bid_size(self):
		return self._bid_size

	@property
	def ask_size(self):
		return self._ask_size

	@property
	def last_price(self):
		return self._last_price

	@property
	def prev_last_price(self):
		return self._prev_last_price

	@property
	def last_change_time(self):
		return self._last_change_time

	@property
	def vwap(self):
		return self._vwap

	@property
	def lot_size(self):
		return self._lot_size

	@property
	def contract_size (self):
		return self._contract_size

	@property
	def prev_close(self):
		return self._prev_close

	@property
	def currency(self):
		return self._currency

	@property
	def tradable(self):
		return not self._suspended

	@property
	def adv(self):
		return self._adv

	@property 
	def open_price(self):
		return self._open_price

	@property
	def fx(self):
		if self.currency == "USD Curncy" or self.currency =='USD':
			return 1

		from algorithm.api import get_universe
		cur_inst = get_universe().get_currency(self.currency)

		if cur_inst is not None:
			return cur_inst.last_price

		else:
			return None

	@property
	def sod_pos(self):
		return self._sod_pos

	@property
	def day_pos(self):
		return self._day_pos

	@property
	def pos(self):
		return self._sod_pos +self._day_pos

	@property
	def ric(self):
		return self._ric

	@property
	def bb_key(self):
		return self._bb_key

	@property
	def suspended(self):
		return self._suspended

	@property
	def sub_mkt_data(self):
		return self._sub_mkt_data

	@symbol.setter
	def symbol(self, val):
		self._symbol = val

	@bid_price.setter
	def bid_price(self, val):
		self._bid_price = val

	@ask_price.setter
	def ask_price(self, val):
		self._ask_price = val

	@bid_size.setter
	def bid_size(self, val):
		self._bid_size = val

	@ask_size.setter
	def ask_size(self, val):
		self._ask_size = val

	@last_price.setter
	def last_price(self, val):
		self._last_price = val

	@last_change_time.setter
	def last_change_time(self, val):
		self._last_change_time = val

	@vwap.setter
	def vwap(self, val):
		self._vwap = val

	@open_price.setter
	def open_price(self, val):
		self._open_price = val

	@lot_size.setter
	def lot_size(self, val):
		self.lot_size = val

	@contract_size.setter
	def contract_size(self, val):
		self._contract_size = val

	@prev_close.setter
	def prev_close(self, val):
		self._prev_close = val

	@currency.setter
	def currency(self, val):
		self._currency = val

	@sod_pos.setter
	def sod_pos(self, val):
		self._sod_pos = val

	@day_pos.setter
	def day_pos(self, val):
		self._day_pos = val

	@suspended.setter
	def suspended(self, val):
		self._suspended = val

	@ric.setter
	def ric(self, val):
		self._ric = val

	@bb_key.setter
	def bb_key(self, val):
		self._bb_key=val

	@sub_mkt_data.setter
	def sub_mkt_data(self, val):
		self._sub_mkt_data =val

	
