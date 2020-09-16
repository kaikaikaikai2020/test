class Algorithm (object):
	def __init__(self, init=None, handle_data = None, before_trading_start = None, after_trading_end = None, name= "unnamed"):
		self._init = init
		self._handle_data = handle_data
		self._before_trading_start = before_trading_start
		self._after_trading_end = after_trading_end
		self._pipeline_names = []
		self._pipelines = {}
		self._name = name
		self.tasks = {}

	@property
	def name (self):
		return self._name
	def add_pipeline(self, name, func, *args, **kwargs):
		if name not in self._pipelines:
			self._pipeline_names.append(name)
		self._pipelines[name] = (func, args, kwargs)
	def init(self, context):
		if self._init is not None:
			return self._init(context)
		return True

	def set_handle_data(self,func):
		self._handle_data = func

	def has_handle_data(self):
		return self._handle_data is not None

	def handle_data(self, context,data):
		if self._handle_data is not None:
			return self._handle_data(context, data)
		return True
	def set_before_trading (self, func):
		self._before_trading_start = func

	def before_trading_start(self, context, data):
		if self._before_trading_start is not None:
			return self._before_trading_start(context, data)
		return True

	def after_trading_end (self, context, data):
		if self._after_trading_end is not None:
			return self._after_trading_end(context, data)
		return True

	def schedule_task(self, name, rule, task, *args, **kwargs):
		self.tasks[name] = (rule, task, args, kwargs)

	def prepare_data(self, universe = None, start_date = None, end_date = None, external_datasets = None, symbology='bbgid', data_recipe = None, external_datasets = None, symbology ='bbgid', data_recipe=None, external_data = None, col_map=None, sod_pos=None,update_cache =None):
		print("prepare_data")
		update_cache = self._sim_params.update_cache if update_cache is not None else update_cache
		start_date = self._start_date if start_date is not None else start_date
		end_date = self._end_date if end_date is None else end_date
		universe = self._universe if universe is None else universe
		symbology = self._symbology

		if not isinstance(start_date, datetime.datetime):
			start_date = pd.Timestamp(start_date).to_pydatetime()

		if not isinstance(end_date, datetime.datetime):
			end_date = pd.Timestamp(end_date).to_pydatetime()

		if universe is None:
			raise ValueError("universe is none")

		datasets ={}
		if external_datasets is not None:
			for name in external_datasets:
				datasets[name] = copy.deepcopy(external_datasets[name])

		if 'main' not in datasets:
			datasets['main'] =[]

		main_datasets = datasets['main']

		if self._px_data_source == 'bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.px')
			self._col_map['market_status'] = 'market_status'
			self._col_map['cur'] = 'crncy'
			self._col_map['lot_size'] = 'px_round_lot_size'
			self._col_map['contract_size'] = 'fut_cont_size'
			self._col_map['tick_size'] = 'fut_tick_size'

			self._col_map['close'] = 'px_last'
			self._col_map['close_adj'] = 'px_last_adj'
			self._col_map['open'] = 'px_open'
			self._col_map['high'] = 'px_high'
			self._col_map['low'] = 'px_low'
			self._col_map['volume'] = 'px_volume'

		if self._sector_data_source == 'bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.gics')
			self._col_map['sector'] = 'gics_sector'
			self._col_map['sector_name'] = 'gics_sector_name'
			self._col_map['industry'] = 'gics_industry'
			self._col_map['industry_name'] = 'gics_industry_name'
		if self._vwap_data_source =='trth':
			main_datasets.append('datasets.reuters.trth.vwap')
			self._col_map['vwap'] = 'vwap'
		if self._country_index_data_source == 'lager':
			main_datasets.append('datasets.country_index.index.country_index')
			self._col_map['adv'] ='adv'

		if self._borrow_cost_data_source == 'markit':
			main_datasets.append('dataset.markit.short.markit_short')
			self._col_map['borrow_rate'] = 'saf'
			self._col_map['borrow_rate_score'] = 'vwaf_score_1_day'

		datasets['main'] = main_datasets
		data_post = {'main': [add_tradable, enrich_ndf, partial(add_lot_size, lot_size_col = self._col_map['lot_size']), partial(add_contract_size, contract_size_col= self._col_map['contract_size'])]}

		if self._strategy_type =='intraday':
			bar_datasets=[]
			bar_datasets.append('datasets.reuters.trth.bar')
			datasets['bar'] = bar_datasets
		data_loading_kwargs = {}

		if self._sim_params.data_loading_kwargs is not None:
			data_loading_kwargs = self._sim_params.data_loading_kwargs
		input_data = None
		
		one_day = pd.Timedelta(days= 1)
		if self._sim_params.production_mode:
			yesterday = self._local_today - one_day
			if start_date < yesterday:
				input_data = self._data_loader.load(receipe = data_recipe, datasets= datasets, universe= universe, symbology = symbology, start_date = start_date, end_date = yesterday, use_cache= self._sim_params.use_cache, update_cache = update_cache, post = data_post, **data_loading_kwargs)
			input_data_today = self._data_loader.load(receipe = data_recipe, datasets= datasets, universe= universe, symbology = symbology, start_date = self._local_today, end_date = self._local_today, use_cache= False, update_cache = False, post = data_post, **data_loading_kwargs)				
			if input_data is not None:
				input_data.append(input_data_today)
			else:
				input_data = input_data_today
		else:
			if start_date <=end_date:
				input_data = self._data_loader.load(receipe = data_recipe, datasets= datasets, universe= universe, symbology = symbology, start_date = start_date, end_date = yesterday, use_cache= self._sim_params.use_cache, update_cache = update_cache, post = data_post, **data_loading_kwargs)
			else:
				raise ValueError("start date {} is after end date {}".format(start_date, end_date))

		if input_data is None:
			raise Exception("no dataset is loaded")

		if external_data is not None:
			input_data['main'] = input_data['main'].join(external_data)
		max_start = None
		min_end = None
		for name, df in input_data.dfs.items():
			if len(df.index.names) >1:
				data_start = df.index.levels[0][0].floor(freq ='D')
				data_end = df.index.levels[0][-1].floor(freq ='D')
			else:
				data_start = df.index[0].floor(freq ='D')
				data_end = df.index[-1].floor(freq ='D')
			if data_start!= start_date or data_end!= end_date:
				logging.warn("{} data is actual start end doesnt match input {} {} {} {}".format(name, data_start.date(), data_end.date(), start_date.date(), end_date.end()))
			if max_start is None:
				max_start = data_start
			else:
				max_start = max(max_start, data_start)

			if min_end is None:
				min_end = data_end
			else:
				min_end = min(min_end,data_end)
		if start_date is None:
			data_start_date = max_start
		else:
			data_start_date = max(max_start, pd.Timestamp(start_date))

		if end_date is None:
			data_end_date = min_end
		else:
			data_end_date = min(min_end, pd.Timestamp(end_date))
		print("data common start date is {} and end date is {}".format(data_start_date.date(), data_end_date.date()))

		if not self._sim_params.include_oos.data:
			last_day_timestamp = self._local_today - relativedelta(month=6)
			if data_end_date >last_day_timestamp:
				print("Data after {} is reserved for out of sample test".format(last_day_timestamp.date()))
				data_end_date = last_day_timestamp
			if data_end_date <= data_start_date:
				raise ValueError('end date {} after oos adj is before start date {} please use another one'.format(data_end_date, data_start_date))
		else:
			logging.warn("including oos data")
		self.actual_start_date = data_start_date
		self.actual_end_date = data_end_date
		self._input_data = input_data
		main_data = self._input_data.dfs['main']
		if col_map is not None:
			self._col_map.update(col_map)
		rename_map = {v: k for k, v in self._col_map.items()}
		main_data.rename(columns= rename_map, inplace = True)

		if 'fx' not in main_data:
			if 'cur' not in main_data:
				raise ValueError("cur not in input data")
			dfs =[]
			for cur in main_data['cur'].unique():
				if pd.isnull(cur):
					continue
				fx = pd.DataFrame(index = main_data.index.levels[0])
				if cur=='USD':
					fx['fx']=1
				else:
					if cur =='GBp':
						cur_symbol = 'GBP Curncy'
					else:
						cur_symbol = cur +' Curncy'
					cur_px = main_data.xs(cur_symbol, level=1)['close']
					if cur in ['EUR', 'AUD', 'GBP', 'GBp']:
						fx['fx'] = 1/cur_px
					else:
						fx['fx'] = cur_px
					if cur =='GBp':
						fx['fx']*-100
				fx['cur'] = cur
				dfs.append(fx)
			if len(dfs) >0:
				df_fx = pd.concat(dfs)
				df_fx = df_fx.reset_index().sort_values(by=['date','cur'])
				main_data = main_data.reset_index()
				main_data = pd.merge_asof(main_data, df_fx, on='date', by='cur')
				main_data = main_data.set_index(['date', symbology])
			else:
				raise ValueError('fail to add fx column')

		main_data['tz'] = main_data[~pd.isnull(main_data['country_iso'])]['country_iso'].map(country_timezone)
		main_data['tcost_rate'] = np.nan
		main_data['long_financing_rate'] = np.nan
		main_data['short_financing_rate'] = np.nan
		main_data['buy_tax_rate'] = np.nan
		main_data['sell_tax_rate'] = np.nan
		print('adding adj price col')
		fut_data = main_data[main_data['product']=='future']
		if len(fut_data)>0:
			fut_data_adj = fut_data[['fut_adj']].copy()
			fut_data_adj['cum_adj'] = fut_data_adj.groupby(self._symbology)['fut_adj'].shift(-1)
			fut_data_adj['cum_adj'].fillna(1, inplace=True)
			main_data.loc[main_data['product']=='future', 'cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cum_adj'].apply(lambda x:x[::-1].cumprod()[::-1])
			root_symbols = fut_data['root_symbol'].dropna().unique()
			for root in root_symbols:
				latest_contract_size = fut_data.xs(root, level=1)['contract_size'][-1]
				main_data.loc[(slice(None), root), 'contract_size'] = latest_contract_size
		stock_data = main_data[main_data['product']=='stock']
		if len(stock_data)>0:
			stock_data_adj = stock_data[['cp_adj_px']].copy()
			stock_data_adj['cum_adj_px'] = stock_data_adj.groupby(self._symbology)['cp_adj_px'].shift(-1)
			stock_data_adj['cum_adj_px'].fillna(1, inplace=True)
			main_data.loc[main_data['product']=='stock', 'cum_adj_px'] = stock_data_adj.groupby(self._symbology)['cum_adj_px'].apply(lambda x:x[::-1].cumprod()[::-1])

			if 'borrow_rate' in main_data:
				main_data['borrow_rate'] = abs(main_data['borrow_rate']).ffill()
			if 'borrow_rate_score' in main_data:
				main_data['borrow_rate_score'] = abs(main_data['borrow_rate_score']).ffill()

			from simulation.commission import commission_rates
			from simulation.financing import long_financing_rates, short_financing_rates
			from simulation.tax import buy_tax_rates, sell_tax_rates
			main_data['tcost_rate'] = stock_data['country_iso'].map(commission_rates)
			main_data['long_financing_rate'] = stock_data['country_iso'].map(long_financing_rates)
			main_data['short_financing_rate'] = stock_data['country_iso'].map(short_financing_rates)
			main_data['buy_tax_rate'] = stock_data['country_iso'].map(buy_tax_rates)
			main_data['sell_tax_rate'] = stock_data['country_iso'].map(sell_tax_rates)

		if 'cum_adj_px' in main_data:
			main_data['cum_adj_px'].fillna(1, inplace = True)
			for col in ['open', 'close', 'low', 'high', 'vwap']:
				if col in main_data:
					main_data[col+'_adj'] = main_data[col]*main_data['cum_adj_px']
					main_data[col+'_adj'].fillna(main_data[col], inplace=True)
					main_data.lc[main_data['product']=='future', col] = main_data[col+'_adj']
		from simulation.financing import future_financing_rates

		if 'future' in main_data['product'].unique():
			main_data.loc[main_data['product']=='future', 'long_financing_rate'] = main_data.loc[main_data['product']=='future', 'country_iso'].map(future_financing_rates)
			main_data.loc[main_data['product']=='future', 'short_financing_rate'] = main_data.loc[main_data['product']=='future', 'long_financing_rate']

		main_data['tcost_rate'].fillna(self._sim_params.tcost, inplace=True)
		main_data['long_financing_rate'].fillna(self._sim_params.long_financing_cost, inplace= True)
		main_data['short_financing_rate'].fillna(self._sim_params.short_financing_cost, inplace= True)
		main_data['buy_tax_rate'].fillna(self._sim_params.buy_tax_cost, inplace= True)
		main_data['sell_tax_rate'].fillna(self._sim_params.sell_tax_cost, inplace= True)

		if self._sim_params.borrow_cost is not None:
			main_data['borrow_rate'] = self._sim_params.borrow_cost
		if 'slippage' not in main_data:
			main_data['slippage'] = np.nan

		if is_number(self._sim_params.slippage_cost):
			main_data['slippage'].fillna(self._sim_params.slippage_cost, inplace=True)
		elif isinstance(self._sim_params.slippage_cost, dict):
			for k, v in self._sim_params.slippage_cost.items():
				if k in ['stock', 'future', 'currency']:
					main_data.loc[main_data['product']==k, 'slippage'] = v
				else:
					main_data.loc[(slice(None), k), 'slippage']=v
		main_data['slippage'].fillna(0, inplace=True)
		for col in ['tcost_rate','long_financing_rate', 'short_financing_rate', 'borrow_rate', 'buy_tax_rate', 'sell_tax_rate', 'slippage']:
			main_data[col]/=10000.0
		if 'adv' in main_data:
			main_data['adv'].ffill(inplace= True)

		self._inst_input = main_data.loc[data_start_date : data_end_date]
		self._inst_input = self._inst_input.reset_index().set_index(['date', self._symbology])
		self._inst_stat = pd.DataFrame(index = self._inst_input.index)
		self._inst_custom = pd.DataFrame(index = self._inst_input.index)
		self._pf_input = pd.DataFrame(index = self._inst_input.index.levels[0])
		self._pf_stat = pd.DataFrame(index = self._pf_input.index)
		self._pf_custom = pd.DataFrame(index = self._pf_input.index)

		self._inst_stat['sod_pos'] = np.nan
		self._inst_stat['pos'] = np.nan
		self._inst_stat['settled_pos'] = 0.0
		if 'init_capital' in self._sim_params:
			self._portfolio.init_capital = self._sim_params.init_capital
		if 'scale_factor' in self._sim_params:
			self._scale_factor = self._sim_params.scale_factor
		if self._sim_params.strategy_type =='intraday':
			self._inst_bar = self._input_data.dfs['bar'].reset_index()
			print("adj the timezone of the bar data")
			tz = pytz.timezone(self._sim_params.timezone)
			self._inst_bar['msgstamp'] = self._inst_bar['msgstamp'].dt.tz_localize('UTC').dt.tz_convert(self._sim_params.timezone).dt.tz_localize(None)
			self._inst_bar['date'] = self._inst_bar['msgstamp'].dt.date
			self._inst_bar['time'] = self._inst_bar['msgstamp'].dt.time
			self._inst_bar.rename(columns={'msgstamp':'timestamp'}, inplace=True)
			self._inst_bar['trade_date'] = self._inst_bar['date'].mask(self._inst_bar['time']<datetime.time(7,0), self._inst_bar['date'] - pd.Timedelta(days=1)) 

			self._inst_bar = self.+_inst_bar.set_index(['timestamp', symbology])
			self._input_data.dfs['bar'] = self._inst_bar
		else:
			if self._sim_params.order_price not in self._inst_input:
				raise ValueError("Column {} not avaialbe in the data".format(self._sim_params.order_price))

		if self._sim_params.production_mode:
			if sod_pos is not None:
				for k in sod_pos.index:
					if (self._local_today, k) in self._inst_stat.index:
						self._inst_stat.loc[(self._local_today, k), 'sod_pos'] = sod_pos[k]

		if self._hedging:
			if self._sim_params.hedge_symbol not in self._inst_input.index.levels[1]:
				raise ValueError("datat for hedge symbol {} not loaded".format(self._sim_params.hedge_symbol))
			self._hedge_data = self._inst_input.loc[(slice(None), self._sim_params.hedge_symbol),].reset_index(level=1, drop = True)
		self._data_cluster.add_data('instrument_input', self._inst_input)
		self._data_cluster.add_data('portfolio_input', self._pf_input)

		if self._sim_params.strategy_type =='intraday':
			self._data_cluster.add_data('bar', self._inst_bar, frequency='5m')

		self._input_data.dfs['main']=main_data
		for name in self._input_data.dfs:
			if name not in ['main', 'bar']:
				self._data_cluster.add_data(name, self._input_data.dfs[name])
		self._data_cluster.set_main_data('instrument_input')
