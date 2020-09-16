def StockDataset(object):
	def __init__(self):
		if self._px_data_source =='bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.px')

			self._col_map['market_status']='market_status'
			self._col_map['cur']='crncy'
			self._col_map['lot_size'] = 'px_round_lot_size'
			self._col_map['contract_size'] = 'fut_cont_size'
			self._col_map['tick_size']= 'fut_tick_size'
			self._col_map['close'] ='px_last'
			self._col_map['close_unadj'] = 'px_last_unadj'
			self._col_map['open'] ='px_open'
			self._col_map['high'] ='px_high'
			self._col_map['low'] = 'px_low'
			self._col_map['volume']='px_volume'
		if self._sector_data_source =='bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.gics')
			self._col_map['sector'] = 'gics_sector'
			self._col_map['sector_name']= 'gics_sector_name'
			self._col_map['industry']='gics_industry'
			self._col_map['industry_name'] = 'gics_industry_name'
		if self._vwap_data_source=='trth':
			main_datasets.append('datasets.reuters.trth.vwap')
			self._col_map['vwap']='vwap'
		if self._country_index_data_source =='lager':
			main_datasets.append('datasets.country_index.index.country_index')
			self._col_map['adv']='adv'
		if self._borrow_cost_data_source =='markit':
			main_datasets.append('datasets.markit.short.markit_short')
			self._col_map['borrow_rate'] ='saf'
			self._col_map['borrow_rate_score'] = 'vwaf_score_1_day'

def FutureDataset(object):
	def __init__(self):
		if self._px_data_source =='bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.px')

			self._col_map['market_status']='market_status'
			self._col_map['cur']='crncy'
			self._col_map['lot_size'] = 'px_round_lot_size'
			self._col_map['contract_size'] = 'fut_cont_size'
			self._col_map['tick_size']= 'fut_tick_size'
			self._col_map['close'] ='px_last'
			self._col_map['close_unadj'] = 'px_last_unadj'
			self._col_map['open'] ='px_open'
			self._col_map['high'] ='px_high'
			self._col_map['low'] = 'px_low'
			self._col_map['volume']='px_volume'

def CurrencyDataset(object):
	def __init__(self):
		if self._px_data_source =='bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.px')

			self._col_map['market_status']='market_status'
			self._col_map['cur']='crncy'
			self._col_map['lot_size'] = 'px_round_lot_size'
			self._col_map['contract_size'] = 'fut_cont_size'
			self._col_map['tick_size']= 'fut_tick_size'
			self._col_map['close'] ='px_last'
			self._col_map['close_unadj'] = 'px_last_unadj'
			self._col_map['open'] ='px_open'
			self._col_map['high'] ='px_high'
			self._col_map['low'] = 'px_low'
			self._col_map['volume']='px_volume'

def StockBarDataset(object):
	pass

def FutureBarDataset(object):
	pass

