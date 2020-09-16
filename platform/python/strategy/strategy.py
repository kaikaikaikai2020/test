import datetime
import pytz
import pandas as pd
import threading
import logging
import time
import os
import math
from functools import partial

from strategy.strategy_instance import set_strategy_instance
from strategy.order import order
from strategy.order_book import OrderBook
from strategy.trade_book import TradeBook
from strategy.universe import Universe
from strategy.pipeline import load_pipelines, save_pipelines

from strategy.data_cluster import DataCluster
from algorithm.algo_instance import set_algo_instance
from loader.data_loader import DataLoader

from utils.dotdict import dotdict, to_dotdict
from utils.scheduler import Scheduler
from utils.epsilon import equal_zero

logger = logging.getLogger('Strategy')

class StrategyThread(threading.Thread):
	def __init__(self, strategy):
		super().__init__()
		self._strategy = strategy

	def run(self):
		logger.info ("start the strategy thread")
		self._strategy.thd_func()
		logger.info('exiting the strategy thread')

cfg_params_default = {
	'timezone':'Asia/Hong Kong',
	'handle_data_frequency':300,
	'order_handler_file':None,
	'scaler_factor':1,
	'save_pipelines':True,
	'log_path':None, 
	'day_cutoff_time':'07:00:00'

}

data_params_default = {
	'load_px_data': False, 
	'load_bar_data':False,
	'datasets':None, 
	'data_recipe':None,
	'col_map':None,
	'start_date':'20100101',
	'end_date':None,
	'update_cache':False,
	'use_cache':True


}


class Strategy(object):
	def __init__(self, alg, universe, symobology= 'bbgid', alg_params = None, cfg_params = None, data_params=None, name= None, intraday=True):
		logger.info('*'*40)
		logger.info('**** Strategy ****')
		logger.info('*'*40)
		set_strategy_instance(self)
		self._impl= None
		self._cfg_params = dotdict(cfg_params_default)
		if cfg_params is not None:
			sef._cfg_params.update(cfg_params)

		self._data_params = dotdict(data_params_default)
		if data_params is not None:
			self._data_params.update(data_params)

		if alg_params is not None:
			self._alg_params = to_dotdict(alg_params)
			logger.info ("alg params")
			logger.info(alg_params)

		else:
			self._alg_params = None

		self._alg = alg
		set_algo_instance(alg)
		self._name = alg.name if name is None else name
		self._symbology = symobology
		self._universe = Universe()
		self._universe.reset()
		self._universe_dict = universe
		self._universe.load(universe)
		self._context = dotdict({})
		self._data_cluster = DataCluster()
		self._order_book = OrderBook()
		self._trade_book = TradeBook()
		self._current_order_id = 0
		self._intraday = intraday

	def set_impl(self, impl):
		self._impl = impl
		self._log_path = impl.log_path

	def get_impl(self):
		return self._impl

	def init(self):
		self._alg.init(self._context)

	def on_start(self):
		pass

	def before_trading_start(self):
		return self._alg.before_trading_start(self._context, self._data_cluster)

	def handle_data(self):
		return self._alg.handle_data(self._context, self._data_cluster)

	def get_current_time(self):
		if self._impl is not None:
			return self._impl.get_current_time()
		else:
			return pd.Timestamp.now(self._cfg_params.timezone).tz_localize(None)

	def get_current_date(self):
		return self._impl.get_current_date()

	def get_trade_date(self):
		current_time = self.get_current_time()
		if current_time.time() <pd.Timestamp(self._cfg_params.day_cutoff_time).time():
			return current_time.date() - datetime.timedelta(days=1)
		else:
			return current_time.date()

	def order (self, symbol, qty, price = None, type= 'market', algo = None, start_time= None, end_time = None, max_vol = None):
		if qty==0:
			logger.warn('0 qty for order {} {} {}'.format(symbol, price, type))
			return False

		order = Order( id = self.generate_order_id(), symbol = symbol, qty=qty, price = price, timestamp=self.get_current_time(), type = type, algo= algo, start_time= start_time, end_time= end_time, max_vol= max_vol)
		self._order_book.add_order(order)
		return self._impl.insert_order(order)

	def order_value (self, symbol, value, price = None,  algo = None, start_time= None, end_time = None, max_vol = None):
		qty = self._calculate_order_qty(symbol, value, price)
		qty = self.round_to_lot(symbol, qty)
		if qty==0:
			logger.warn('0 qty for order {} {} {}'.format(symbol, price, type))
			return False

		return self.order(symbol, qty, price= price, algo=algo, start_time = start_time, end_time=end_time, max_vol= max_vol)

	def order_target (self, symbol, target, price = None,  algo = None, start_time= None, end_time = None, max_vol = None):
		inst = self._universe.get_inst(symbol)
		if inst is None:
			logger.error("{} nto found in the universe".format(symbol))
			return False
		qty = target - inst.pos
		qty = self.round_to_lot(symbol, qty)

		if equal_zero(qty):
			return True

		return self.order(symbol, qty, price= price, algo=algo, start_time = start_time, end_time=end_time, max_vol= max_vol)

	def order_target_value (self, symbol, target_value, price = None,  algo = None, start_time= None, end_time = None, max_vol = None):
		qty = self._calculate_order_qty(symbol, target_value, price)
		return self.order(symbol, qty, price= price, algo=algo, start_time = start_time, end_time=end_time, max_vol= max_vol)

	def cancel_order(self, id):
		return self._impl.cancel_order(id)

	def _calculate_order_qty(self, symbol, value, price = None):
		inst = self._universe.get_inst(symbol)
		if inst is None:
			logger.error ("{} not found in the universe".format(symbol))		
			return 0


		product = inst.type
		price = inst.last_price

		if product =='currency':
			return value*self._cfg_params.scale_factor

		if pd.isnull(price):
			logger.warn("price not avaialbe {}".format(symbol))
			return 0

		qty = value *self._scale_factor/price_cols
		if product = 'stock':
			qty= self.round_to_lot(symbol,qty)

		elif product =='future':
			qty = int(math.floor(qty/inst.contract_size+0.5))
		return qty

	def round_to_lot(self, symbol, qty):
		inst = self._universe.get_inst(symbol)
		if inst is not None:
			lot = inst.lot_size
			if pd.isnull(lot):
				logger.error("lot size not avaialbe {}".format(symbol))
				return 0
			return int(math.floor(qty/1ot +0.5))*lot
		return int(math.floor(qty +0.5))

	def generate_order_id(self):
		self._current_order_id +=1
		return self._current_order_id

	def get_alg_params(self):
		return self._alg_params

	def load_bar_data(self):
		pass

	def load_data(self, update_cache = None, use_cache = None):
		logger.info("loading data")

		data_loading_kwargs ={}
		if self._data_params.data_loading_kwargs is not None:
			data_loading_kwargs = self._data_params.data_loading_kwargs

		if update_cache is None:
			update_cache = self._data_params.update_cache

		if use_cache is None:
			use_cache = self._data_params.use_cache

		data_loaer = DataLoader()
		data = data_loader.load(recipe = self._data_params.data_recipe, datasets= self._data_params.datasets, universe = self._universe_dict, symobology = self._symbology, start_date = self._data_params.start_date, end_date = self.get_trade_date(), update_cache = update_cache, use_cache = use_cache, consolidating_latest_date = False, **data_loading_kwargs)
		if self._data_params.col_map is not None:
			for name, map in self._data_params.col_map.items():
				data.dfs[name].rename(columsn=self._data_params.col_map[name], inplace=True)

		if self._data_params.load_intraday_bar:
			from dataset.intraday_bar import intraday_bar as ds

			dfs= []
			query_date = data.dfs['bar']['date'].amx()
			stocks = self._universe.get_stock_list()
			if len(stocks)>0:
				df_stock= ds.get(start_date = query_date, product = 'stock', symbol = stocks)
				if df_stock is not None and len(df_stock)>0:
					dfs.append(df_stock)

			roots = self._universe.get_future_root_list()
			if len(roots)>0:
				future_map = {i+'1 Index': i for i in roots}
				df_future = ds.get(start_date = query_date, product ='future', symbols = list(future_map.keys()))

				if df_future is not None and len(df_future)>0:
					df_future.index = df_future.index.set_levels(df_future.index.levels[1].map(lambda x: future_map[x]), level=1)
					dfs.append(df_future)

			currencies = self._universe.get_currency_list()
			if len(currencies)>0:
				df_currency = ds.get(start_date = query_date, product = 'currency', symbols = currencies)
				if df_currency is not None and len(df_currency) >0:
					dfs.append(df_currency)

			if len(dfs)>0:
				df_intraday_bar = pd.concat(dfs)
			else:
				df_intraday_bar =  None

			if 'bar' in data.dfs:
				if df_intraday_bar is not None:
					data.dfs['bar'] = data.dfs['bar'].append(df_intraday_bar)
					data.dfs['bar'] = data.dfs['bar'][-data.dfs['bar'].index.duplcated()]

				data.dfs['bar'].sort_index(inplace = True)

		self ._enrich_data(data)
		for name , df in data.dfs.items():
			lag = data.lags[name]
			self._data_cluster.add_data(name, df, lag=lag)
		if self._data_params.external_data is not None:
			for name, ed in self._data_params.external_data.items():
				ed_path = ed['path']
				ed_lag = pd.Timedelta(ed['lag']) if 'lag' in ed else None

				logger.info("loading external data {} {} ".format(name, ed_path))
				df = pd.read_hdf(ed_path, key='data')
				if ed_lag is not None:
					self._data_cluster.add_data(name, df, lag= ed_lag)
				else:
					self._data_cluster.add_data(name, df)

		if 'main' in self._data_cluster:
			self._data_cluster.set_main_data('main')

		return data

	def run_pipelines(self):
		logger.info("running pipelines")

		result_dict = {}
		pipeline_input = {}

		for name in self._data_cluster.names:
			data = self._data_cluster.get_data(name)
			pipeline_input[name] = data._Data__df

		for k, v in self._alg._pipelines.items():
			if k in pipeline_input:
				continue
			logger.info("running pipeline {}".format(k))

			r = v[0](pipeline_input, *v[1], **v[2])
			if isinstance(r, pd.DataFrame) or isinstance(r, pd.Series):
				result_dict[k] = r
				pipeline_input[k] = r

			elif isinstance(r, dict):
				result_dict[k] ={}
				pipeline_input[k] ={}
				for c, s in r.items():
					if isinstance(s, pd.Series) or isinstance(s,pd.DataFrame):
						result_dict[k][c]=s
						pipeline_input[k][c]=s
					else:
						raise ValueError ('data in result dict must be dataframe or series')

			else:
				raise ValueError("reusult returned from pipeline must be dict or dataframe or series")

		for p, dfs in result_dict.items():
			if isinstance(dfs, pd.Series) or isinstance(dfs, pd.DataFrame):
				self._data_cluster.add_data(p, dfs)

			elif isinstance(dfs, dict):
				for c, s in dfs.items():
					self._data_cluster.add_data(c, s)

		if self._cfg_params.save_pipelines:
			save_pipelines(os.path.join(self._log_path, 'pipelines'), result_dict)

		return result_dict
	def load_pipelines(self, path = None, pipelines = None):
		logger.info("loading pipeline")
		if path is not None:
			result_dict = load_pipelines(os.path.join(path, 'pipelines'), pipeline_name = pipelines)
		else:
			result_dict = load_pipelines(os.path.join(self._log_path, 'pipelines'), pipeline_name= pipelines)

		for p, dfs in result_dict.items():
			if isinstance(dfs, pd.Series) or isinstance(dfs, pd.DataFrame):
				self._data_cluster.add_data(p, dfs)

			elif isinstance(dfs, dict):
				for c, s in dfs.items():
					self._data_cluster.add_data(c, s)

		return result_dict

	def add_fx(self, input_df, cur_col = 'cur'):
		logger.info("adding fx")
		if cur_col not in input_df:
			raise ValueError("cur not in input data")

		dfs= []
		for cur in input_df['cur'].unique():
			if pd.isnull(cur):
				continue
			fx = pd.DataFrame(index = input_df.index.levels[0])
			if cur == 'USD':
				fx['fx']=1
			else:
				if cur== 'GBp':
					cur_symbol = 'GBP Curncy'
				else:
					cur_symbol = cur + ' Curncy'
				cur_px = input_df.xs(cur_symbol, level =1)['close']
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
			input_df = input_df.reset_index()
			input_df = pd.merge_asof(input_df, df_fx, on='date', by ='cur')
			input_df = input_df.set_index(['date', symbology])
		else:
			raise ValueError("fail to add fx column")

		return input_df

	def add_adv(self, input_df):
		if 'volume' not in input_df:
			return input_df

		from operators.common import sma
		input_df['turnover'] = input_df['close']*input_df['volume']*input_df['contract_size']/input_df['fx']
		input_df['adv_30'] = sma(input_df['turnover'],30,30)

		if 'adv' in input_df:
			input_df['adv'].fillna(input_df['adv_30'])
			input_df.drop('adv_30', axis =1 , inplace = True)
		else:
			input_df.rename(columns={'adv_30':'adv'}, inplace= True)

		input_df['adv'] = input_df['adv'].groupby(level=1).bfill()
		input_df['adv'] = input_df['adv'].groupby(level=1).ffill()
		return input_df

	def add_adj_px(self, input_df):
		logger.info("adding adj price columns")
		fut_data = input_df[input_df['product']=='future']
		if len(fut_data) >0:
			fut_data_adj = fut_data[['cp_adj_px']].copy()
			fut_data_adj['cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cp_adj_px'].shift(-1)
			fut_data_adj['cum_adj_px'].fillna(1, inplace= True)
			input_df.loc[input_df['product']=='future', 'cum_adj_px'] = fut_data_adj.groupby(self._symbology)['cum_adj_px'].apply(lambda x:x[::-1].cumprod()[::-1])

		stock_data = input_df[input_df['product'] == 'stock']

		if len(stock_data) >0:
			stock_data_adj = stock_data[['cp_adj_px']].copy()
			stock_data_adj['cum_adj_px'] = stock_data_adj.groupby(self._symbology)['cp_adj_px'].shift(-1)
			stock_data_adj['cum_adj_px'].fillna(1, inplace= True)
			input_df.loc[input_df['product']=='stock', 'cum_adj_px'] = stock_data_adj.groupby(self._symbology)['cum_adj_px'].apply(lambda x:x[::-1].cumprod()[::-1])

		if 'cum_adj_px' in input_df:
			input_df['cum_adj_px'].fillna(1, inplace= True)
			for col in ['open', 'close', 'low', 'high', 'vwap', 'twap']:
				if col in input_df:
					input_df[col +'_adj'] = input_df[col] * input_df['cum_adj_px']
					input_df[col +'_adj'].fillna(input_df[col], inplace = True)

					if 'future' in input_df['product']:
						input_df.loc[input_df['product']=='future', col ] = input_df[col+'_adj']


		return input_df

	def adj_timezone(self, df):
		logger.info('adj timezone for bar data')
		tz= pytz.timezone(self._cfg_params.timezone)
		df.index = df.index.set_levels(df.index.levels[0].tz_localize('UTC').tz_convert(tz).tz_localize(None), level=0)
		df.index = df.index.rename ('timestamp', level = 0)
		df = df.reset_index()
		df['date'] = df['timestamp'].dt.date
		df['time'] = df['timestamp'].dt.time
		logger.info("add trade date")
		cutoff_time= pd.Timestamp(self._cfg_params.day_cutoff_time).time()
		df['trade_date'] = df['date'].mask(df['time'] <cutoff_time, df['date']-pd.Timedelta(days=1))
		df = df.set_index(['timestamp', self._symbology])
		df = df.sort_index()

		logger.info("add last price colume")
		df['last'] = df['open']
		df['last'].fillna(df['close'].groupby(level = 1).shift(1), inplace= True)
		df['last'] = df['last'].groupby(level=1).ffill()

		return df

	def _enrich_data(self, data):
		for name, df in data.dfs.items():
			if name == 'main':
				data.dfs['main'] = self.add_fx(data.dfs['main'])
				data.dfs['main'] = self.add_adj_px(data.dfs['main'])
				data.dfs['main'] = self.add_adv(data.dfs['main'])

			elif name == 'bar':
				data.dfs['bar'] = self.adj_timezone(df)

	def on_trade(self, trade):
		logger.debug("on trade {} {} {} @ {}".format(trade.timestamp, trade.symbol, trade.qty, trade.price))

		if self._trade_book.add_trade(trade):
			order = self._order_book.find_order(trade.order_id)
			if order is None:
				raise RuntimeError('trades order id [{}] not found in order book'.format(trade.order_id))
		else:
			raise RuntimeError("fail to add trade [{}] to trade book".format(trade.id))

		if not order.add_trade(trade):
			raise RuntimeError("fail to add trade [{}] to order".format(trade.id))

		inst = self._universe.get_inst(trade.symbol)

		if inst is not None:
			inst.day_pos +=trade.qty

		else:
			logger.error("fail to find {} in unverse when handling trade".format(inst.symbol))

	def close_all_positions(self):
		pass

	@property
	def symbology(self):
		return self._symbology

	@property
	def name(self):
		return self._name

	@property
	def tasks(self):
		return self._alg.tasks

	@property
	def log_path(self):
		return self._log_path

	@property
	def universe_dict(self):
		return self._universe_dict

	@property
	def order_book(self):
		return self._order_book

	@property
	def trade_book(self):
		return self._trade_book

	@property
	def intraday(self):
		return self._intraday

	def is_live(self) -> bool:
		return self._impl.is_live()

	@property
	def name (self):
		return self._name

if __name__ =='__main__':
	universe = {
			'currencies': {
				'symbols': ['INR Curncy', 'KRW Curncy']
			},
			'futures':{
				'symbols': ['ES', 'NQ']
			},
			'stocks':{
				'symbols': ['005490 KS Equity', '030200 KS Equity', 'HDB US Equity', 'HDFCB IS Equity', 'IBN US Equity', 'ICICIBC IS Equity', 'INFO IS Equity', 'INFY US Equity', 'KT US Equity', 'PKX US Equity', 'TTM US Equity', 'TTMT US Equity', 'WIT US Equity', 'WPRO IS Equity']
			}
	}

	strategy = Strategy('test', universe)
	strategy.start()
