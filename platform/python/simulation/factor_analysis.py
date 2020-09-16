import pandas as pd
import numpy as np
from operators.common import mean, std,shift, sum
import math
import datetime
from importlib import reload
from utils.epsilon import EPSILON
from simulation.plotting import *


class Result(object):
	def __init__(self):
		self.factors = []
		self.df_norm = None
		self.df_pf = None
		self.df_pnl = None
		self.daily_metrics = None
		self.performance_metrics = None
		self.timestamp = datetime.datetime.now()

	def display_summary(self):
		with pd.option_context("display.max_row", len(self.factors)):
			plot_nice_table(self.performance_metrics.sort_value(by='return'),'performance_metrics')

	def plot(self, input_data=None, factor=1, figsize= (15,10)):
		import pyfolio as pf
		import pytz
		import matplotlib.pyplot as plt
		plt.rcParams['figure.figsize'] = figsize
		ret = self.pf_data['ret'].copy()
		ret.index.tz = pytz.utc
		plot_return_pnl(self.pf_data)
		plt.grid()
		plt.show()

		pf.plotting.plot_rolling_sharpe(ret, rolling_window=126)
		plt.grid()
		plt.show()

		plot_pnl_long_short(self.pf_data)
		plt.grid()
		plt.show()

		plot_turnover(self.pf_data)
		plt.grid()
		plt.show()

		plot_annual_returns_stack(self.pf_data)
		plt.grid()
		plt.show()

		plot_day_of_month_returns(self.pf_data)
		plt.grid()
		plt.show()

		plot_day_of_week_returns(self.pf_data)
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

		plot_stock_pnl_contribution(self.inst_data['pnl'])
		plt.grid()
		plt.show()

		if input_data is not None and 'adv' in input_data:
			plot_pos_adv_hist(self.inst_data['pos'], input_data['adv'], factor= factor)
			plt.grid()
			plt.show()

			plot_pos_adv_scatter(self.inst_data['pos'], input_data['adv'])

			plt.grid()
			plt.show()

			plot_trd_adv_scatter(self.inst_data['trade'], input_data['adv'], factor= factor)

			plt.grid()
			plt.show()

			plot_return_adv_scatter(self.inst_data['pnl'], input_data['adv'])

			plt.grid()
			plt.show()

	def exist(self):
		return os.path.isdir(self.path)

	def save(self):
		os.makedirs(self.path, exist_ok= True)
		self.inst_data.to_hdf(os.path.join(self.path,'inst.hdf'), key= 'data')
		self.pf_data.to_hdf(os.path.join(self.path, 'pf.hdf'),key='data')
		self.performance_metrics.to_csv(os.path.join(self.path, 'performance_metrics.csv'), index_label='year')

	def load(self):
		if not self.exist():
			raise ValueError(self.path +' doesnt exist')
		print("loading factor analysis result: {}".format(self.path))

		self.pf_data = pd.read_hdf(os.path.join(self.path, 'pf.hdf'), key='data')
		self.inst_data = pd.read_hdf(os.path.join(self.path, 'inst.hdf'), key='data')
		self.performance_metrics = pd.read_csv(os.path.join(self.path, 'performance_metrics.csv'), index_col ='year')

def display_summary(results,year = None):
	if years is not None:
		if isinstance(years, str):
			years =[years]

	if isinstance(results, list):
		metrics_comb = pd.DataFrame()
		for r in results:
			metrics = r.performance_metrics.reset_index()
			metrics['name'] = '_'.join([r.name, r.universe, r.portfolio])
			if years is not None:
				metrics_comb = metrics_comb.append(metrics['year'].isin(years))
			else:
				metrics_comb = metrics_comb.append(metrics)

		metrics_comb = metrics_comb.set_index(['year', 'name'])
		metrics_comb = metrics_comb.sort_value()
		plot_nice_table(metrics_comb, 'performance metrics')
	elif isinstance(results, dict):
		metrics_comb = pd.DataFrame()
		for name, r in results.items():
			metrics = r.performance_metrics.reset_index()
			metrics['name'] = name
			if years is not None:
				metrics_comb = metrics_comb.append(metrcs[metrics['year'].isin(years)])
			else:
				metrics_comb = metrics_comb.append(metrics)

		metrics_comb = metrics_comb.set_index(['year', 'name'])
		metrics_comb = metrics_comb.sort_index()
		plot_nice_table(metrics_comb, 'performance_metrics')

	else:
		results.display_summary

def plot_results(results, figsize = (15,10), days = None):
	data_dict = {}
	if isinstance(results, list):
		for r in results:
			name = '_'.join([r.name, r.universe, r.portfolio])
			data_dict[name] = r.pf_data
	elif isinstance(results, dict):
		for name, r in results.items():
			data_dict[name] = r.pf_data

	plot_return_pnl(data= data_dict, return_only= True)

	if days is not None:
		plot_return_pnl (data=data_dict, return_only = True, days= days)


def normalize(f):
		print("normalizing factors")
		f_mean = f.groupby(level = 0).mean()
		f_std = f.groupby(level = 0).std()
		f_mean_bd = f_mean.reindex(level=0, index = f.index)
		f_std_bd = f_std.reindex(level=0, index = f.index)
		f_norm = (f-f_mean)/f_std
		return f_norm


def cross_sectional_corr(factors, lag =1):
		df_unstack = factor.unstack()
		df_unstack_shift = factor.shift(lag)
		dates= df_unstack.index.unique()
		f_corr = df_unstack.corrwith(df_unstack_shift, axis=1)
		return f_corr




def construct_quantile_portfolio(df_factors, quantile_low=0.1, quantile_high=0.9):
	print('constrcuting quantitle portfolio')
	
	df_quantiles = df_factors.groupby(level =0).quantitle(quantile_low, quantile_high)
	df_quantile_low = df_quantiles.xs(quantile_low, level =1)
	df_quantile_high = df.quantitle.xs(quantile_high, level = 1)
	df_quantile_low = df_quantile_low.reindex(index = df_factors.index, level = 0)
	df_quantile_high = df_quantile_high.reindex(index = df_factors.index, level = 0)

	df_pf_dir = pd.DataFrame(data= 0, index = df_factors.index, columns= df_factors.columns)
	df_pf_dir = df_pf_dir.maks(df_factors>= (df_quantile_high-EPSILON),1)
	df_pf_dir = df_pf_dir.maks(df_factors<= (df_quantile_low + EPSILON),-1)

	df_long_sum = df_pf_dir.where(df_pf_dir == 1, np.nan).groupby(level=0).sum()
	df_short_sum = df_pf_dir.where(df_pf_dir == -1, np.nan).groupby(level=0).sum()

	df_pf = pd.DataFrame(data=0, index=df_factors.index, columns = df_factors.columns)
	df_pd = df_pf.mask (df_pf_dir==1, (1/df_long_sum).reindex(df_factors.index, level=0))
	df_pd = df_pf.mask (df_pf_dir==-1, (1/df_short_sum).reindex(df_factors.index, level=0))

	df_pf *=0.5
	df_pf.fillna(0, inplace= True)

	return df_pf

def construct_total_portfolio(df_factors):
	print('constrcuting total portfolio')
	
	df_size = sum(df_factors.abs(), level=0)
	df_size_bd = df_size.reindex(index=df_factors.index, level=0)

	df_pf = df_factors/df_size_bd
	df.fillna(0, inplace=True)

	return df_pf

def generate_summary(df_daily):
	if len(df_daily) ==0:
		return None

	metrics = pd.Series()

	metrics['turnover'] = df_daily['turnover'].mean()
	metrics['pnl'] = df_daily['pnl'].sum()
	metrics['return'] = df_daily['ret'].sum()
	metrics['return_daily'] = daily['ret'].mean()
	metrics['skew'] = df_daily['ret'].skew()
	metrics['kurtosis'] = df_daily['ret'].kurt()
	metrics['bps'] = metrics['return']/df_daily['turnover'].sum()*10000
	metrics['volatility_daily'] = df_daily['ret'].std()
	metrics['volatility'] = metrics['volatility_daily']*15.874
	metrics['sharpe'] = metrics['return_daily']/metrics['volatility_daily']*15.874
	metrics['fitness'] =metrics['shapre'] *math.sqrt(abs(metrics['return'])/metrics['turnover'])
	high_water = df_daily['cum_ret'].expanding().max()
	high_water = high_water.fillna(method= 'bfill')
	i = (high_water -df_daily['cum_ret']).idxmax()
	if not pd.isnull(i):
		j = high_water[:i].idxmax()
		days_since_high_water = high_water.expanding().apply(lambda x: len(x) - np.argmax(np.ma.masked_invlid(x)))

		metrics['max_underwater_duration'] = days_since_high_water.max()
		metrics['max_drawdown'] = (df_daily['cum_ret'] - high_water).min()
		metrics['max_dd_duration'] = (i-j)
	else:
		metrics['max_underwater_duration'] = np.nan
		metrics['max_drawdown'] = np.nan
		metrics['max_dd_duration'] = np.nan

	if not equal_zero(metrics['max_drawdown']):
		metrics['calmar'] = (metrics['return_daily']*252)/(-metrics['max_drawdown'])
	else:
		metrics['calmar'] = np.nan

	linear_ret = pd.Series(np.linspace(0, metrics['return'],len(df_daily)), index= df_daily.index)
	mse = math.sqrt(((df_daily['cum_ret'] - linear_ret)**2).mean())
	if not equal_zero(mse):
		metrics['linearity'] = metrics['return']/mse
	else:
		metrics['linearity'] = np.nan

	return metrics


def generate_performance(): #need to check

	print("generating performance")
	df_inst = pd.DataFrame()
	df_daily= pd.DataFrame()
	df_inst['pos'] = pf

	df_inst['trade'] = pf.groupby(level=1).diff()
	df_daily['turnover'] = df_inst['trade'].abs().groupby(level=0).sum()
	ret = shift(data['return'],-1)
	df_inst['pnl'] = pf*ret

	df_aily['long_pnl'] = df_inst['pnl'].where(df_inst['pos']>0,0).sum(level=0)
	df_aily['short_pnl'] = df_inst['pnl'].where(df_inst['pos']<0,0).sum(level=0)
	df_daily['pnl'] =sum(df_inst['pnl'], level=0)
	df_daily['cum_pnl'] = df_daily['pnl'].cumsum()
	df_daily['cum_long_pnl'] = df_daily['long_pnl'].cumsum()
	df_daily['cum_short_pnl'] = df_daily['short_pnl'].cumsum()

	df_daily['ret'] = df_daily['pnl']
	df_daily['cum_ret'] = df_daily['cum_pnl']

	start_date = df_daily.index.min()
	end_date = df_daily.index.max()

	start_year = int(start_date.year)
	end_year = int(end_date.year)

	df_metrics = pd.DataFrame()

	for i in range(start_year, end_year+1):
		year_start = max(start_date, pd.Timestamp(i,1,1))
		year_end = min(end_date, pd.Timestamp(i,12,31))

		df_slice = df_daily.loc[year_start:year_end]
		summary = generate_summary(df_slice)

		if summary is not None:
			summary.name = i
			df_metrics = df_metrics.append(summary)

	summary = generate_summary(df_daily)
	df_metrics.loc['All'] = summary
	return df_inst, df_daily, df_metrics

def analyze_factors(name, universe, f, data, portfolio = 'total'):
	print("analyzing factor [{}] with universe [{}] and portfolio [{}]".format(name, universe, portfolio))

	f_norm = normalize(f)

	if portfolio == 'total':
		f_pf = construct_total_portfolio(f_norm)

	elif portfolio == 'quantile':
		f_pf = construct_quantile_portfolio(f_norm)

	else:
		raise ValueError("unknow portfolio flag: {}".format(portfolio))

	inst_data, pf_data, performance_metrics = generate_performance(f_norm, f_pf, data)

	result = Result(name, universe, portfolio)
	result.inst_data = inst_data
	result.pf_data = pf_data
	result.performance_metrics = performance_metrics
	return result

def corr(results):
	df_return = pd.DataFrame()
	if isinstance(results, list):
		for r in results:
			df_return[r.name] = r.pf_data['ret']
	elif isinstance(results, dict):
		for name, r in results.items():
			df_return[name] = r.pf_data['ret']
	else:
		raise ValueError("unspport")

	return df_return.corr()

def corr_with(results1, results2):
	df_return_1 = pd.DataFrame()
	if isinstance(results1, list):
		for r in results1:
			df_return_1[r.name] = r.pf_data['ret']

	elif isinstance(results1, dict):
		for name, r in results1.items():
			df_return_1[name] = r.pf_data['ret']

	else:
		raise ValueError("unsupport")

	df_return_2 = pd.DataFrame()

	if isinstance(results2, list):
		for r in results2:
			df_return_2[r.name] = r.pf_data['ret']

	elif isinstance(results2, dict):
		for name, r in results2.items():
			df_return_2[name] = r.pf_data['ret']

	else:
		raise ValueError("unsupport")

	corr_df = pd.DataFrame()
	for c in df_return_2:
		corr_dt[c] = df_return_1.corrwith(df_return_2[c])

	return corr_df

if __name__=='__main__':

	from factor_universe.markit_short import basic_factors
	df_raw = pd.read_hdf('jp_recipe.hdf')
	df_raw.rename(columns= {'dlyreturn':'return'}, inplace = True)
	df_raw['return'] /=100
	derived_factors = [
	'days_to_cover', 'total_demand_ratio', 'bo_inventory_ratio', 'bo_on_load_ratio', 'broker_demand_ratio', 'active_bo_inventory_ratio', 'active_available_bo_inventory_ratio']

	df_raw['days_to_cover'] = df_raw['total_demand_value'] /df_raw['adv']
	df_raw['total_demand_ratio'] = -df_raw['total_demand_value']/df_raw['adv']
	df_raw['bo_inventory_ratio'] = -df_raw['bo_inventory_value']/df_raw['adv']
	df_raw['bo_on_loan_ratio'] = -df_raw['bo_on_load_value']/df_raw['adv']
	df_raw['broker_demand_ratio'] = -df_raw['broker_demand_value']/df_raw['adv']
	df_raw['active_bo_inventory_ratio'] = -df_raw['active_bo_inventory_value']/df_raw['adv']
	df_raw['active_available_bo_inventory_ratio'] = -df_raw['active_available_bo_inventory_value']/df_raw['adv']

	for f in ['bo_inventory_value_add', 
			'bo_inventory_value_new',
			'bo_inventory_value_removed',
			'bo_inventory_value_increase',
			'bo_inventory_value_decrease',
			'bo_on_load_value_add',
			'bo_on_load_value_new',
			'bo_on_load_value_removed',
			'bo_on_load_value_increase',
			'bo_on_load_value_decrease',
			'broker_demand_value_add',
			'broker_demand_value_new',
			'broker_demand_value_removed',
			'broker_demand_value_increase',
			'broker_demand_value_decrease']:
		f_new = f+'_ratio'
		df_raw[f_new] = df_raw[f]/df_raw['adv']
		derived_factors.append(f_new)
	df_raw.replace([np.inf, -np.inf], np.nan, inplace=True)
	df_change = df_raw[basic_factors].groupby(level=1).diff()
	basic_factors_change =[]
	for f in basic_factors:
		f_new = f+ '_change'
		df_raw[f_new] = df_change[f]
		basic_factors_change.append(f_new)

	df_raw.replace([np.inf, -np.inf], np.nan, inplace=True)
	df_derived_change = df_raw[derived_factors].groupby(level=1).diff()
	derived_factors_change = []

	for f in derived_factors:
		f_new = f+'_change'
		df_raw[f_new] = df_derived_change[f]
		derived_factors_change.append(f_new)

	df_raw.replace([np.inf, -np.inf], np.nan, inplace=True)
	for universe in ['nky', 'tpx500']:
		df_universe = df_raw.query(universe +'_index==1')
		index_names =df_universe.index.names
		df_universe = df_universe.reset_index().set_index(index_names)

		for portfolio in ['total','quantile']:
			for f in ['ase2d_jpsize', 'ase2d_jpbeta', 'ase2d_jpliquidty']:
				result = analyze_factors(f, universe, df_universe[f], df_universe, portfolio= portfolio)
				result.save()



