from utils.dotdict import dotdict, to_dotdict
from utils.epsilon import equal_zero
from utils.number import is_number
from utils.scheduler import Scheduler

from backtester.simulator import Simulator
from backtester.result import Result
from backtester.tz import country_timezone

from backtester.data_post import add_lot_size, add_contract_size

from strategy.strategy_impl import StrategyImpl
from strategy.universe import get_universe
from strategy.data_cluster import DataCluster
from strategy.pipeline import load_pipelines, save_pipelines

from strategy.order import Order
from strategy.currency import Currency
from strategy.stock import Stock
from strategy.future import Future
from strategy.index import Index
from strategy.sec_types import SECURITY_TYPE_NDF, SECURITY_TYPE_NDIRS, SECURITY_TYPE_DF, SECURITY_TYPE_CD

from preprocessing.misc import add_tradable
from preprocessing.holiday import remove_holidays

from operators.common import sma

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

from loader.data_loader import DataLoader
from dateutil.relativedelta import relativedelta
from pandas.tseries.offsets import BDay

logger = logging.getLogger('backtester')

sim_params_default = {
	'order_price':'close',
	'slippage_cost': 0,
	'tcost':0,
	'long_financing_cost':0,
	'short_financing_cost':0,
	'buy_tax_cost':0,
	'sell_tax_cost':0,
	'enable_tax_cost':True,
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
	'fill_mode': 'full',
	'fill_ratio':1,
	'timezone':'Asia/Hong Kong',
	'open_time':"09:00:00",
	'close_time':"16:00:00",
	'day_cutoff_time':"07:00:00",
	'night_cutoff_time':"18:00:00",
	'stock_total_return':True,
	'handle_data':False,
	'bar_fill_price': 'close',
	'max_exec':0.05,
	'load_borrow_rate':False,
	'holiday_countries':None,
	"exclude_cur_from_portfolio_size":False
}

class Backtester(StrategyImpl):
	def __init__(self, strategy, sim_params=sim_params_default, start_date = None, end_date=None, result_id= None):
		logger.info("Initializing backtest")
		self._strategy= strategy
		self._universe = get_universe()
		self._universe_dict = strategy.universe_dict
		self._symbology = self._strategy.symbology
		self._sched = Scheduler(self.get_current_time, time_type= "pandas_time")
		self._sim_params = dotdict(sim_params_default)
		if sim_params is not None:
			self._sim_params.update(sim_params)
		if not isinstance(start_date, datetime.datetime):
			self._start_date = pd.Timestamp(start_date).to_pydatetime()
		self._current_date = None
		self._current_date = pd.Timestamp.now(tz=self._sim_params.timezone).replace(tzinfo=None)

		if end_date is None:
			self._end_date = (self._current_time - BDay(1)).to_pydatetime()
		self._simulator = Simulator(self)
		self._simulator.set_fill_mode(self._sim_params.fill_mode, self._sim_params.fill_ratio)
		self._scale_factor = 1
		self._inst_input = None
		self._pf_input = None
		self._inst_stat = None
		self._pf_stat = None

		self._inst_custom = None
		self._pf_custom = None

		self._inst_bar = None
		self._intraday = self.__strategy.intraday
		self._hist_result = None
		self._pipeline_results = None
		if self._sim_params.hedge_symbol is not None:
			self._hedging = True
		else:
			self._hedging = False
		self._order_record = pd.DataFrame()
		self._trade_record = pd.DataFrame()

		self._summary = pd.DataFrame()
		self._eod_pos = None

		self.result = Result(result_id)
		self.result.timestamp = datetime.datetime.utcnow()
		self.result.user = getpass.getuser()
		print(self.result.id, self.result.timestamp, self.result.user)

		self.result.sim_params = self._sim_params
		self.result.alg_name = self._strategy.name
		self.result.alg_params = self._strategy._alg_params

		self._log_path = self.result.path
		if not os.path.exists(self._log_path):
			os.makedirs(self._log_path)

		self._log_file = os.path.join(self._log_path,'log.txt')
		print('log file path: {}'.format(self._log_file))
		logging.shutdown()
		for handler in logging.root.handlers:
			logging.root.removeHandler(handler)
		logging.basicConfig(level = logging.INFO, filename = self._log_file, filemode ='w', format = '%(asctime)s %(name)s %(levelname)s: %(message)s')
		self._strategy.set_impl(self)

	def __exit__(self, type, value, tb):
		logger.shutdown()
		for handler in logging.root.handlers:
			logging.root.removeHandler(handler)
	def is_live(self) -> bool:
		return False
	def prepare_data(self,universe=None, start_date=None, end_date=None, symbology='bbgid', data_recipe = None, update_cache = None):
		logger.info("Preparing data for backtest")
		update_cache = self._sim_params.update_cache if update_cache is None else update_cache
		start_date = self._start_date if start_date is None else start_date
		end_date = self._end_date if end_date is None else end_date
		universe = self._universe if universe is None else universe
		symbology = self._symbology
		if not isinstance(start_date, datetime.datetime):
			start_date = pd.Timestamp(start_date).to_pydatetime()
		if universe is None:
			raise ValueError("Universe is None")

		datasets={}
		datasets['main'] = ['dataset.price.px']
		if 'stocks' in universe:
			datasets['main'].append('dataset.gics.gics')
		if 'futures' in universe or 'stock' in universe:
			datasets['main'].append('dataset.vwap.vwap')
		if self._sim_params.load_borrow_rate:
			datasets['main'].append('dataset.short.short')

		data_post = {'main':[add_tradable, partial(add_lot_size, lot_size_col = 'lot_size'), partial(add_contract_size, contract_size_col='contract_size')]}
		if self._intraday:
			bar_datasets = []
			if 'futures' in universe or 'stocks' in universe:
				bar_datasets.append('datasets.bar.bar')
				datasets['bar']= bar_datasets

		data_loading_kwargs= {}
		if self._sim_params.data_loading_kwargs is not None:
			data_loading_kwargs = self._sim_params.data_loading_kwargs
		input_data = None

		data_loader = DataLoader()
		if start_date <= end_date:
			input_data = data_loader.load(recipe= data_recipe, datasets = datasets, universe= universe, symbology = symbology, start_date = start_date, end_date=end_date, use_cache = self._sim_params.use_cache, update_cache= update_cache, post = data_post, **data_loading_kwargs)
		else:
			raise ValueError("Start date {} is after end date {}".format(start_date, end_date))
		if input_data is None:
			raise Exception('No dataset data is loaded')

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

		logger.info("Data common start date is {} and end date is {}".format(data_start_date.date(), data_end_date.date()))
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

			if self._sim_params.holiday_countries is not None:
				logger.info('Removing holiday [{}] from man data'.format(','.join(self._sim_params.holiday_countries)))
				main_data = remove_holidays(main_data, countries=self._sim_params.holiday_countries)
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
					fx['fx'].ffill(inplace = True)
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
			if 'volume' in main_data:
				main_data['turnover'] = main_data['close']*main_data['volume']*main_data['contract_size']/main_data['fx']
				main_data['adv_30'] = sma(main_data['turnover'],30,30)
				if 'adv' in main_data:
					main_data['adv'].fillna(main_data['adv_30'])
					main_data.drop('adv_30', axis=1, inplace=True)
				else:
					main_data.rename(columns= {'adv_30':'adv'}, inplace=True)
				main_data['adv'] = main_data['adv'].groupby(level=1).bfill()
			main_data['tz'] = main_data[~pd.isull(main_data['coutry_iso'])]['coutry_iso'].map(country_timezone)
			main_data['tz'] = main_data.groupby(level=1)['tz'].ffill()

			main_data['tcost_rate'] = np.nan
			main_data['long_financing_rate'] = np.nan
			main_data['short_financing_rate'] = np.nan
			main_data['buy_tax_rate'] = np.nan
			main_data['sell_tax_rate'] = np.nan
			logger.info("adding adj price columns")
			fut_data = main_data[main_data['product']=='future']
			if (len(fut_data))>0:
				fut_data_adj = fut_data[['cp_adj_px']].copy()
				fut_data_adj['cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cp_adj_px'].shift(-1)
				fut_data_adj['cum_adj_px'].fillna(1, inplace = True)
				main_data.loc[main_data['product']=='future', 'cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cum_adj_px'].apply(lambda x: x[::-1].cumprod()[::-1]) 

			stock_data = main_data[main_data['product']=='stock']

			if (len(stock_data)>0):
				stock_data_adj = fut_data[['cp_adj_px']].copy()
				stock_data_adj['cum_adj_px'] = stock_data_adj.groupby(self._symbology)['cp_adj_px'].shift(-1)
				stock_data_adj['cum_adj_px'].fillna(1, inplace = True)
				main_data.loc[main_data['product']=='stock', 'cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cum_adj_px'].apply(lambda x: x[::-1].cumprod()[::-1]) 

				if 'borrow_rate' in main_data:
					main_data['borrow_rate'] = abs(main_data['borrow_rate']).ffill()
				else:
					main_data['borrow_rate']=0
				if 'borrow_rate_cost' in main_data:
					main_data['borrow_rate_score'] = main_data['borrow_rate_score'].ffill()
				else:
					main_data['borrow_rate_score'] = np.nan
				from backtester.commission import commission_rates
				from backtester.financing import long_financing_rates,  short_financing_rates
				from backtester. tax import buy_tax_rates, sell_tax_rates

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

			from backtester.financing import future_financing_rates
			if 'future' in main_data['product'].unique():
				main_data.lco[main_data['product']=='future', 'long_financing_rate'] = main_data.loc[main_data['product']== 'future','coutry_iso'].map(future_financing_rates)
				main_data.lco[main_data['product']=='future', 'short_financing_rate'] = main_data.loc[main_data['product']== 'future','long_financing_rate'] 
			main_data['tcost_rate'].fillna(self._sim_params.tcost, inplace= True)
			main_data['long_financing_rate'].fillna(self._sim_params.long_financing_rate, inplace= True)
			main_data['short_financing_rate'].fillna(self._sim_params.short_financing_rate, inplace= True)
			main_data['buy_tax_rate'].fillna(self._sim_params.buy_tax_rate, inplace= True)
			main_data['sell_tax_rate'].fillna(self._sim_params.sell_tax_rate, inplace= True)

			if self._sim_para2ms.borrow_rate_cost is not None:
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
			if 'scale_factor' in self._sim_params:
				self._scale_factor = self._sim_params.scale_factor
			if self._intraday:
				bar = self._input_data.dfs['bar']
				logger.info('Adjust timezone for bar data')
				tz = pytz.timezone (self._sim_params.timezone)
				bar.index = bar.index.set_levels(bar.index.levels[0].tz_localize('UTC').tz_convert(tz).tz_localize(None), level=0)
				bar.index = bar.index.rename('timestamp', level=0)
				bar = bar.reset_index()
				bar['date'] = bar['timestamp'].dt.date
				bar['time'] = bar['timestamp'].dt.time
				logger.info('add trade date')
				cutoff_time = pd.Timestamp(self._sim_params.day_cutoff_time).time()
				bar['trade_date'] = bar['date'].mask(bar['time'] < cutoff_time, bar['date'] -pd.Timedelta(days=1))
				bar = bar.set_index(['trade_date', 'timestamp', self._symbology])
				bar = bar.sort_index()
				logger.info('add last price columne')
				bar['last'] = bar['open']
				bar['last'].fillna(bar['close'].groupby(level=1).shift(1), inplace= True)
				bar['last'] = bar['last'].groupby(level=1).ffill()

				logger.info('add bar last price data')
				bar_last = bar['last']
				bar_last = bar_last.unstack(level=2)
				bar_last = bar_last.ffill()
				bar_last = bar_last.stack()
				bar_last.name = 'last'
				bar_last = bar_last.to_frame()
				self._inst_bar =bar 
				self._inst_bar_last = bar_last
			else:
				if self._sim_params.order_price not in self._inst_input:
					raise ValueError(" column{} not available in teh data".format(self._sim_params.order_price))
			if self._hedging:
				if self._sim_params.hedge_symbol not in self._inst_input.index.levels[1]:
					raise ValueError(" data for hedge symbol {} not loaded".format(self._sim_params.hedge_symbol))
				self._hedge_data = self._inst_input.loc[(slice(None), self._sim_params.hedge_symbol), ].reset_index(level=1, drop=True)
	def get_current_time(self):
		return self._current_time
	def get_current_date(self):
		return self._current_time.date()

	def update_portfolio(self, date):
		logger.info("update portfolio")
		if 'expired' in self._current_data:
			settled_pos = {}
			expired_ids = self._current_data[self._current_data['expired']==True].index.unique()
			for i in expired_ids:
				inst = self._universe.get_inst(i)
				if (inst is not None):
					if not equal_zero(inst.pos):
						settled_pos[i] = inst.pos
						inst.day_pos = - inst.sod_pos
			if (len(settled_pos))>0:
				try:
					self._inst_stat.loc[(date, list(settled_pos.kes())), 'settled_pos'] = list(settled_pos.values())
				except:
					import pdb; pbd.set_trace()
		positions ={}
		for sym, inst in self._universe.insts.items():
			positions[sym] = inst.pos
		mi = pd.MultiIndex.from_product([[date],list(positions.kes())], names= self._inst_stat.index.names)
		self._eod_pos = pd.Series(list(positions.values()), index=mi)
		self._inst_stat.loc[date, 'pos'] = self._eod_pos

	def generate_performance(self):
		logger.info("generate_performance")
		inst_data = self._inst_input.join(self._inst_stat)
		tr = self._trade_record
		if len(tr)>0:
			tr['time'] = tr['timestamp'].dt.time #need to check
			tr = tr.sort_index(by=['timestamp', 'symbol'])
			tz_df = inst_data['tz'].to_frame().reset_index()
			tr = pd.merge_asof(tr, tz_df, left_on='timestamp', right_on='date', left_by='symbol', right_by= self._symbology, direction= 'nearest')
			tz_list = tr['tz'].dropna().unique()
			for tz in tz_list:
				tr.loc[tr['tz']==tz, 'timestamp_loca']=tr[tr['tz']==tz]['timestamp'].dt.tz_localize(self.sim_params.timezone).dt.tz_convert(tz).dt.tz_localize(None)
			tr['timestamp_localtime'] = tr['timestamp_local'].dt.time
			tr['date'] = tr['timestamp_local'].dt.floor(freq='D')
			tr['date'] = tr['date'].mask(tr['timestamp_localtime']>datetime.time(18,0), tr['timestamp_local'].dt.ceil(freq='D'))
			tr = tr.sort_values(by=['date','symbol'])
			tr.drop(self._symbology, axis=1, inplace=True)
			tz_df['date_tradable'] = tz_df['date']
			tr = pd.merge_asof(tr, tz_df[['date',self._symbology,'date_tradable']], on = 'date', left_by='symbol', right_by = self._symbology, direction= 'forward') 
			tr['date'] = tr['date_tradable']
			tr.drop(['date_tradable', self._symbology], axis =1 , inplace = True)
			tr = tr.sort_values(by=['timestamp', 'symbol'])
			cutoff_time = pd.Timestamp(self._sim_params.day_cutoff_time).time()
			ah_trade = tr[((tr['timestamp_localtime']>datetime.time(18,0,0))|(tr['timestamp_localtime']<datetime.time(7,0,0)))&(tr['time']<cutoff_time)] 
			ah_trade = ah_trade.groupby(['date', 'symbol'])['qty'].sum()
			ah_trade = ah_trade[ah_trade.abs()>0]
			if len(ah_trade)>0:
				inst_date['ah_trade']=ah_trade
				inst_data['ah_trade'].fillna(0,inplace = True)
				inst_data['sod_pos']+=inst_data['ah_trade']
				inst_data['ah_trade_shift'] = inst_data.groupby(level =1)['ah_trade'].shift(-1).fillna(0)
				inst_data['pos'] -=inst_data['ah_trade_shift']
				self._inst_stat['sod_pos'] = inst_data['sod_pos']
				self._inst_stat['pos'] = inst_data['pos']
			else:
				tr['date'] = tr['timestamp'].dt.floor(freq='D')

			logger.info("merging with instrument data")

			sec_types = inst_data['security_typ'].dropna().unique()
			to_merge_cols = ['close', 'sod_pos','contract_size', 'fx', 'slippage', 'security_typ']
			if SECURITY_TYPE_NDIRS in sec_types:
				to_merge_cols +=['days', 'day_count','cum_disc_factor']
			to_merge = inst_data[to_merge_cols].copy()
			to_merge.index.names = ['date','symbol']
			to_merge = to_merge.reset_index()
			tr = tr.merge(to_merge, left_on=['date', 'symbol'], right_on=['date', 'symbol'], how='left')
			logger.info('calculating trade level stat')
			tr_ndir - tr[tr['security_typ']==SECURITY_TYPE_NDIRS]
			if len(tr_ndir)> 0:
				def fill_tr_for_ndir(tr):
					tr['trade_price'] = (tr.price+tr.slippage*100).where(tr.qty>0,0)+(tr.price - tr.slippage*100).where(tr.qty<0,0)
					tr['qty'] = pd.to_numeric(tr['qty'])
					tr['slippage'] = ((tr['price']-tr['trade_price'])/100*tr['qty']*tr['days']/tr['day_count']*tr['cum_disc_factor']).abs()
					tr['trade_delta'] = tr['qtr']
					tr['buy_value'] = tr['qty'].where(tr['qty']>0,0).abs()
					tr['sell_value'] = tr['qty'].where(tr['qty']<0,0).abs()
					tr['trade_value'] = tr['buy_value'] + tr['sell_value']
					tr['pnl'] = (tr['close'] - tr['trade_price'])/100*tr['qty']*tr['days']/tr['day_count']*tr['cum_disc_factor']
					tr['traded']=tr['qty'].abs()
					tr['sod_pos'].fillna(0, inplace= True)
					tr['pos_intraday'] = tr.groupby(['date','symbol'])['qty'].cumsum().fillna(0)
					tr['pos'] = tr['pos_intraday']+tr['sod_pos']
					tr['delta'] = tr['pos']
					tr['value'] = tr['delta'].abs()
					return tr
				fill_tr_for_ndir(tr_ndir)

			tr_non_ndirs = tr[tr['security_typ']!= SECURITY_TYPE_NDIRS]

			if len(tr_non_ndir)> 0:
				def fill_tr(tr):
					tr['trade_price'] = tr.price.where(tr.qty>0,0)*(1+tr.slippage) +tr.price.where(tr.qtr<0,0)*(1-tr.slippage)
					tr['qty'] = pd.to_numeric(tr['qty'])
					tr['slippage'] = ((tr['price']-tr['trade_price'])*tr['qty']*tr['contract_size']).abs()
					tr['trade_delta'] = tr['qtr']*tr['trade_price']*tr['contract_size']
					tr['buy_value'] = (tr['trade_price']*tr['qty'].where(tr['qty']>0,0)*tr['contract_size']).abs()
					tr['sell_value'] = (tr['trade_price']*tr['qty'].where(tr['qty']<0,0)*tr['contract_size']).abs()
					tr['trade_value'] = tr['buy_value'] + tr['sell_value']
					tr['pnl'] = (tr['close'] - tr['trade_price'])*tr['qty']*tr['contract_size']
					tr['traded']=tr['qty'].abs()
					tr['sod_pos'].fillna(0, inplace= True)
					tr['pos_intraday'] = tr.groupby(['date','symbol'])['qty'].cumsum().fillna(0)
					tr['pos'] = tr['pos_intraday']+tr['sod_pos']
					tr['delta'] = tr['pos']*tr['price']*tr['contract_size']
					tr['value'] = tr['delta'].abs()
					return tr
				fill_tr(tr_non_ndir)
			tr = pd.concat([tr_non_ndirs,tr_ndirs])
			for c in ['delta','value']:
				tr[c+'_usd'] = tr[c]/tr['fx']
			logger.info("calculating trade daily level stat")
			tr['qty'] = tr['qty'].astype(float)
			tr['pnl'] = tr['pnl'].astype(float)

			tr_daily = tr.groupby(['date','symbol'])[['trade_value','buy_value','sell_value', 'slippage','traded','qty','pnl']].sum()
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
			inst_data['traded'] = tr_daily['traded']
			inst_data['traded'].fillna(0.0, inplace= True)
			self._trade_record = tr
		else:
			inst_data['buy_turnover'] = 0.0
			inst_data['sell_turnover'] = 0.0
			inst_data['turnover'] = 0.0
			inst_data['trade_pnl'] = 0.0
			inst_data['slippage_cost'] = 0.0
			inst_data['trade_qty'] = 0.0
			inst_data['traded'] = 0.0
		logger.info("generating instrument stat")
		ndir_mask = (inst_data['security_typ']==SECURITY_TYPE_NDIRS)
		has_ndir = False
		if ndir_mask.ay():
			has_ndir=True
		inst_data['sod_pos'].fillna(0.0, inplace=True)
		inst_data['settled_pos'].fillna(0.0, inplace=True)
		inst_data['pos'].fillna(0.0, inplace=True)
		inst_data['delta'] = inst_data['pos']*inst_data['close']*inst_data['contract_size']
		if has_ndir:
			inst_data.loc[ndir_mask,'delta'] = inst_data['pos']
		inst_data['value'] = np.abs(inst_data['delta'])
		inst_data['prev_close'] = inst_data.groupby(level=1)['contract_size'].shift(1)
		inst_data['prev_contract_size'] = inst_data.groupby(level=1)['contract_size'].shift(1)
		if 'cap_adj_px' in inst_data:
			inst_data['cap_adj_px'].fillna(1, inplace=True)
			inst_data['prev_close_adj'] = inst_data['prev_close']*inst_data['cp_adj_px']
		else:
			inst_data['prev_close_adj'] = inst_data['prev_close']
		if not self._sim_params.stock_total_return:
			inst_data.loc[inst_data['product']=='stock','prev_close_adj'] = inst_data['prev_close']

		inst_data['price_change'] = inst_data['close']*inst_data['contract_size'] - inst_data['prev_close_adj']*inst_data['contract_size'] 
		inst_data['price_change'].fillna(0, inplace=True)
		inst_data['day_pnl'] = inst_data.price_change*inst_data['sod_pos']
		if has_ndir:
			inst_data.loc[ndir_mask,'day_pnl'] = inst_data.price_change/100 *inst_data['sod_pos']*inst_data['days']/inst_data['day_pnl'] *inst_data['cum_disc_factor']
		inst_data['tcost'] = (inst_data['turnover']*inst_data['tcost_rate']).abs()
		if self._sim_params.enable_tax_cost:
			inst_data['buy_tax_cost'] = (inst_data['buy_turnover']*inst_data['buy_tax_rate']).abs().fillna(0)
			inst_data['sell_tax_cost'] = (inst_data['sell_turnover']*inst_data['sell_tax_rate']).abs().fillna(0)
		else:
			inst_data['buy_tax_cost']=0
			inst_data['sell_tax_cost']=0

		inst_data['tax_cost'] = inst_data['buy_tax_cost'] +inst_data['sell_tax_cost']
		inst_data['long_financing_cost'] = (inst_data['value'].where(inst_data['pos']>0,0)*inst_data['long_financing_rate']).fillna(0)/365.0 
		inst_data['short_financing_cost'] = (inst_data['value'].where(inst_data['pos']<0,0)*inst_data['short_financing_rate']).fillna(0)/365.0
		inst_data['financing_cost'] =inst_data['long_financing_cost']*inst_data['short_financing_cost']
		inst_data['financing_cost'] = inst_data['financing_cost'].groupby(level=1).shift(1)

		inst_data['borrow_cost'] = inst_data['value'].where(inst_data['pos']<0,0)*inst_data['borrow_rate'].fillna(0)/365.0
		inst_data['pnl'] = inst_data.trade_pnl + inst_data.day_pnl - inst_data.tcost - inst_data.financing_cost - inst_data.borrow_cost - inst_data.tax_cost

		#add usd field

		for c in ['delta', 'value','pnl','turnover','tcost','financing_cost','slippage_cost', 'borrow_cost']:
			inst_data[c+'_usd'] = inst_data[c]/inst_data['fx']
			if has_ndir:
				inst_data.loc[ndir_mask, c+'_usd'] = inst_data[c]
		total_value = inst_data.groupby(level = 0)['value_usd'].sum()
		total_value = total_value.reindex(index = inst_data.index, level = 0)
		divisor = 1/total_value
		inst_data['weight'] = inst_data['value_usd']*divisor
		if (inst_data.weight>self._sim_params.max_weight).any():
			logger.warn("max weight {} breached".format(self._sim_params.max_weight))

		for c in inst_data:
			if c not in self._inst_input:
				self._inst_stat[c] = inst_data[c]
		logger.info("generating portfolio stats")
		start_year = int(self._start_date.year)
		start_loc, end_loc = inst_data.index.levels[0].slice_locs(self._start_date, self._end_date)
		index_slice = inst_data.index.levels[0][start_loc:end_loc]
		df = pd.DataFrame(index = index_slice)
		df['long_pnl'] = inst_data.pnl_usd.where(inst_data.pos>0,0).sum(level=0).fillna(0)
		df['short_pnl'] = inst_data.pnl_usd.where(inst_data.pos<0,0).sum(level=0).fillna(0)
		df['pnl'] = inst_data.pnl_usd.sum(level=0).fillna(0)
		df['cum_pnl'] = df['pnl'].cumsum()
		df['cum_long_pnl'] = df['long_pnl'].cumsum()
		df['cum_short_pnl'] = df['short_pnl'].cumsum()
		if self._sim_params.exclude_cur_from_portfolio_size:
			df['value'] = inst_data[inst_data['product']!='currency']['value_usd'].sum(level=0).fillna(0)
			df['delta'] = inst_data[inst_data['product']!='currency']['delta_usd'].sum(level=0).fillna(0)
		else:
			df['value'] = inst_data['value_usd'].sum(level=0).fillna(0)
			df['delta'] = inst_data['delta_usd'].sum(level=0).fillna(0)
		if self._sim_params.exclude_cur_from_portfolio_size:
			df['turnover'] = inst_data[inst_data['product']!='currency']['turnover_usd'].abs().sum(level=0)
		else:
			df['turnover'] = inst_data['turnover_usd'].abs().sum(level=0)
		df['high_water'] = df['cum_pnl'].expanding().max()
		df['under_water'] = df['pnl'] -df['high_water']

		df['tcost'] = inst_data['tcost_usd'].abs().sum(level=0)
		df['tax_cost'] = inst_data['tax_cost_usd'].abs().sum(level=0)
		df['borrow_cost']=inst_data['borrow_cost_usd'].abs().sum(level=0)
		df['financing_cost'] = inst_data['financing_cost_usd'].sum(level=0)
		df['slippage']=inst_data['slippage_cost_usd'].abs().sum(level=0)
		df['pnl_raw'] = df['pnl']+df['slippage']+df['tcost']+df['tax_cost']+df['borrow_cost']+df['financing_cost']
		df['cum_pnl_raw']=df['pnl_raw'].cumsum()

		if self._sim_params.init_capital is None:
			logger.warning('Init capital is not provided - use average gross value to calculate return')
			if df['value'].sum()<0.001:
				df['ret'] = 0.0
				df['ret_raw'] = 0.0
			else:
				df['ret'] = df['pnl']/df[df['value']>0]['value'].mean()
				df['ret_raw'] = df['pnl_raw']/df[df['value']>0]['value'].mean()
		else:
			df['ret'] = df['pnl']/self._sim_params.init_capital
			df['ret_raw'] = df['pnl_raw']/self._sim_params.init_capital

		df['cum_ret'] = df['ret'].cumsum()
		df['cum_ret_raw'] = df['ret_raw'].cumsum()

		if self._hedging:
			self._hedge_data['ret'] = self._hedge_data['close'].pct_change().shift(-1)
			df['hedge_pnl'] = -df['delta']*self._hedge_data['ret']
			df['cum_hedge_pnl'] = df['hedge_pnl'].cumsum()
			df['cum_total_pnl'] = df['cum_pnl']+df['cum_hedge_pnl']
		logger.info("generating yearly stats")
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


		logger.info('gerenating overall stats')
		start_year = int(self._start_date.year)
		s = self.update_stats(df)

		for k in list(s.keys()):
			if k not in self._summary:
				self._summary[k] = np.nan
		self._summary.loc['All'] = pd.Series(s)

		for c in df:
			self._pf_stat[c] = df[c]
	def update_stats(self, df):
		#need to check
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
			max_underwater_end_date = days_since_high_water.idxmax()
			max_underwater_start_date = days_since_high_water.loc[:max_underwater_end_date].iloc[::-1].idxmin()
			s.max_underwater_duration = (max_underwater_end_date-max_underwater_start_date).days

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

	def insert_order(self, order):
		return self._simulator.order(order)
	def cancel_order(self, id):
		pass
	def modify_order(self, order):
		pass
	@property
	def sim_params(self):
		return self._sim_params

	def load_hsitorical_result(self, id = None, path = None, cutoff_date = None):
		one_day = pd.Timedelta(days=1)
		from backtester.result import load_result
		logger.info("loading historical result {} {} {} ".format(id, path, cutoff_date))
		self._hist_result = load_result(id=id, path = path)

		if cutoff_date is not None:
			self.hist_last_day = pd.Timestamp(cutoff_date)
		else:
			self.hist_last_day = self._hist_result.portfolio_data.index[-1]

		logger.info("use historical result from {} to {}".format(self._hist_result.portfolio_data.index[0], self.hist_last_day))
		self.actual_start_date = max(self.hist_last_day+one_day, self.actual_start_date)

	def generate_pipelines(self):
		logger.info('Generating pipelines')
		self._pipeline_results = {}
		if self._sim_params.load_pipelines:
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
	def fill_result(self, result):
		result._input_meta_data = self._input_data.meta
		result._inst_input = self._inst_input
		result._pf_input = self._pf_input
		result._inst_stat = self._inst_stat
		result._pf_stat = self._pf_stat
		result._inst_custom = self._inst_custom
		result._pf_custom = self._pf_custom
		result._inst_bar = self._inst_bar
		result._statistics = self._summary
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
		logger.info('Handle data')
		dates_locs = self._inst_input.index.levels[0].slice_locs(start= self.actual_start_date)
		dates = self._inst_input.index.levels[0][dates_locs[0]:]
		if dates_locs[0] >0:
			previous_date = self._inst_input.index.levels[0][dates_locs[0]-1]
		else:
			previous_date = None
		self._strategy._context.previous_date = previous_date
		self._dates = dates

		self._dates_to_update_universe = set()
		logger.info('loading universe')
		#load stocks
		if 'stock' in self._inst_input['product'].unique():
			logger.info('loading stocks')
			stock_input = self._inst_input[self._inst_input['product']=='stock']
			stock_input.index = stock_input.index.remove_unused_levels()
			stocks = stock_input.index.levels[1].unique()
			if len(stocks)>0:
				self._universe.add_stocks(stocks)
			for sym, inst in self._universe.stocks.items():
				inst_data = self._inst_input.loc[(slice(None), sym):]
				inst.lot_size = inst_data['lot_size'].iloc[0]
				inst.currency = inst_data['cur'].iloc[0] + ' Curncy'

		#load futures
		if 'future' in self._inst_input['product'].unique():
			logger.info('loading future')
			root_list = self._universe.get_future_root_list()
			roots_available = self._inst_input['root_symbol'].dropna().unique()
			if len(root_list)>0:
				for root in root_list:
					if root in roots_available:
						futures = self._inst_input[self._inst_input['root_symbol']==root].reset_index(level=1)[self._symbology].dropna().unique()
						for f in futures:
							inst = self._universe.add_future(f)
							inst_data = self._inst_input.loc[(slice(None), f), :]
							inst.currency = inst_data['cur'].iloc[0] + ' Curncy'
							inst.contract_size = inst_data['contract_size'].iloc[0]
							inst.expiry_date = inst_data['last_tradeable_dt'].iloc[0]
							inst.root = root
							contract_size_diff = inst_data['contract_size'].diff()
							contract_size_diff = contract_size_diff[contract_size_diff.abs()>0]
							if len(contract_size_diff) >0:
								self._dates_to_update_universe = self._dates_to_update_universe.union(contract_size_diff.reset_index(level = 0)['date'].unique()) 

		if 'index' in self._inst_input['product'].unique():
			logger.info('loading index')
			for sym, inst in self._universe.indices.items():
				inst_data = self._inst_input.loc[(slice(None), sym), :]
				inst.currency = inst_data['cur'].iloc[0] +' Curncy'

		if 'currency' in self._inst_input['product'].unique():
			logger.info('loading currency')
			currencies = self._inst_input[self._inst_input['security_typ'].isin([SECURITY_TYPE_DF, SECURITY_TYPE_NDF, SECURITY_TYPE_NDIRS, SECURITY_TYPE_CD])]['cur'].unstack().ffill()
			if len(currencies)>0:
				currencies = currencies.iloc[-1]
				cur_dict = currencies.to_dict()
				for k, v in cur_dict.items():
					inst= Currency(k)
					inst.currency = v +' Curncy'
					self._universe.add_currency(k, inst = inst)
		self._strategy._data_cluster.add_data('instrument_stat', self._inst_stat)
		self._strategy._data_cluster.add_data('instrument_custom', self._inst_custom)
		self._strategy._data_cluster.add_data('portfolio_custom', self._pf_custom)

		from utils.progress_bar import log_progress

		logger.info("dates to update universe [{}]".format(','.join([str(date) for date in self._dates_to_update_universe])))
		new_year = None
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

			self._strategy._context.previous_date = date

	def update_universe(self, date):
		for sym, inst in self._universe.stocks.items():
			inst.suspend = (sym not in self._current_data.index)

		if date.to_datetime64() in self._dates_to_update_universe:
			for name, f in self._universe.futures.items():
				if name in self._current_data.index:
					logger.info("Update universe for symbol {} on {}".format(name, date))
					contract_size = self._current_data.loc[name, 'contract_size']
					if contract_size is not None:
						f.contract_size = contract_size


	def handle_per_day(self, date):
		logger.info(date)
		if self._intraday:
			self._current_time = date +pd.Timedelta(self._sim_params.day_cutoff_time)
		else:
			self._current_time = date


		self._current_data = self._inst_input.ix[date]
		self._simulator.reset()
		self._strategy._order_book.reset()
		self._strategy._trade_book.reset()
		self._simulator._date = date
		self._simulator._ref_date = self._current_data

		logger.info("update universe")
		self.update_universe(date)
		for s, inst in self._universe.insts.items():
			inst.sod_pos = inst.pos
			inst.day_pos = 0

		if self._eod_pos is not None:
			self._eod_pos.index = self._eod_pos.index.set_levels([date], level=0)

		logger.info("adjusting positions")
		if 'cp_adj_pos' in self._current_data:
			df_adj = self._current_data.dropna(subset=['cp_adj_pos'])[['cp_adj_pos']].reset_index()
			if len(df_adj)>0:
				df_adj = df_adj.set_index(self._symbology)
				symbols = df_adj.index.unique()
				for sym in symbols:
					inst = self._universe.get_inst(sym)
					if inst is not None and not equal_zero(inst.sod_pos):
						logger.info("adj positions for {} ".format(sym))
						inst.sod_pos /= df_adj.loc[sym, 'cp_adj_pos']
						self._eod_pos.lc[date, sym]/=df_adj.lc[sym, 'cp_adj_pos']
		if self._eod_pos is not None:
			self._inst_stat.loc[date,'sod_pos'] = self._eod_pos
		for sym, inst in self._universe.insts.items():
			if sym in self._current_data.index:
				inst.open_price = self._current_data.loc[sym,'open']
				if 'vwap' in self._current_data:
					inst.vwap = self._current_data.loc[sym,'vwap']

		r = True
		logger.info("before trading start")
		if self._strategy.before_trading_start()!=False:
			self._sched.reset()
			def func(self, task, *args, **kwargs):
				return task(self._strategy._context, self._strategy._data_cluster, *args,**kwargs)
			for name, taks in self._strategy.tasks.items():
				rule = task[0]
				if rule.time is not None:
					if rule.time <pd.Timestamp(self._sim_params.day_cutoff_time).time():
						cal_date = (date + pd.Timedelta(days=1)).date()
					else:
						cal_date = date.date()
					trigger_time = pd.Timestamp(datetime.datetime.combine(cal_date, rule.time))
					if rule.period is None:
						self._sched.add_task(name, trigger_time, partial(func, self, task[1]), args=task[2], kwargs=task[3])
					else:
						self._sched.add_periodic_task(name, period = rule.period, trigger_time = trigger_time, func= partial(func, self, task[1]), args=task[2], kwargs=task[3]) 
				elif rule.period is not None:

					self._sched.add_periodic_task(name, period = rule.period, func= partial(func, self, task[1]), args=task[2], kwargs=task[3]) 

			if self._intraday:
				if date not in self._inst_bar.index:
					logger.error('{} not found in bar data'.format(date))
					return True

				df_bar_today = self._inst_bar.loc[date]
				df_bar_last_today = self._inst_bar_last.loc[date]
				self._simulator._px_data = df_bar_today
				if self._sim_params.handle_data:
					date_open_time = date +pd.Timedelta(self._sim_params.open_time)
					date_close_time = date +pd.Timedelta(self._sim_params.close_time)
					df_bar_last_today = df_bar_last_today(date_open_time:date_close_time)
					for time, bar_last in df_bar_last_today.groupby(level=0):
						self._current_bar_last = bar_last.loc[time]
						self._current_time = time
						self._sched.run()
						for sym, inst in self.universe.insts.items():
							inst.last_price = self._current_bar_last.loc[inst.symbol,'last']
						r = self._strategy.handle_data()
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
							if time in df_bar_last_today.index:
								self._current_bar_last = df_bar_last_today.loc[time]
							else:
								logger.error("can not find time {} in bar data today".format(time))
								self._sched.remove_task(name)
								continue

							for sym, inst in self._universe.insts.items():
								if sym in self._current_bar_last.index:
									inst.last_price = self._current_bar_last.loc[sym, 'last']
								elif sym in self._current_data.index:
									inst.last_price = self._current_data.loc[sym, 'close']
							self._sched.run()
						else:
							break
				logger.info("set close price to last")
				for sym, inst in self._universe.insts.items():
					if sym in self._current_data.index:
						inst.last_price = self._current_data.loc[inst.symbol, 'close']
			else:
				self._simulator._px_data = self._current_data
				logger.info("set close price to last")
				for sym, inst in self._universe.insts.items():
					if sym in self._current_data.index:
						inst.last_price = self._current_data.loc[inst.symbol, 'close']
				r = self._strategy.handle_data()
			logger.info("dump order record")				
			self.dump_order_record()
			logger.info("dump trade record")
			self.dump_trade_record()
		self.update_portfolio(date)
		return r
	def dump_order_record(self):
		self._order_record = self._order_record.append(self._strategy.order_book.to_dateframe())

	def dump_trade_record(self):
		self._trade_record = self._trade_record.append(self._strategy.trade_book.to_dateframe())

	def save_result(self):
		self.fill_result(self.result)
		self.result.save()
	def init_strategy(self):
		logger.info("strategy init")
		self._strategy.init()
		logger.info("strategy load data")
		self._strategy.load_data()

	@property
	def log_path(self):
		return self._log_path
	def on_trade(self, trade):
		self._strategy.on_trade(trade)

def backtest_strategy(sim_params=None, strategy= None, start_date = None, end_date = None, result_id=None, load_data_only= False, historical_result = None):
	logger.info("****************************************")
	logger.info("***********back test begin *************")
	logger.info("****************************************")
	bt = Backtester(strategy = strategy, sim_params = sim_params, start_date = start_date, end_date = end_date, result_id = result_i)
	bt.prepare_data()
	if load_data_only:
		bt.save_result()
		return bt.result
	if historical_result is not None:
		bt.load_hsitorical_result(id=historical_result.get('id', None), path = historical_result.get ('path', None), cutoff_date = historical_result.get('cutoff_date', None))

	bt.init_strategy()
	bt.generate_pipelines()
	bt.handle_data()
	bt.generate_performance()
	bt.save_result()
	bt.result.context = bt._strategy._context
	return bt.result



	





