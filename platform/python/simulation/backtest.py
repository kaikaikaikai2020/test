from utils.dotdict import dotdict, to_dotdict
from utils.epsilon import equal_zero
from utils.number import is_number
from utils.scheduler import Scheduler
from .simulator import Simulator
from .portfolio import Portfolio
from .algo_instance import set_algo_instance
from .backtest_instance import set_backtest_instance
from .data_cluster import DataCluster
from .pipeline import load_pipeline, save_pipeline
from .order import order
from .order_book import OrderBook
from .trade_book import TradeBook
from .result import Result
from .tz import country_timezone

from loader.data_enrichment import add_tradable, enrich_ndf
from simulation.data_post import add_lot_size, add_contract_size
from loader.recipe import Recipe

from functools import partial
import pandas as pd
import numpy as np
import math
import logging 
import datetime
import sys
import os
import uuid
import pytz
import copy
import getpass
import cProfile, pstats, io
from .plotting import *
from loader.data_loader import DatatLoader
from dateutil.relativedelta import relativedelta

default_params = {
	'order_price':'close',
	'slippage': 0,
	'tcost':0,
	'long_financing_cost':0,
	'short_financing_cost':0,
	'buy_tax_cost':0,
	'sell_tax_cost':0,
	'borrow_cost':0,
	'scale_factor':1,
	'hedge_symbol': None,
	'use_cache':True,
	'save_result':True,
	'result_path': None,
	'atol': 1e-8,
	'rtol': 1e-5,
	'load_pipelines':None,
	'load_pipelines_path':None,
	'save_pipelines':True,
	'disable_lookforward_bias_check':False,
	'pipeline_only': False,
	'data_feed_source':None,
	'include_oos_data':False,
	'production_mode':False,
	'strategy_type': 'daily',
	'fill_mode': 'full',
	'fill_ratio':1.0,
	'timezone':'Asia/Hong Kong',
	'open_time':"09:00:00",
	'close_time':"16:00:00",
	'day_cutoff_time':"07:00:00",
	'stock_total_return':True
}

class Backtester(object):
	def __init__(self,  sim_params=default_params, alg= None,  start_date = None, end_date=None, external_data = None, external_datasets = None, symbology= 'bbgid', col_map = None, alg_params = None, sod_pos = None, load_dat_only=False, result_id= None, data_recipe=None):

		print("Initializing backtest")
		set_backtest_instance(self)

		if alg is None:
			raise ValueError('none alg')

		if not isinstance(start_date, datetime.datetime):
			self._start_date = pd.Timestamp(start_date).to_pydatetime()

		if not isinstance(end_date, datetime.datetime):
			self._end_date = pd.Timestamp(end_date).to_pydatetime()

		self._context = dotdict({})
		self._current_date = None
		self._current_time = None
		self._context.portfolio = Portfolio()
		self._portfolio = self._context.portfolio

		self._sim_params = dotdict(default_params)
		if sim_params is not None:
			self._sim_params.update(sim_params)		
		self._symbology = symbology
		self._universe = universe

		if alg_params is not None:
			self._alg_params = to_dotdict(alg_params)
		else:
			self._alg_params = None

		self._simulator = Simulator(self)
		self._simulator.set_fill_mode(self._sim_params.fill_mode, self._sim_params.fill_ratio)
		self._detect_lookforward_bias = True
		self._current = None
		self._scale_factor = 1
		self._data_loader = DataLoader()
		self._px_data_source= 'bbg'
		self._vwap_data_srouce = 'trth'
		self._borrow_cost_data_source ='markit'
		self._sod_pos = sod_pos
		self._data_cluster = DataCluster()
		self._inst_input = None
		self._pf_input = None
		self._inst_stat = None
		self._pf_stat = None
		self._inst_custom = None
		self._pf_custom = None		
		self._inst_bar = None
		self._hist_result = None
		self._pipeline_results = None
		self._strategy_type = self._sim_params.strategy_type
		self._datasets =[]
		if self._sim_params.hedge_symbol is not None:
			self._hedging = True
		else:
			self._hedging = False

		self._order_book = OrderBook()
		self._trade_book = TradeBook()
		self._current_order_id = None
		self._order_record = pd.DataFrame()
		self._trade_record = pd.DataFrame()				
		self._sched = Scheduler(self.get_current_time, time_type= "pandas_time")
		self._task = {}
		self._local_now = datetime.datetime.now(pytz.timezone(self._sim_params.timezone))		
		self._local_today = pd.Timestamp(self._local_now.date())

		self._col_map = dotdict(
			close = 'close', 
			close_unadj = 'close_unadj',
			vwap ='vwap',
			adv ='adv', 
			sector = 'sector',
			product = 'product',
			pos = 'pos', 
			sod_pos = 'sod_pos', 
			ret ='ret',
			value = 'value',
			delta ='delta',
			trade_pnl = 'trade_pnl', 
			day_pnl = 'day_pnl', 
			settled_pnl = 'settled_pnl',
			pnl = 'pnl',
			cum_pnl = 'cum_pnl', 
			tcost = 'tcost',
			trade_qty = 'trade_qty',
			trade_price = 'trade_price',
			turnover = 'turnover', 
			price_change = 'price_change', 
			financing_cost = 'financing_cost',
			slippage_cost = 'slippage_cost',
			settled_price = 'settled_price',
			settled_pos = 'settled_pos',
			bid_ask_spread_ratio = 'bid_ask_spread_ratio')

		self.result = Result(result_id)
		self.result.timestamp = datetime.datetime.now()
		self.result.user = getpass.getuser()
		self.result.sim_params = self._sim_params
		self.result.alg_name = self._alg.name
		self.result.alg_params = self._alg_params

		root = logging.getLogger()
		ch = logging.StreamHandler(sys.stdout)
		ch.setLevel(logging.INFO)
		root.addHandler(ch)

	def prepare_data(self,universe=None, start_date=None, end_date=None, external_datasets = None, symbology='bbgid', data_recipe = None, external_data = None, col_map = None, sod_pos = None, update_cache = None):
		print("Preparing data for backtest")
		update_cache = self._sim_params.update_cache if update_cache is None else update_cache
		start_date = self._start_date if start_date is None else start_date
		end_date = self._end_date if end_date is None else end_date
		universe = self._universe if universe is None else universe
		symbology = self._symbology

		if not isinstance(start_date, datetime.datetime):
			start_date = pd.Timestamp(start_date).to_pydatetime()

		if not isinstance(end_date, datetime.datetime):
			end_date = pd.Timestamp(end_date).to_pydatetime()

		if universe is None:
			raise ValueError("Universe is None")

		datasets={}

		if external_datasets is not None:
			for name in external_datasets:
				datasets[name] = copy.deepcopy(external_datasets[name]) 

		if 'main' not in datasets:
			datasets['main'] = []


		if self._px_data_source =='bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.px')

			self._col_map['market_status'] = 'market_status'
			self._col_map['cur'] = 'crncy'
			self._col_map['lot_size'] = 'lot_size'
			self._col_map['contract_size'] = 'fut_cont_size'
			self._col_map['tick_size'] = 'fut_tick_size'
			self._col_map ['close'] ='px_last'
			self._col_map['close_unadj'] ='px_last_unadj'
			self._col_map['open'] = 'px_open'
			self._col_map['high'] = 'px_high'
			self._col_map['low'] = 'px_low'
			self._col_map['volume'] = 'px_volume'
		if self._sector_data_source = 'bbg':
			main_datasets.append('datasets.bloomberg.bloomberg.gics')
			self._col_map['sector'] = 'gics_sector'
			self._col_map['sector_name'] = 'gics_sector_name'
			self._col_map['industry'] = 'gics_industry'
			self._col_map['industry_name'] = 'gics_industry_name'
		
		if self._vwap_data_srouce == 'trth':
			main_datasets.append('datasets.reuters.trth.vwap')
			self._col_map['vwap'] = 'vwap'

		if self._borrow_cost_data_source =='markit':
			main_datasets.append('datasets.markit.short.markit_short')
			self._col_map['borrow_rate'] = 'saf'
			self._col_map['borrow_rate_score'] = 'vwaf_score_1_day'

		datasets['main'] = main_datasets
		data_post = {'main':[add_tradable, enrich_ndf, partial(add_lot_size, lot_size_col = self._col_map['lot_size']), partial(add_contract_size, contract_size_col = self._col_map['contract_size'])]}

		if self._strategy_type =='intraday':
			bar_datasets = []
			bar_datasets.append('datasets.reuters.trth.bar')
			datasets['bar'] = bar_datasets

		data_loading_kwargs = {}
		if self._sim_params.data_loading_kwargs is not None:
			data_loading_kwargs = self._sim_params.data_loading_kwargs
		input_data = None
		one_day = pd.Timedelta(days=1)
		if self._sim_params.production_mode:
			yesterday = self._local_today - one_day
			if start_date <= yesterday:
				input_data = self._data_loader.load(recipe = data_recipe,datasets= datasets, universe = universe, symbology = symbology, start_date = start_date, end_date= yesterday, use_cache = self._sim_params.use_cache, update_cache = update_cache, post= data_post, **data_loading_kwargs)
				input_data_today =	self._data_loader.load(recipe = data_recipe,datasets= datasets, universe = universe, symbology = symbology, start_date = input_data.meta.end_date +  dateime.timedelta(days=1), end_date= self._local_today, use_cache = False, update_cache = False, post= data_post, consolidate_latest_date = False, **data_loading_kwargs)
				if input_data is not None:
					input_data.append(input_data_today)
				else:
					input_data = input_data_today
			else:
				if start_date <=end_date:
					input_data = self._data_loader.load(recipe = data_recipe,datasets= datasets, universe = universe, symbology = symbology, start_date = start_date, end_date= end_date, use_cache = self._sim_params.use_cache, update_cache = update_cache, post= data_post, **data_loading_kwargs)
				else:

					raise ValueError("start date {} is after end date{}".format(start_date, end_date))
			if input_data is None:
				raise Exception(" no dataset data is loaded")

			if external_data is not None:
				input_data['main'] = input_data['main'].join(external_data)

			max_start = None
			min_end = None
			for name, df in input_data.dfs.items():
				if (len(df.index.name))>1:
					data_start = df.index.levels[0][0].floor(freq='D')
					data_end = df.index.levels[0][-1].floor(freq ='D')
				else:
					data_start = df.index[0].floor(freq='D')
					data_end = df.index[-1].floor(freq='D')
				if data_start != start_date or data_end != end_date:
					logger.warning("{} data's actual start/end doesn't match input. [{}, {}] vs [{}, {}]".format(name, data_start.date(), data_end.date(), start_date.date(), end_date.date()))
				if max_start is None:
					max_start = data_start
				else:
					max_start = max(max_start, data_start)
				if min_end is None:
					min_end = data_end
				else:
					min_end = min(min_end, data_end)
			if start_date is None:
				data_start_date = max_start
			else:
				data_start_date = max(max_start, pd.Timestamp(start_date))
			if end_date is None:
				data_end_date = min_end
			else:
				data_end_date = min(min_end, pd.Timestamp(end_date))

			print("Data common start date is {} and end date is {}".format(data_start_date.date(), data_end_date.date()))

			if not self._sim_params.include_oos_data:
				last_day_timestamp = self._local_today - relativedelta(months=6)
				if data_end_date > last_day_timestamp:
					logger.warning("Data after {} is reserved for out of sample test".format(last_day_timestamp.date()))
					data_end_date = last_day_timestamp
				if data_end_date<=data_start_date:
					raise ValueError('end date {} after oos adj is before start date {}. Please provide another new start date'.format(data_end_date, data_start_date))
				else:
					logger.warning("Include OOS data")
			self.actual_start_date = data_start_date
			self.actual_end_date = data_end_date
			self._input_data = input_data

			main_data = self._input_data.dfs['main']

			if col_map is not None:
				self._col_map.update(col_map)

			rename_map = {v:k for k, v in self._col_map.items()}
			main_data.rename(columns = rename_map, inplace= True)

			if 'fx' not in main_data:
				if 'cur' not in main_data:
					raise ValueError('Cur not in input data')
				dfs=[]
				for cur in main_data['cur'].unique():
					if pd.isnull(cur):
						continue
					fx = pd.DataFrame(index=main_data.index.levels[0])
					if cur == 'USD':
						fx['fx']=1
					else:
						if cur== 'GBp':
							cur_symbol = 'GBP Curncy'
						else:
							cur_symbol = cur + ' Curncy'
						cur_px = main_data.xs(cur_symbol, level =1)['close']
						if cur in ['EUR', 'AUD', 'GBP','GBp']:
							fx['fx'] = 1/cur_px
						else:
							fx['fx'] = cur_px
						if cur =='GBp':
							fx['fx'] * =100
					fx['cur'] = cur
					dfs.append(fx)
				if len(dfs) >0:
					df_fx = pd.concat(dfs)
					df_fx = df_fx.reset_index().sort_values(by=['date', 'cur'])
					main_data = main_data.reset_index()
					main_data = pd.merge_asof(main_data, df_fx, on='date', by ='cur')
					main_data = main_data.set_index(['date', symbology])
				else:
					raise ValueError("fail to add fx column")
		
			main_data['tz'] = main_data[~pd.isull(main_data['coutry_iso'])]['coutry_iso'].map(country_timezone)

			main_data['tcost_rate'] = np.nan
			main_data['long_financing_rate'] = np.nan
			main_data['short_financing_rate'] = np.nan
			main_data['buy_tax_rate'] = np.nan
			main_data['sell_tax_rate'] = np.nan
			print("adding adj price columns")
			fut_data = main_data[main_data['product']=='future']
			if (len(fut_data))>0:
				fut_data_adj = fut_data[['fut_adj']].copy()
				fut_data_adj['cum_adj'] = fut_data_adj.groupby(self._symbology)['fut_adj'].shift(-1)
				fut_data_adj['cum_adj'].fillna(1, inplace = True)
				main_data.loc[main_data['product']=='future', 'cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cum_adj'].apply(lambda x: x[::-1].cumprod()[::-1]) 
				root_symbols = fut_data['root_symbols'].dropna().unique()
				for root in root_symbols:
					latest_contract_size = fut_data.xs(root, level=1)['contract_size'][-1]
					main_data.loc[(slice(None), root), 'contract_size'] = latest_contract_size

			stock_data = main_data[main_data['product']=='stock']

			if (len(stock_data)>0):
				stock_data_adj = stock_data[['cp_adj_px']].copy()
				stock_data_adj['cum_adj_px'] = stock_data_adj.groupby(self._symbology)['cp_adj_px'].shift(-1)
				stock_data_adj['cum_adj_px'].fillna(1, inplace = True)
				main_data.loc[main_data['product']=='stock', 'cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cum_adj_px'].apply(lambda x: x[::-1].cumprod()[::-1]) 

				if 'borrow_rate' in main_data:
					main_data['borrow_rate'] = abs(main_data['borrow_rate']).ffill()
				if 'borrow_rate_cost' in main_data:
					main_data['borrow_rate_score'] = main_data['borrow_rate_score'].ffill()

				from simulation.commission import commission_rates
				from simulation.financing import long_financing_rates,  short_financing_rates
				from simulation.tax import buy_tax_rates, sell_tax_rates

				main_data['tcost_rate'] = stock_data['country_iso'].map(commission_rates)
				main_data['long_financing_rate'] = stock_data['country_iso'].map(long_financing_rates)
				main_data['short_financing_rate'] = stock_data['country_iso'].map(short_financing_rates)
				main_data['buy_tax_rate'] = stock_data['country_iso'].map(buy_tax_rates)
				main_data['sell_tax_rate'] = stock_data['country_iso'].map(sell_tax_rates)
			if 'cum_adj_px' in main_data:
				main_data['cum_adj_px'].fillna(1, inplace = True)
				for col in ['open', 'close', 'low', 'high', 'vwap','twap']:
					if col in main_data:
						main_data[col+'_adj']  = main_data[col] * main_data['cum_adj_px']
						main_data[col+'_adj'].fillna(main_data[col], inplace= True)
						main_data.loc[main_data['product']=='future',col] = main_data[col+'_adj']
			from simulation.financing import future_financing_rates
			if 'future' in main_data['product'].unique():
				main_data.lco[main_data['product']=='future', 'long_financing_rate'] = main_data.loc[main_data['product']== 'future','coutry_iso'].map(future_financing_rates)
				main_data.lco[main_data['product']=='future', 'short_financing_rate'] = main_data.loc[main_data['product']== 'future','long_financing_rate'] 
			main_data['tcost_rate'].fillna(self._sim_params.tcost, inplace= True)
			main_data['long_financing_rate'].fillna(self._sim_params.long_financing_rate, inplace= True)
			main_data['short_financing_rate'].fillna(self._sim_params.short_financing_rate, inplace= True)
			main_data['buy_tax_rate'].fillna(self._sim_params.buy_tax_rate, inplace= True)
			main_data['sell_tax_rate'].fillna(self._sim_params.sell_tax_rate, inplace= True)

			if self._sim_params.borrow_rate_cost is not None:
				main_data['borrow_rate'] = self._sim_params.borrow_cost
			if 'slippage' not in main_data:
				main_data['slippage'] = np.nan
			if is_number (self._sim_params.slippage_cost):
				main_data['slippage'].fillna(self._sim_params.slippage_cost, inplace = True)
			elif isinstance(self._sim_params.slippage_cost, dict):
				for k, v in self._sim_params.slippage_cost.items():
					if k in ['stock', 'future', 'currency', 'index']:
						main_data.loc[main_data['product']==k, 'slippage'] =v
					else:
						main_data.loc[(slice(None), k), 'slippage'] =v
			main_data['slippage'].fillna(0, inplace = True)
			for col in ['tcost_rate', 'long_financing_rate', 'short_financing_rate', 'borrow_rate', 'buy_tax_rate', 'sell_tax_rate', 'slippage']:
				main_data[col]/=10000.0
			if 'adv' in main_data:
				main_data['adv'].ffill(inplace=True)
			self._inst_input = main_data.loc[data_start_date:data_end_date]
			self._inst_input = self._inst_input.reset_index().set_index(['date', self._symbology])
			self._inst_stat = pd.DataFrame(index = self._inst_input.index)
			self._inst_custom = pd.DataFrame(index = self._inst_input.index)
			self._pf_input = pd.DataFrame(index = self._inst_input.levels[0])
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
				self._inst_bar = self._input_data.dfs['bar'].reset_index

				print('Adjust timezone for bar data')
				tz = pytz.timezone (self._sim_params.timezone)
				self._inst_bar['msgstamp'] = self._inst_bar['msgstamp'].dt.tz_localize('UTC').dt.tz_convert# need to check

				self._inst_bar['date'] = self._inst_bar['msgstamp'].dt.date
				self._inst_bar['time'] = self._inst_bar['msgstamp'].dt.time
				self._inst_bar.rename(columns = {'msgstamp':'timestamp'}, inplace=True)
				self._inst_bar['trade_date'] = self._inst_bar['date'].mask(self._inst_bar['time']<datetime.time(7,0), self._inst_bar['date'])#need to check
				self._inst_bar = self._inst_bar.set_index(['timestamp', symbology])
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
					raise ValueError("data for hedge symbol {}  not loaded".format(self._sim_params.hedge_symbol))

				self._hedge_data = self._inst_input.loc[(slice(None), self._sim_params.hedge_symbol),].reset_index(level=1, drop=True)

			self._data_cluster.add_data('instrument_input', self._inst_input)
			self._data_cluster.add_data('portfolio_input', self._pf_input)

			if self._sim_params.strategy_type == 'intraday':
				self._data_cluster.add_data('bar', self._inst_bar, frequency='5m')

			self._input_data.dfs['main'] = main_data
			for name in self._input_data.dfs:
				if name not in ['main','bar']:
					self._data_cluster.add_data(name, self._input_data.dfs[name])
			self._data_cluster.set_main_data('instrument_input')


	@property
	def current_date(self):
		return self._current_date

	@property
	def current_time (self):
		return self._current_time

	def get_current_time(self):
		return self._current_time

	def update_portfolio(self, date):

		pf = self._portfolio
		pf.end_date = date

		if 'expired' in self._current_data:
			settled_pos = {}
			expired_ids = self._current_data[self._current_data['expired']==True].index.unique()
			for i in expired_ids:
				if i in pf.positions
					if not equal_zero(pf.positions[i]):
						settled_pos[i] = pf.positions[i]
						pf.positions[i]= 0
			if (len(settled_pos))>0:
				try:
					self._inst_stat.loc[(date, list(settled_pos.kes())), 'settled_pos'] = list(settled_pos.values())
				except:
					import pdb; pbd.set_trace()

		if self._sim_params.strategy_type !='intraday':
			mi = pd.MultiIndex.from_product([[date], list(pf.positions.keys())], names= self._inst_stat.index.names)
			s = pd.Series(list(pf.positions.values()), index = mi)

			try:
				self._inst_stat.loc[date, 'pos'] = s
			except:
				import pdb; pdb.set_trace()

		else:
			today= self._context.today

			if today not in pf.date_positions:
				pf.date_positions[today] ={}

			if self._context.previous_date is not None:
				previous_date = self._context.previous_date
				if previous_date not in pf.date_positions:
					pf.date_positions[previous_date] ={}

				mi = pd.MultiIndex.from_product([[previous_date], list(pf.date_positions[previous_date].keys())], names= self._inst_stat.index.names)
				s = pd.Series(list(pf.date_positions[previous_date].values()), index = mi)

				self._inst_stat.loc[previous_date, 'pos'] = s

				mi = pd.MultiIndex.from_product([[today], list(pf.date_positions[previous_date].keys())], names= self._inst_stat.index.names)
				s = pd.Series(list(pf.date_positions[previous_date].values()), index = mi)

				self._inst_stat.loc[previous_date, 'sod_pos'] = s
				pf.date_positions[today] = dict(pf.date_positions[previous_date], **pf.date_positions[today])

			mi = pd.MultiIndex.from_product([[today], list(pf.date_positions[today].keys())], names= self._inst_stat.index.names)
			s = pd.Series(list(pf.date_positions[today].values()), index = mi)

			try:
				self._inst_stat.loc[today, 'pos']= s
			except:
				import pdb; pdb.set_trace()

	def generate_performance(self):
		print("generate_performance")
		inst_data = self._inst_input.join(self._inst_stat)
		tr = self._trade_record
		if len(tr)>0:
			tr['date'] = tr['timestamp'].dt.floor(freq= 'D')
			tr = tr.sort_index(by=['timestamp', 'symbol'])
			tr = tr.merge(inst_data['tz'].to_frame(), left_on=['date', 'symbol'], right_index= True, how = 'left')

			tz_list = tr.dropna(subset=['tz'])['tz'].unique()

			for tz in tz_list:
				tr.loc[tr['tz']==tz, 'timestamp_loca']=tr[tr['tz']==tz]['timestamp'].dt.tz_localize(self.sim_params.timezone).dt.tz_convert(tz).dt.tz_localize(None)
			tr['timestamp_localtime'] = tr['timestamp_local'].dt.time

			tr['date'] = tr['timestamp_local'].dt.floor(freq='D')
			tr['date'] = tr['date'].mask(tr['timestamp_localtime']>datetime.time(18,0), tr['timestamp_local'].dt.ceil(freq='D'))

			tr['actual_price'] = np.nan
			if self._sim_params.strategy_type=='intraday':
				inst_bar = self._inst_bar.reset_index()[['timestamp', self._symbology, 'close']]
				inst_bar.rename(columns= {self._symbology:'symbol'}, inplace=True)
				inst_bar = inst_bar.sort_values(by=['timestamp', 'symbol'])

				tr = pd.merge_asof(tr, inst_bar, on= 'timestamp', by='symbol', direction= 'forward')
				tr['actual_price'] = tr['actual_price'].mask(pd.isnull(tr['price']), tr['close'])
				tr.drop(['close'], axis=1, inplace=True)

			else:
				tr = pd.merge(tr, inst_data[self._sim_params.order_price].to_frame(), left_on=['date', 'symbol'], right_index=True, how='left')
				tr['actual_price'] = tr['actual_price'].mask(pd.isnull(tr['price']), tr[self._sim_params.order_price])
				tr.drop(self._sim_params.order_price, axis=1, inplace=True)

			price_cols = []
			for col in ['open', 'close', 'vwap']:
				if col in inst_data:
					price_cols.append(col)

			tr = tr.merge(inst_data[price_cols], left_on=['date','symbol'], right_index= True, how='left')

			for col in price_cols:
				tr['actual_price'] = tr['actual_price'].mask(tr['price']==col, tr[col])

			tr['price'] = tr['actual_price']
			tr['price'] = tr['price'].astype(float64)
			tr.drop(tr.columns.intersection(['actual_price']+price_cols), axis =1 , inplace=True)
			tr = tr.merge(inst_data[['slippage']], left_on=['date', 'symbol'], right_index = True, how = 'left')
			tr['trade_price'] = tr.price.where(tr.qty>0,0)*(1+tr.slippage)+tr.price.where(tr.qty<0,0)*(1-tr.slippage)

			to_merge = inst_data[['close_unadj' if 'close_unadj' in inst_data else 'close', 'sod_pos', 'contract_size', 'fx']].copy()
			to_merge.rename(columns= {'close_unadj':'close'}, inplace= True)

			to_merge.index.names = ['date','symbol']
			to_merge = to_merge.reset_index()
			tr = tr.merge(to_merge, left_on=['date', 'symbol'], right_on=['date','symbol'],how='left')

			tr['slippage'] = ((tr['price'] - tr['trade_price'])*tr['qty']*tr['contract_size']).abs()
			tr['trade_delta'] = tr['trade_price']*tr['qty']*tr['contract_size']
			tr['buy_value'] = (tr['trade_price'] *tr['qty'].where(tr['qty']>0,0)*tr['contract_size']).abs()
			tr['sell_value'] = (tr['trade_price'] *tr['qty'].where(tr['qty']<0,0)*tr['contract_size']).abs()
			tr['trade_value'] = tr['buy_value']+tr['sell_value']
			tr['pnl'] = (tr['close']-tr['trade_value'])*tr['qty']*tr['contract_size']
			tr['volume'] = tr['qty'].abs()
			tr['sod_pos'].fillna(0, inplace=True)
			tr['pos_intraday'] = tr.groupby(['date', 'symbol'])['qty'].cumsum()
			tr['pos'] = tr['pos_intraday']+tr['sod_pos']
			tr['delta'] = tr['pos']*tr['price']*tr['contract_size']
			tr['value'] = tr['delta'].abs()

			for c in ['delta', 'value']:
				tr[c+'_usd'] =tr[c]/tr['fx']

			tr_pos = tr[['timestamp', 'symbol', 'pos', 'delta', 'value', 'delta_usd', 'value_usd', 'date']].groupby(['date', 'timestamp', 'symbol']).max()
			tr_pos_index = tr_pos.reset_index()[['date', 'timestamp', 'symbol']]
			tr_pos_index = tr_pos_index.merge(inst_data.reset_index()[['date', self._symbology]], on='date', how='left')
			tr_pos_index = tr_pos_index.set_index(['date', 'timestamp', self._symbology])
			tr_pos_index = tr_pos_index.sort_index()
			tr_pos = tr_pos.reindex(tr_pos_index.index.drop_duplicates())
			tr_pos = tr_pos.sort_index()
			tr_pos = tr_pos.groupby(level= (0,2)).ffill()
			tr_pos.fillna(0, inpalce = True)
			tr_sum = tr_pos.groupby(level=(0,1))[['delta_usd', 'value_usd']].sum()
			tr_sum = tr_sum.reset_index()
			tr_max = tr_sum.groupby('date').max()
			tr_max['delta_usd_min'] = tr_sum.groupby('date')['delta_usd'].min()
			tr_max['delta_usd'] = tr_max['delta_usd'].mask(tr_max['delta_usd_min'].abs()>tr_max['delta_usd'], tr_max['delta_usd_min'])
			tr_max.drop('delta_usd_min', axis=1, inplace=True)

			tr_daily = tr.groupby(['date', 'symbol'])[['trade_value', 'buy_value', 'sell_value', 'slippage', 'volume', 'qty']].sum()
			tr_daily['pnl'] = tr.groupby(['date', 'symbol'])['pnl'].sum()
			tr_daily.index.names = inst_data.index.names

			inst_data['buy_turnover'] = tr_daily['buy_value']
			inst_data['buy_turnover'].fillna(0.0, inplace = True)
			inst_data['sell_turnover'] = tr_daily['sell_value']
			inst_data['sell_turnover'].fillna(0.0, inplace = True)
			inst_data['turnover'] = tr_daily['trade_value']
			inst_data['turnover'].fillna(0.0, inplace= True)
			inst_data['trade_pnl'] = tr_daily['pnl']
			inst_data['trade_pnl'].fillna(0.0, inplace= True)
			inst_data['slippage_cost'] = tr_daily['slippage']
			inst_data['slippage_cost'].fillna(0.0, inplace= True)
			inst_data['trade_qty'] = tr_daily['qty']
			inst_data['trade_qty'].fillna(0.0, inplace= True)
			inst_data['volume'] = tr_daily['volume']
			inst_data['volume'].fillna(0.0, inplace= True)
			self._trade_record = tr
		else:
			inst_data['buy_turnover'] = 0.0
			inst_data['sell_turnover'] = 0.0
			inst_data['turnover'] = 0.0
			inst_data['trade_pnl'] = 0.0
			inst_data['slippage_cost'] = 0.0
			inst_data['trade_qty'] = 0.0
			inst_data['volume'] = 0.0	

		inst_data['sod_pos'].fillna(0.0, inplace=True)
		inst_data['settled_pos'].fillna(0.0, inplace=True)
		inst_data['pos'].fillna(0.0, inplace=True)
		inst_data['delta'] = inst_data['pos']*inst_data['close']*inst_data['contract_size']
		inst_data['value'] = np.abs(inst_data['delta'])
		inst_data['prev_close'] = inst_data.groupby(level=1)['contract_size'].shift(1)
		inst_data['prev_contract_size'] = inst_data.groupby(level=1)['contract_size'].shift(1)

		if 'cap_adj_px' in inst_data and self._sim_params.stock_total_return:
			inst_data['cap_adj_px'].fillna(1, inplace=True)
			inst_data['prev_close_adj'] = inst_data['prev_close']*inst_data['cp_adj_px']
		else:
			inst_data['prev_close_adj'] = inst_data['prev_close']

		inst_data['price_change'] = inst_data['close']*inst_data['contract_size'] - inst_data['prev_close_adj']*inst_data['contract_size'] 
		inst_data['price_change'].fillna(0, inplace=True)
		inst_data['day_pnl'] = inst_data.price_change*inst_data['sod_pos']

		inst_data['tcost'] = (inst_data['turnover']*inst_data['tcost_rate']).abs()
		inst_data['buy_tax_cost'] = (inst_data['buy_turnover']*inst_data['buy_tax_rate']).abs().fillna(0)
		inst_data['sell_tax_cost'] = (inst_data['sell_turnover']*inst_data['sell_tax_rate']).abs().fillna(0)

		inst_data['tax_cost'] = inst_data['buy_tax_cost'] +inst_data['sell_tax_cost']
		inst_data['long_financing_cost'] = (inst_data['value'].where(inst_data['pos']>0,0)*inst_data['long_financing_rate']).fillna(0)/365.0 
		inst_data['short_financing_cost'] = (inst_data['value'].where(inst_data['pos']<0,0)*inst_data['short_financing_rate']).fillna(0)/365.0
		inst_data['financing_cost'] =inst_data['long_financing_cost']*inst_data['short_financing_cost']
		inst_data['financing_cost'] = inst_data['financing_cost'].groupby(level=1).shift(1)

		inst_data['borrow_cost'] = inst_data['value'].where(inst_data['pos']<0,0)*inst_data['borrow_rate'].fillna(0)/365.0
		inst_data['pnl'] = inst_data.trade_pnl + inst_data.day_pnl - inst_data.tcost - inst_data.financing_cost - inst_data.borrow_cost - inst_data.tax_cost
		inst_data['pnl'] = inst_data.groupby(level=1)['pnl'].fillna(0)


		#add usd field

		for c in ['delta', 'value','pnl','turnover','tcost','financing_cost','slippage_cost', 'borrow_cost']:
			inst_data[c+'_usd'] = inst_data[c]/inst_data['fx']

		total_value = inst_data.groupby(level = 0)['value_usd'].sum()
		total_value = total_value.reindex(index = inst_data.index, level = 0)
		divisor = 1/total_value
		inst_data['weight'] = inst_data['value_usd']*divisor
		if (inst_data.weight>self._sim_params.max_weight).any():
			logger.warn("max weight {} breached".format(self._sim_params.max_weight))

		for c in inst_data:
			if c not in self._inst_input:
				self._inst_stat[c] = inst_data[c]

		start_loc, end_loc = inst_data.index.levels[0].slice_locs(self._start_date, self._end_date)
		index_slice = inst_data.index.levels[0][start_loc:end_loc]
		df = pd.DataFrame(index = index_slice)
		df['long_pnl'] = inst_data.pnl_usd.where(inst_data.pos>0,0).sum(level=0).fillna(0)
		df['short_pnl'] = inst_data.pnl_usd.where(inst_data.pos<0,0).sum(level=0).fillna(0)
		df['pnl'] = inst_data.pnl_usd.sum(level=0).fillna(0)
		df['cum_pnl'] = df['pnl'].cumsum()
		df['cum_long_pnl'] = df['long_pnl'].cumsum()
		df['cum_short_pnl'] = df['short_pnl'].cumsum()

		if len(tr)>0:
			mask = tr_daily.index
			sod_value = ((inst_data['sod_pos']-inst_data['settled_pos'])*inst_data['close']*inst_data['contract_size']/inst_data['fx']).abs().drop(mask, errors='ignore').groupby(level=0).sum().fillna(0)

			sod_value = sod_value.reindex(df.index)
			sod_value.fillna(0.0, inplace=True)

			sod_delta = ((inst_data['sod_pos']-inst_data['settled_pos'])*inst_data['close']*inst_data['contract_size']/inst_data['fx']).drop(mask, errors='ignore').groupby(level=0).sum().fillna(0)
			sod_delta.fillna(0.0, inplace = True)
			tr_max = tr_max.reindex(df.index)
			tr_max.fillna(0.0, inplace = true)
			df['value'] = tr_max['value_usd'] + sod_value
			df['delta'] = tr_max['delta_usd'] + sod_value

		else:
			df['value'] = inst_data.evea("(sod_pos -settled_pos)*close*contract_size/fx").abs().groupby(level=0).sum().fillna(0)
			df['delta'] = inst_data['delta_usd'].sum(level=0)
			if self._portfolio.init_capital is None:
				logging.warn("init capital is not provided use average gross to calcualte return")
				if df['value'].sum()<0.001:
					df['ret'] = 0.0
				else:
					df['ret'] = df['pnl']/df[df['value']>0]['value'].mean()
	
			else:
				df['ret'] = df['pnl']/self._sim_params.init_capital
			
			df['cum_ret'] = df['ret'].cumsum()
			df['turnover'] = inst_data['turnover_usd'].abs().sum(level=0)
			df['high_water'] = df['cum_pnl'].expanding().max()
			df['under_water'] =df['pnl'] -df['high_water']
			df['tcost'] = inst_data['tcost_usd'].abs().sum(level=0)
			df['tax_cost'] = inst_data['tax_cost_usd'].abs().sum(level=0)
			df['borrow_cost']=inst_data['borrow_cost_usd'].abs().sum(level=0)
			df['financing_cost'] = inst_data['financing_cost_usd'].sum(level=0)
			df['slippage']=inst_data['slippage_cost_usd'].abs().sum(level=0)
			if self._hedging:
				self._hedge_data['ret'] = self._hedge_data['close'].pct_change().shift(-1)
				df['hedge_pnl'] = -df['delta']*self._hedge_data['ret']
				df['cum_hedge_pnl'] = df['hedge_pnl'].cumsum()
				df['cum_total_pnl'] = df['cum_pnl']+df['cum_hedge_pnl']

			self._portfolio.daily_statistics = df

			start_year = int(self._start_date.year)
			end_year = int(self._end_date.year)

			for i in range(start_year, end_year+1):
				year_start = max(self._start_date, pd.Timestamp(i,1,1))
				year_end = min(self._end_date, pd.Timestamp(i,12,31))
				df_slice = df.loc[year_start:year_end]
				s = self.update_stats(df_slice)

				if s is None:
					continue
				for k in list(s.keys()):
					if k not in self._summary:
						self._summary[k] = np.nan
				self._summary.loc[i] = pd.Series(s)


			s = self.update_stats(df)

			for k in list(s.keys()):
				if k not in self._portfolio.summary:
					self._portfolio.summary[k] = np.nan
			self._portfolio.summary.loc['All'] = pd.Series(s)

			for c in self._portfolio.daily_statistics:
				self._pf_stat[c] = self._portfolio.daily_statistics

	def update_stats(self, df)			:
		columns = ['pnl', 'returns', 'volatility_daily', 'volatility', 'pnl_std', 'sharpe','total_turnover', 'bps','value', 'turnover', 'skew', 'kurtosis','slippage','tcost', 'financing_cost', 'borrow_cost', 'tax_cost','max_drawdown', 'max_underwater_duration', 'max_dd_duration', 'calmar', 'linearity']
		s = dotdict({})
		for col in columns:
			s[col] = np.nan
		# drop the date where value is zero or not turnover
		df = df.fillna(0)
		df = df[(df['value']>0|df['turnover']>0|df['pnl']!=0)]
		if len(df)==0:
			return s

		s.pnl = df['pnl'].sum()
		s.value = df['value'].mean()
		s.returns = s.pnl/s.value
		ret = df['pnl']/s.value
		s.volatility_daily = ret.std()
		s.volatility = ret.std()*15.874
		if equal_zero(s.volatility):
			s.sharpe = np.nan
		s.pnl_std = df['pnl'].std()
		s.sharpe = np.nan if equal_zero(s.pnl_std) else df['pnl'].mean()/s.pnl_std*15.874
		s.total_turnover = df['turnover'].sum()
		s.bps = np.nan if equal_zero(s.total_turnover) else s.pnl/s.total_turnover*10000
		s.value = df['value'].mean()

		s.turnover = np.nan if equal_zero(s.value) else df['turnover'].mean()/s.value
		s.skew = df['pnl'].skew()
		s.kurtosis = df['pnl'].kurt()
		s.slippage = df['slippage'].sum()
		s.tcost = df['tcost'].sum()
		s.financing_cost = df['financing_cost'].sum()
		s.borrow_cost = df['borrow_cost'].sum()
		s.tax_cost = df['tax_cost'].sum()
		if 'hedge_pnl' in df:
			s.hedge_pnl = df['hedge_pnl'].sum()
			s.total_pnl = s.pnl +s.hedge_pnl

		cum_pnl = df['pnl'].cumsum()
		high_water= cum_pnl.expanding().max()
		high_water = high_water.fillna(method= 'bfill')
		i = np.argmax(high_water - cumpnl)
		j = np.argmax(high_water[:i])
		days_since_high_water = high_water.expanding().apply(lambda x : len(x)-np.argmax(np.ma.masked_invalid(x)))
		if np.isnan(np.max(days_since_high_water)):
			s.max_underwater_duration = np.nan
		else:
			s.max_underwater_duration = int(np.max(days_since_high_water))

		s.max_drawdown = np.nan if equal_zero(s.value) else (cum_pnl - high_water).min()/s.value
		if (not isinstance (i, pd.Timestamp)) or (not isinstance(j, pd.Timestamp)):
			s.max_dd_duration = np.nan
		else:
			s.max_dd_duration = (i-j).days
		s.calmar = (ret.mean()*252)/(-s.max_drawdown)

		#pnl consistency
		cum_pnl = df['pnl'].cumsum()
		linear_pnl = pd.Series(np.linspace(0, s.pnl, len(df)), index = df.index)
		mse = math.sqrt(((cum_pnl- linear_pnl)**2).mean())
		s.linearity = np.nan if equal_zero(mse) else s.pnl/mse

		return s

	def order(self, symbol, qty, price =None, type= None):
		if qty==0:
			logging.warn("0 qty for order {} {} {}".format(symbol, price, type))
			return False

		order = Order(id=self.generate_order_id(), symbol= symbol, qty=qty, price=price, timestamp= self.current_time, type=type)
		self._order_book.add_order(order)
		return self._simulator.order(order)

	def order_value(self, symbol, value, price=None):
		qty= self._calculate_order_qty(symbol, value, price)
		if qty==0:
			logging.warn("0 qty for order {} {} {}".format(symbol, price, type))
			return False
		return self.order(symbol, qty, price)			

	def order_target(self, symbol, target, price=None):
		if symbol in self._portfolio.positions:
			qty = target - self._portfolio.positions[symbol]
			if qty!=0:
				return self.order(symbol, qty, price)
			else:
				return True
		else:
			if target!=0:
				return self.order(symbol, target,price)
			else return True

	def order_target_value(self, symbol, target_value, price = None):
		qty = self._calculate_order_qty(symbol, target_value, price)
		return self.order_target(symbol, qty, price)

	def cancel_order(self, id):
		pass

	def _calculate_order_qty(self, symbol, value, price = None):
		product = self._current_data.loc[symbol, 'product']
		if product =='currency':
			return value*self._scale_factor

		if isinstance(price, str):
			if symbol in self._current_data.index:
				price = self._current_data.loc[symbol, price]
			else:
				logging.warn("price not avaialbe {}".format(symbol))
				return 0

		elif price is None:
			if self._sim_params.strategy_type == 'intraday':
				if symbol in self._current_bar_data.index:
					price = self._current_bar_data.loc[symbol, 'close']
				else:
					logging.warn("Price not avaialbe {}".format(symbol))
					return 0

			else:
				if symbol in self._current_data.index:
					price = self._current_data.loc[symbol, self._sim_params.order_price]
				else:
					logging.warn("price not avaialbe {}".format(symbol))

		if pd.isnull(price):
			logging.warn("price not avaialbe {}".format(symbol))
			return 0

		qty = value *self._scale_factor/price_cols
		if product = 'stock':
			qty= self.round_to_lot(symbol,qty)

		elif product =='future':
			qty = int(math.floor(qty/self._current_data.loc[symbol, 'contract_size']+0.5))
		return qty

	def round_to_lot(self, symbol, qty):
		if symbol in self._current_data.index:
			lot = self._current_data.loc[symbol, 'lot_size']
			return int(qty/lot+0.5)*lot


	def get_alg_params(self):
		return self._alg_params

	@staticmethod
	def display_summary(result):
		if isinstance(result, dict):
			statistics = pd.DataFrame()
			for i, j in result.items():
				statistics = statistics.append(j.statistics.loc['All'])
			statistics.index = list(result.keys())

			plot_nice_table(statistics, 'portfolio stat summary')
		else:
			plot_nice_table(result.statistics, 'portfolio stat summary')


	@property
	def sim_params(self):
		return self._sim_params

	@property
	def alg(self):
		return self._alg

	def is_traadabel(self, sym):
		return sym in self._current_date.index and self._current_date.loc[sym, 'tradable']

	def load_hsitorical_result(self, id = None, path = None, cutoff_date = None):
		one_day = pd.Timedelta(days=1)
		from .api import load_result
		print("loading historical result {} {} {} ".format(id, path, cutoff_date))
		self._hist_result = load_result(id=id, path = path)

		if cutoff_date is not None:
			self.hist_last_day = pd.Timestamp(cutoff_date)
		else:
			self.hist_last_day = self._hist_result.portfolio_data.index[-1]

		if self._sim_params.production_mode:
			yesterday = self._local_today - one_day
			self.hist_last_day = self._hist_result.portfolio_data.index[self._hist_result.portfolio_data.index <= yesterday][-1]

		print("use historical result from {} to {}".format(self._hist_result.portfolio_data.index[0], self.hist_last_day))
		self.actual_start_date = max(self.hist_last_day+one_day, self.actual_start_date)

	def init_alg(self):
		print("Init algorithm")
		self._alg.init(self._context)

	def generate_pipelines(self):
		print('Generating pipelines')
		pipeline_results = {}

		if self._sim_params.load_pipelines and self._sim_params.load_pipelines is not None:
			if self._sim_params.load_pipelines_path is None:
				pipeline_path = os.path.join(self.result.path, 'pipeline')

			else:
				pipeline_path = os.path.join(self.sim_params.load_pipelines_path, 'pipeline')

			pipeline_results = load_pipelines(pipelines_path, pipeline_names = 'None' if self._sim_params.load_pipelines is True else self._sim_params.load_pipelines)

			pipeline_to_run = []

			for p in self._alg._pipeline_names:
				if p not in pipeline_results:
					pipeline_to_run.append(p)

			if len(pipeline_to_run) >0:
				if self._sim_params.use_historical_result:
					pipeline_results.update(self.run_pipelines(names=pipeline_to_run), from_date = self.actual_start_date, hist_result = self._hist_result.pipelines) 

				else:
					pipeline_results.update(self.run_pipelines(names= pipeline_to_run))

		else:
			if self._hist_result is not None:
				pipeline_results = self.run_pipelines(from_date = self.actual_start_date, hist_result = self._hist_result.pipelines)
			else:
				pipeline_results = self.run_pipelines()

		if self._hist_result is not None:
			for p, dfs in pipeline_results.items():
				if isinstance(dfs, dict):
					for n in dfs:
						dfs[n] = dfs[n][self.actual_start_date].append(self._hist_result.pipelines[p][n][self._start_date:self.hist_last_day])
						dfs[n].sort_index(inplace=True)

				elif isinstance(dfs, pd.DataFrame) or isinstance(dfs, pd.Series):
					pipeline_results[p] = pipeline_results[p][self.actual_start_date:].append(self._hist_result.pipelines[p][self._start_date:self.hist_last_day])
					pipeline_results[p].sort_index(inplace= True)

		self._pipeline_results = pipeline_results
		if self._sim_params.save_pipelines:
			if not os.path.isdir(self.result.path):
				os.makedirs(self.result.path)

			save_pipelines(os.path.join(self.result.path, 'pipeline'), pipeline_results)

		return self._pipeline_results






			pipelines = None
			if (isinstance(self._sim_params.load_pipelines, str)):
				pipelines = [self._sim_params.load_pipelines]
			elif hasattr(self._sim_params.load_pipelines,'__iter__'):
				pipelines = self._sim_params.load_pipelines
			self._pipeline_results = self._strategy.load_pipelines(self._sim_params.load_pipelines_path, pipelines= pipeline)
			self._pipeline_results = self._strategy.run_pipelines()
		else:
			if self._hist_result is not None:
				pipeline_results = self.__strategy.run_pipelines(from_date = self.actual_start_date, hist_result= self._hist_result.piplines)
			else:
				pipeline_results = self._strategy.run_pipelines()
		if self._hist_result is not None:
			for p, dfs in pipeline_results.items():
				if isinstance(dfs, dict):
					for n in dfs:
						dfs[n] = dfs[n][self.actual_start_date:].append(self._hist_result.pipelines[p][n][self._start_date:self.hist_last_day])
						dfs[n].sort_index(inplace = True)
				elif isinstance(dfs, pd.DataFrame) or isinstance(dfs, pd.Series):
						pipeline_results[p] = pipeline_results[p][self.actual_start_date:].append(self._hist_result.pipelines[p][self._start_date:self.hist_last_day])
						pipeline_results[p].sort_index(inplace=True)
		return self._pipeline_results

	def run_pipelines(self, names = None, frome_date = None, hist_result = None):
		result_dict = {}
		if len(self._alg._pipeline_names) == 0:
			return result_dict

		if names is None:
			names = self._alg._pipeline_names

		if from_date is not None:
			print("rnning pipeline from {}".format(from_date))

		else:
			print("running pipeline for the whole data")

		pipeline_input = {}

		for name in self._input_data.dfs:
			pipeline_input[name] = self._input_data.dfs[name]

		for k in names:
			print("running pipeline {}".format(k))

			v = self._alg._pipelines[k]
			if self._sim_params.disable_lookforward_bias_check:
				logging.warn("lookforward bias check disabled!!")
				if hist_result is not None and from_date is not None:
					r = v[0](pipeline_input, *v[1], from_date = from_date, hist_result = hist_result[k], **v[2])
				else:
					r = v[0](pipeline_input, *v[1], **v[2])

				if isinstance(r, pd.DataFrame) or isinstance(r, pd.Series):
					result_dict[k] = r
					if hist_result is not None and from_date is not None:
						pipeline_input[k] = hist_result[k].append(r)
					else:
						pipeline_input[k] = r

				elif isinstance(r, dict):
					result_dict[k] ={}
					pipeline_input[k] ={}
					for c, s in r.items():
						if isinstance(s, pd.Series) or isinstance(s, pd.DataFrame):
							result_dict[k][c] = s
							if hist_result is not None and from_date is not None:
								pipeline_input[k][c] = hist_result[k][c].append(s)

							else:
								pipeline_input[k][c] = s

						else:
							raise ValueError("Data in result dict must be dataframe or series")

				else:
					raise ValueError("result returned from pipeline must be dic or dataframe or sereise")

			else:
				h1 = int(len(self._inst_input.index.levels[0])/2.0)
				cut_date = self._inst_input.index.levels[0][h1]

				data_slice = self._inst_input.loc[:cut_date, slice(None)].copy()
				r = v[0](self._context, self._inst_input.copy(), *v[1], **v[2])
				r_h = v[0](self._context, data_slice, *v[1], **v[2])

				for (c,s), (c_h, s_h) in zip(iter(r.items()), iter(r_h.items())):
					if c!= c_h:
						raise ValueError("Potential lookforward bias detected. difference columns returned from pipeline and verficiate [{}] [{}]".format(c, c_h)) 

					if c in self._inst_input:
						raise ValueError('columns [{}] already exists in the data'.format(c) )

					full_result = s.xs(cut_date, level=0).rename(c).fillna(0)
					half_result = s_h.xs(cut_date, level=0).rename(c).fillna(0)
					if not np.isclose(full_result, half_result, atol= self._sim_params.atol, rtol = self._sim_params.rtol, equal_nan=True).all(): 
						print("full result:")
						print(full_result)
						print("half results:")
						print(half_result)

						diff = full_result.to_frame().merge(half_result.to_frame(), left_index= True, right_index=True)
						diff['diff'] = diff[c+'_x'] -diff[c+_'y']
						diff['result'] = np.isclose(full_result, half_result, atol = self._sim_params.atol, rtol = self._sim_params.rtol, equal_nan= True) 

						with pd.option_context('display.max_rows', 1000000):
							print(diff[~diff['result']])

						raise ValueError("Potential lookforward bias detected for column[{}]".format(c))

					if len(s.index.difference(self._inst_input.index))>0:
						raise ValueError("index on pipeline column{} doesnt match the origianl data".format(c))

					print("Add column [{}] to data".format(c))
					self._inst_input[c] = s

		return result_dict

	def fill_result(self, result):
		result._input_meta_data = self._input_data.meta
		result._inst_input = self._inst_input
		result._pf_input = self._pf_input
		result._inst_stat = self._inst_stat
		result._pf_stat = self._pf_stat
		result._inst_custom = self._inst_custom
		result._pf_custom = self._pf_custom
		result._inst_bar = self._inst_bar
		result._col_map = self._col_map

		result._statistics = self._portfolio.summary
		result._pipeline = self._pipeline_results
		result.merge_instrument_data()
		result.merge_portfolio_data()
		if len(self._order_record)>0:
			result._order_record = self._order_record.set_index(['timestamp','symbol']).sort_index()
		else:
			result._order_record = None
		if len(self._trade_record) >0:
			result._trade_record = self._trade_record.set_index(['timestamp','symbol']).sort_index()
		else:
			result._trade_record = None

	def handle_data(self):
		print('Handle data')

		for p, dfs in self._pipeline_results.items():
			if isinstance(dfs, pd.Series) or isinstance(dfs, pd.DataFrame):
				self._data_cluster.add_data(p, dfs)
			elif isinstance(dfs, dict):
				for c, s in dfs.items():
					self._data_cluster.add_data(c,s)

		dates_locs = self._inst_input.index.levels[0].slice_locs(start= self.actual_start_date)
		dates = self._inst_input.index.levels[0][dates_locs[0]:]

		if dates_locs[0] >0:
			previous_date = self._inst_input.index.levels[0][dates_locs[0]-1]
		else:
			previous_date = None

		if self._hist_result is not None:
			self._inst_stat = self._inst_stat[self.actual_start_date:].append(self._hist_result.instrument_stat[self._start_date:self.hist_last_day])
			self._inst_stat.sort_index(inplace=True)
			self._inst_custom = self._inst_custom[self.actual_start_date:].append(self._hist_result.instrument_custom[self._start_date:self.hist_last_day])
			self._inst_custom.sort_index(inplace= True)

			self._pf_stat = self._pf_stat[self.actual_start_date:].append(self._hist_result.portfolo_stat[self._start_date:self.hist_last_day]) 
			self._pf_stat.sort_index(inplace=True)
			self._pf_custom = self._pf_custom[self.actual_start_date:].append(self._hist_result.portfolio_custom[self._start_date:self.hist_last_day]) 
			self._pf_custom.sort_index(inplace= True)
			pos_dict = self._inst_stat.loc[self.hist_last_day, 'pos'].to_dict()
			self._portfolio.positions.update(pos_dict)
		self._data_cluster.add_data('instrument_stat', self._inst_stat)
		self._data_cluster.add_data('instrument_custom', self._inst_custom)
		self._data_cluster.add_data('portfolio_custom', self._pf_custom)
		self._data_cluster.add_data('portfolio_stat', self._pf_stat)

		if self._sim_params.production_mode:
			if self._local_today != dates[-1]:
				raise ValueError("Today {} is not loaded in the data".format(self._local_today))
			dates = [dates[-1]]
			if self._sod_pos is not None:
				self._portfolio.positions = {}
				for k in self._sod_pos.index:
					if (self._local_today, k) in self._inst_stat.index:
						self._portfolio.positions[k] = self._sod_pos[k]


		if self._inst_bar is not None:
			self._inst_bar = self._inst_bar.reset_index().set_index(['trade_date', 'timestamp', self._symbology])
			self._inst_bar = self._inst_bar.sort_index()

		self._context.today = None
		self._context.previous_date = previous_date
		self._dates = dates
		
		from utils.progress_bar import log_progress
		new_year = None
		self._current_order_id = 0

		for date in log_progress (self._dates, every=1, item_info_func= lambda x:'Date: '+str(x.date())):
			if date > self._end_date:
				break
			if new_year!= date.year:
				new_year = date.year
				print("Year", new_year)

			r = self.handle_per_day(date)
			if r== False:
				print('Exit')
				break

			self._context.previous_date = date		

	def handle_per_day(self, date):
		self._current_date = date
		self._current_time = date
		self._current_data = self._inst_input.ix[date]
		self._simulator.reset()
		self._strategy._order_book.reset()
		self._strategy._trade_book.reset()
		self._simulator._date = date
		self._simulator._ref_date = self._current_data
		self._context.today = date

		pf = self._portfolio

		if 'cp_adj_pos' in self._current_data:
			df_adj = self._current_data.dropna(subset=['cp_adj_pos'])[['cp_adj_pos']].reset_index()
			if len(df_adj)>0:
				print("adj positions for {}".format(','.join(df_adj[self._symbology].unique())))
				df_adj['pos'] = df_adj[self._symbology].map(pf.positions)
				df_adj = df_adj.dropna(subset=['pos'])
				if len(df_adj)>0:
					df_adj['pos_adj'] = df_adj['pos']/df_adj['cp_adj_pos']
					df_adj = df_adj.set_index(self._symbology)
					pos_adj = df_adj['pos_adj'].to_dict()
					pf.positions.update(pos_adj)

		if self._sim_params.strategy_type == 'intraday':
			if self._context.previous_date is not None:
				mi = pd.MultiIndex.from_product([[self._context.previous_date], list(pf.date_positions[self._context.previous_date].keys())], names= self._inst_stat.index.names) 
				s = pd.Series(list (pf.date_positions[self._context.previous_date].keys()), index = mi)
				self._inst_stat.loc[date, 'sod_pos'] = s
			else:
				self._inst_stat.loc[date, 'sod_pos'] = 0

		else:
			mi = pd.MultiIndex.from_product([[date], list(pf.positions.keys())], names = self._inst_stat.index.names)
			s = pd.Series(list(pf.positions.values()), index = mi)
			self._inst_stat.loc[date, 'sod_pos'] =s

		r = True

		if self._alg.before_trading_start(self._context, self._data_cluster)!=False:
			self._sched.reset()
			def func(self, task, *args, **kwargs):
				return task(self._context, self._data_cluster, *args,**kwargs)

			for name, taks in self._alg.tasks.items():
				rule = task[0]
				if rule <pd.Timestamp(self._sim_params.day_cutoff_time).time():
					cal_date = (date + pd.Timedelta(days=1)).date()
				else:
					cal_date = date.date()

				self._sched.add_task(name, pd.Timestamp(datetime.datetime.combine(cal_date, task[0])), partial(func, self, task[1]), args=task[2], kwargs=task[3])

			if self._sim_params.strategy_type =='daily':
				self._sim_params._px_data = self._current_data
				r = self._alg.handle_data(self._context, self._data_cluster)

			elif self._sim_params.strategy_type == 'intraday':

				df_bar_today = self._inst_bar.loc[date]
				if self._alg.has_handle_data(self._context, self._data_cluster)
					date_open_time = date +pd.Timedelta(self._sim_params.open_time)
					date_close_time = date +pd.Timedelta(self._sim_params.close_time)
					df_bar_today = df_bar_today[date_open_time:date_close_time]

					for time, bar in df_bar_today.groupby(level=0):
						self._current_bar = bar_last.loc[time]
						self._simulator._px_data = self._current_bar_data
						self._context.now = time
						self._current_time = time
						self._sched.run()
						r = self._alg.handle_data()
						if r == False:
							break

					else:
						while True:
							next_task= self._sched.next_task()
							if next_task is not None:
								time = next_task[0]
								name = next_task[1]
								logger.debug("trigger task (s) @ {}".format(time))
								self._current_time = time
								self._current.now = time

								if time in df_bar_last_today.index:
									self._current_bar_data = df_bar_today.loc[time]
									self._simulator._px_data = self._current_bar_data

								else:
									logger.error("can not find time {} in bar data today".format(time))
									self._sched.remove_task(name)
								self._sched.run()
							else:
								break


				else:
					raise ValueError("unhandled strategy_type")

				self._alg.after_trading_end(self._context, self._data_cluster)						
				self.dump_order_record()
				self.dump_trade_record()

			self.update_portfolio(date)
			return r

	def generate_order_id(self):
		self._current_order_id +=1
		return self._current_order_id

	def dump_order_record(self):
		self._order_record = self._order_record.append(self.order_book.to_dateframe())

	def dump_trade_record(self):
		self._trade_record = self._trade_record.append(self.trade_book.to_dateframe())

	def on_trade(self, trade):
		if self._trade_book.add_trade(trade):
			order = self._order_book.find_order(trade.order_id)
			if order is None:
				raise RuntimeError("trade's order id [{}] not found in order book".format(trade.order_id))
		else:
			raise RuntimeError('fail to add trade [{}] to trade book'.format(trade.id))

		if not order.add_trade(trade):
			raise RuntimeError("fail to add trade [{}] to order".format(trade.id))

		if trade.symbol not in self._portfolio.positions:
			self._portfolio.positions[trade.symbol] = trade.qty
		else:
			self._portfolio.positions[trade.symbol]+=trade.qty

		if self._sim_params.trategy_type == 'intraday':
			exch_time = trade.timestamp.tz_localize(self._sim_params.timezone).tz_convert(self._current_data.loc[trade.symbol,'tz']).tz_localize(None)
			if exch_time.time <datetime.time(18,0):
				date = exch_time.floor(freq='D')
			else:
				date = exch_time.ceil (freq='D')


			self._portfolio.date_positions.setdefault(date, {})[trade.symbol] = self._portfolio.positions[trade.symbol]
	def save_result(self):
		self.fill_result(self.result)
		self.result.save()

	def close_all_positions(self):
		for c, v in self._portfolio.positions.items():
			if not equal_zero(v):
				self.order(c, -v, type='market')


def run_alg(sim_params = None, alg= None, universe= None, start_date = None, end_date= None, external_data= None, external_datasets= None, symbology='bbgid', col_map = None, alg_params = None, sod_pos= None,  load_data_only = False, result_id = None, data_recipe= None, historical_result = None):
	bt = Backtest(sim_params = sim_params, alg= alg, universe= universe, start_date = start_date, end_date= end_date, external_data= external_data, external_datasets= external_datasets, symbology=symbology, col_map = col_map, alg_params = alg_params, sod_pos= sod_pos, result_id = result_id, data_recipe= data_recipe)
	bt.prepare_data(universe= universe, start_date= start_date, end_date= end_date, external_datasets= external_datasets, symbology= symbology, data_recipe=data_recipe, external_data= external_data, col_map = col_map, sod_pos= sod_pos)
	if load_data_only:
		bt.save_result()
		return bt.result_id

	if historical_result is not None:
		bt.load_hsitorical_result(id= historical_result.get('id', None), path = historical_result.get('path', None), cutoff_date = historical_result.get('cutoff_date', None))

	bt.init_alg()
	bt.generate_pipelines()
	bt.handle_data()
	bt.generate_performance()
	bt.save_result()
	return bt.result()


def run_alphas(sim_params = None, alg= None, universe= None, start_date = None, end_date= None, external_data= None, external_datasets= None, symbology='bbgid', col_map = None, alg_params = None,  result_id = None, data_recipe= None):
	bt = Backtest(sim_params = sim_params, alg= alg, universe= universe, start_date = start_date, end_date= end_date, external_data= external_data, external_datasets= external_datasets, symbology=symbology, col_map = col_map, result_id = result_id, data_recipe= data_recipe)
	bt.prepare_data(universe= universe, start_date= start_date, end_date= end_date, external_datasets= external_datasets, symbology= symbology, data_recipe=data_recipe, external_data= external_data, col_map = col_map)
	bt.init_alg()
	bt.generate_pipelines()
	bt.handle_data()
	bt.generate_performance()
	bt.save_result()
	return bt.result()

