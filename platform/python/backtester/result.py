import pandas as pd
from db.mongo import MongoDBClient
from utils.dotdict import dotdict
from utils.number import is_number
from config.config import Config
import uuid
import os
import json
from .plotting import *

class Result(object):
	def __init__(self, id=None, path= None):
		if id is None:
			self._id = str(uuid.uuid1())
		else:
			self._id = str(id)

		if path is None:
			parent_path= Config().get()['Backtest']['result_path']
			self._path= os.path.join(parent_path, self._id)
		else:
			self._path = path

		self._timestamep = None
		self._user = None
		self._inst_input = None
		self._pf_input = None
		self._inst_bar = None
		self._input_meta_data = None
		self._sim_params = None
		self._alg_name = None
		self._alg_params = None
		self._statistics = None
		self._col_map = None
		self._pipelines = dotdict({})
		self._inst_stat = None
		self._pf_stat = None
		self._inst_custom = None
		self._pf_cumstom = None
		self._inst_data =None
		self._pf_data = None
		self._order_record = None
		self._trade_record = None

	def save (self, path = None):
		client = MongoDBClient.get('Backtest')
		if path is None:
			path = self._path
		from collections import OrderedDict
		dict_to_save = dotdict(OrderedDict())
		dict_to_save.id = self._id
		dict_to_save.user = self._user
		dict_to_save.timestamp = self._timestamep
		dict_to_save.alg_name = self._alg_params
		dict_to_save.path = path
		dict_to_save.input_meta_data = self._input_meta_data
		dict_to_save.sim_params = self._sim_params
		dict_to_save.col_map = self._col_map
		if self._alg_params is not None:
			dict_to_save.alg_params = self._alg_params
		if self._statistics is not None:
			dict = self._statistics.to_dict(orient = 'index')
			new_dict = OrderedDict()
			for k in dict:
				if not isinstance(k, str):
					new_dict[str(k)] = dict[k]
				else:
					new_dict[k] = dict[k]
			dict_to_save.statistics = new_dict
		client.insert('backtest', 'backtest', dict_to_save)

		if not os.path.isdir(path):
			os.makedirs(path)
		from datetime import date, datetime
		def json_serial(obj):
			if isinstance(obj, (datetime, date)):
				return obj.isoformat()
			raise Typeerror("Type %s not serializable "%type (obj))
		with open(os.path.join(path, 'backtest.txt'), 'w') as of:
			del dict_to_save['_id']
			if 'statistics' in dict_to_save:
				del dict_to_save['statistics']
			json.dump(dict_to_save, of, indent=4, separators=(',',':'), default = json_serial)
		self._inst_stat.to_hdf(os.path.join(path, 'instrument_stat.hdf'), key='data')
		self._inst_custom.to_hdf(os.path.join(path, 'instrument_custom.hdf'), key='data')
		self._pf_stat.to_hdf(os.path.join(path, 'portfolio_stat.hdf'), key='data')
		self._pf_cumstom.to_hdf(os.path.join(path, 'portfolio_custom.hdf'), key='data')
		if self._statistics is not None:
			self._statistics.to_csv(os.path.join(path, 'statistics.csv'), index_label = 'year')
		if self._order_record is not None:
			self._order_record.to_csv(os.path.join(path, 'order_record.hdf'), key='data')
		if self._trade_record is not None:
			self._trade_record.to_csv(os.path.join(path, 'trade_record.hdf'), key='data')

	@staticmethod
	def load(path= None, id = None, load_input_date = False, load_pipelines= False):
		client = MongoDBClient.get('Backtest')
		if path is not None:
			result = Result.load_from_path(path)
		elif id is not None:
			r = client.find_one('backtest', 'backtest',{'id':id})
			if r is not None:
				path = r['path']
				result = Result.load_from_path(path)
			else:
				print("cant find the backtest with id: {}".format(id))
				return None
		if load_input_data:
			from loader.data_loader import DataLoader
			meta_data = dotdict(result.input_meta_data)
			data_loader DataLoader()
			data_loader._col_map = result._col_map
			input_data = data_loader.load(datasets=meta_data.datasets, universe= meta_data.universe, start_date = meta_data.start_date, end_date = meta_data.end_date, symbology = meta_data.symbology)
			result._inst_input = input_data.dfs['main']
			if 'bar' in input_data.dfs:
				result._inst_bar = input_data.dfs['bar']
			result._pf_input = pd.DataFrame(index = result._inst_input.index.levels[0])

		if load_pipelines:
			from strategy.pipeline imoort load_pipelines
			pipeline_results = load_pipelines(os.path.join(path, 'pipelines'))
			if len(pipeline_results) ==0 and result._sim_params.load_pipelines is not None:
				pipeline_results = load_pipelines(os.path.join(result._sim_params.load_pipelines_path,'pipelines'))
			result._pipelines = pipeline_results
		result.merge_instrument_data()
		result.merge_portfolio_data()
		return result
	@staticmethod
	def load_from_path(path):
		bt = None
		with open(os.path.join(path, 'backtest.txt')) as infile:
			bt = dotdict(json.load(infile))

		result = Result(id, path)
		result._alg_name = bt.alg_name

		if bt.alg_params is not None:
			result._alg_params = dotdict(bt.alg_params)

		if bt.sim_params is not None:
			result._sim_params = dotdict(bt.sim_params)
		result._timestamep = bt.timestamp
		result._input_meta_data = bt.input_meta_data
		result._user = bt.user
		result._path = bt.path
		result._statistics = pd.read_csv(os.path.join(path, 'statistics.csv'), index_col='year')

		fpath = os.path.join(path, 'instrument.hdf')
		if os.path.exists(fpath):
			data = pd.read_hdf(fpath, key='data')
			result._inst_data = data
		else:
			fpath = os.path.join(path, 'instrument_stat.hdf')
			if os.path.exists(fpath):
				result._inst_stat - pd.read_hdf(fpath, key='data')
			fpath = os.path.join(path, 'instrument_custom.hdf')
			if os.path.exists(fpath):
				result._inst_custom = pd.read_hdf(fpath, key='data')

		fpath = os.path.join(path, 'portfolio.hdf')
		if os.path.exists(fpath):
			data = pd.read_hdf(fpath, key='data')
			result._pf_data = data
		else:
			fpath = os.path.join(path, 'portfolio_stat.hdf')
			if os.path.exists(fpath):
				result._pf_stat = pd.read_hdf(fpath, key='data')
			fpath = os.path.join(path, 'portfolio_custom.hdf')
			if os.path.exists(fpath):
				result._pf_cumstom = pd.read_hdf(fpath, key='data')

		result._order_record = result.check_and_load_data('order_record.hdf')
		result._trade_record = result.check_and_load_data('trade_record.hdf')
		return result

	def merge_instrument_data(self):
		if self._inst_input is not None:
			self._inst_data = self._inst_input
			self._inst_data = self._inst_data.join(self._inst_stat, how='outer')
		else:
			self._inst_data = self._inst_stat
		if self._inst_data is not None:
			self._inst_data = self._inst_data.join(self._inst_custom, how='outer')
	def merge_portfolio_data(self):
		if self._pf_input is not None:
			self._pf_data = self._pf_input
			self._pf_data = self._pf_data.join(self._pf_stat, how='outer')
		else:
			self._pf_data = self._pf_stat
		if self._pf_data is not None:
			self._pf_data = self._pf_data.join(self._pf_custom, how='outer')

	def check_and_load_data(self, file):
		fpath = os.path.join(self._path, file)
		if os.path.exists(fpath):
			data = pd.read_hdf(fpath, key='data')
			return data

		return None

	@property
	def user(self):
		return self._user

	@user.setter
	def user(self, val):
		self._user = val

	@property
	def id(self):
		return self._id

	@id.setter
	def id(self, val):
		self._id = val
	@property
	def path(self):
		return self._path

	@path.setter
	def path(self, val):
		self._path = val

	@property
	def timestamp(self):
		return self._timestamep

	@timestamp.setter
	def timestamp(self, val):
		self._timestamep = val
	@property
	def input_meta_data(self):
		return self._input_meta_data
	@property
	def sim_params(self):
		return self._sim_params
	@sim_params.setter
	def sim_params(self, val):
		self._sim_params = val

	@property
	def alg_name (self):
		return self._alg_name

	@alg_name.setter
	def alg_name(self, val):
		self._alg_name = val

	@property
	def alg_params(self):
		return self._alg_params
	@alg_params.setter
	def alg_params(self, val):
		self._alg_params = val

	@property
	def statistics(self):
		return self._statistics

	@property
	def instrument_data(self):
		return self._inst_data
	@property
	def inst_data(self):
		return self._inst_data
	@property
	def portfolio_data(self):
		return self._pf_data
	@property
	def pf_data(self):
		return self._pf_data
	@property
	def instrument_input(self):
		return self._inst_input

	@property
	def portfolio_input(self):
		return self._pf_input

	@property
	def instrument_stat(self):
		return self._inst_stat
	@property
	def portfolio_stat(self):
		return self._pf_stat
	@property
	def instrument_custom(self):
		return self._inst_custom
	@property
	def portfolio_custom(self):
		return self._pf_cumstom
	@property
	def instrument_bar(self):
		return self._inst_bar
	@property
	def order_record(self):
		return self._order_record

	@property
	def trade_record(self):
		return self._trade_record

	@property
	def col_map(self):
		return self._col_map
	@property
	def pipelines(self):
		return self._pipelines

	def display_summary(self):
		plot_nice_table(self.statistics, 'portfolio stat summary')

	def plot(self, benchmark_symbol=None, figsize=(15,10), return_only=False):
		import pyfolio as pf
		import pytz 
		import matplotlib.pyplot as plt
		if benchmark_symbol is not None:
			if benchmark_symbol not in self.instrument_data.index.levels[1]:
				raise ValueError("benchmark_symbol {} not loaded".format(benchmark_symbol))
			benchmark_data = self.instrument_data.loc[(slice(None), benchmark_symbol), ].reset_index(level=1, drop=True)
			benchmark_data['ret'] = benchmark_data['close'].pct_change().shift(-1)

		plt.rcParams["figure.figsize"] = figsize
		ret = self.portfolio_data['ret'].copy()
		ret.index = ret.index.tz_localize(tz='utc')

		plot_return_pnl(self.portfolio_data)
		if return_only:
			return True
		pf.plotting.plot_rolling_sharpe(ret, rolling_window=126)
		plt.grid()
		plt.show()
		if benchmark_symbol is not None:
			ax = pf.plotting.plot_rolling_return(self.portfolio_data['ret'], benchmark_data['ret'].rename(benchmark_symbol))
			ax.set_title('backtest return vs benchmark {}'.format(benchmark_symbol))
			plt.grid()
			plt.show()
			plot_rolling_beta(self.instrument_data, self.portfolio_data, self.col_map, benchmark_symbol)
			plt.grid()
			plt.show()
		plot_pnl_breakdown(self.statistics, self._sim_params.hedge_symbol)
		plt.grid()
		plt.show()

		plot_pnl_long_short(self.portfolio_data)

		if self._sim_params.hedge_symbol is not None:
			plot_pnl_hedge(self.portfolio_data)
			plt.grid()
			plt.show()
		plot_delta_and_size(self.portfolio_data)
		plt.grid()
		plt.show()

		plot_turnover(self.portfolio_data['turnover'])
		plt.grid()
		plt.show()
		current_slippage = None
		if is_number(self._sim_params.slippage):
			current_slippage = int(self._sim_params.slippage*10000)
		plot_slippage_sweep(self.portfolio_data, current_slippage= current_slippage)
		plt.grid()
		plt.show()

		plot_annual_return_stack(self.portfolio_data)
		plot_day_of_month_return(self.portfolio_data)
		plt.grid()
		plt.show()
		plot_day_of_week_return(self.portfolio_data)
		plt.grid()
		plt.show()
		pf.plotting.plot_monthly_returns_heatmap(ret)
		plt.grid()
		plt.show()
		pf.plotting.plot_drawdown_underwater(ret)
		plt.grid()
		plt.show()
		pf.plotting.plot_drawdown_periods(ret, top=5)
		plt.grid()
		plt.show()

		plot_nice_table(pf.timeseries.gen_drawdown_table(ret, top=10), title= 'drawdowns')
		plot_instrument_pnl_contribution(self.instrument_data['pnl_usd'])

		if ('product' in self.instrument_data) and (len(self.instrument_data[self.instrument_data['product']=='stock'])>0):
			plot_stock_pnl_contribution(self.instrument_data[self.instrument_data['product']=='stock']['pnl_usd'])
			plt.grid()
			plt.show()

			if 'sector_name' in self.instrument_data:
				plot_sector_pnl_contribution(self.instrument_data)
				plt.grid()
				plt.show()
	def load_result(path=None, id=None, input_data = False, pipelines = False):
		return Result.load(path, id, input_data, pipelines)

	def display_summary(results, year=None):
		df = pd.DataFrame()
		for name, result in results.items():
			s = results.statistics.xs('All')
			s['name'] = name
			df = df.append(s)
		df = df.set_index('name')
		plot_nice_table(df, "multiple portfolio stata summary all")
		if year is not None:
			df= pd.DataFrame()
			for name, result in results.items():
				s = results.statistics.xs(str(year))
				s['name'] = name
				df = df.append(s)
			df = df.set_index('name')
			plot_nice_table(df, "multiple portfolio stata summary all")


if __name__=='__main__':
	r = Result()
	pass