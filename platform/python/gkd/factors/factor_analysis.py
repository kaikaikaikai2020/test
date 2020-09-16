import pandas as pd
import numpy as np
from operators.common import mean, std,shift, sum
import math
import datetime
from importlib import reload
from utils.epsilon import EPSILON

def normalize_factors(df, factors, low = 0.05, high= 0.95, std_cap = 2):
	print('normalizing factors')
	df_factors= df[factors]
	if low is not None and high is not None:
		df_quantiles = df_factors.groupby(level=0).quantile([low, high])
		col_diff = df_factors.columns.difference(df_quantiles.columns)
		if len(col_diff)>0:
			raise ValueError ('columns does not match in the result {}'.format(col_diff))

		df_quantile_low = df_quantiles.xs(low, level=1)
		df_quantile_high = df_quantiles.xs(high, level=1)
		df_quantile_low = df_quantile_low.reindex(index= df_factors.index, level= 0)
		df_quantile_high = df_quantile_high.reindex(index= df_factors.index, level= 0)

		#clip the extrame
		df_clip = df_factors.mask(df_factors>- (df_quantile_high-EPSILON), df_quantile_high)
		df_clip = df_clip.mask(df_clip <= (df_quantile_low+EPSILON), df_quantile_low)

	else:
		df_clip = df_factors

	df_mean = df_clip.groupby(level = 0).mean()
	df_sd = df_clip.groupby(level= 0).std()
	df_norm = (df_clip - df_mean)/df_sd
	df_norm = df_norm.clip(-std_cap, std_cap)/std_cap
	df_mean = df_norm.groupby(level= 0).mean()
	df_norm -=df_mean
	return df_norm

def cross_sectional_corr(df_factors, lag =1):
	factor_corr = None
	for f in df_factors:
		df_unstack = df_factors[f].unstack()
		df_unstack_shift = df_unstack.shift(lag)
		dates = df_unstack.index.unique()
		if factor_corr is None:
			factor_corr = pd.DataFrame (index = df_unstack.index)
		for date in dates:
			corr = df_unstack.loc[date].corr(df_unstack_shift.loc[date])
			factor_corr.loc[date, f] = corr

	return factor_corr

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

	def plot(self):
		self.daily_metrics['return_cumsum'].plot(figsize= (15,10))

def construct_quantile_portfolio(df, factors, quantile_low=0.1, quantile_high=0.9):
	print('constrcuting quantitle portfolio')
	df_factors = df[factors]
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
	delta = df_pf.groupby(level=0).sum()
	size = df_pf.abs().groupby(level=0).sum()

	for factor in factors:
		if (delta[factor].abs()>0.01).any():
			print(factor, 'delta not netural')
			print(delta[factor][delta[factor].abs()>0.01])
			import pdb; pdb.set_trace()

		size_check_cond = (((size[factor]-1).abs()>0.05)&(df_factors[factor].groupby(level=0).count()>5))
		if size_check_cond.any():
			print(factor, 'size not equal 1')
			print(size[factor][size_check_cond])
			import pdb; pdb.set_trace()

	return df_pf

def construct_total_portfolio(df, factors):
	print('constrcuting total portfolio')
	df_factors = df[factors]

	df_size = sum(df_factors.abs(), level=0)
	df_size_bd = df_size.reindex(index=df_factors.index, level=0)

	df_pf = df_factors/df_size_bd
	df.fillna(0, inplace=True)

	return df_pf

def generate_performance(df, df_pf, factors, return_col = 'ret', remove_beta = False, beta_col='beta', market_ret_col= 'mkt_ret', return_lag=2, tcost= None): #need to cehck
	print("generating performance")
	df_metrics = pd.DataFrame()
	daily_metrics = {}
	df_pf = df_pf.reindex(df.index)
	df_pf.fillna(0, inplace= True)
	df_trade = df_pf.groupby(level=1).diff()
	df_turnover = df_trade.abs().groupby(level=0).sum()
	daily_metrics['turnover'] = df_turnover

	if remove_beta:
		ret = shift(df[return_col] - df[beta_col].fillna(1)*df[market_ret_col], -return_lag)
	else:
		ret = shift(df[return_col], -return_lag)

	df_pf['ret'] = ret
	df_pnl = df_pf[factors].mul(df_pf['ret'], axis=0)
	if(tcost is not None):
		df_pnl -= df_trade[factors].abs()*tcost/10000

	df_return = sum(df_pnl, level=0)
	df_return_cumsum = df_return.cumsum()
	daily_metrics['return'] = df_return
	daily_metrics['return_cumsum'] = df_return_cumsum

	df_metrics['turnover'] = daily_metrics['turnover'].mean()
	df_metrics['return'] = daily_metrics['return'].sum()
	df_metrics['return_daily'] = daily_metrics['return'].mean()
	df_metrics['skew'] = daily_metrics['return'].skew()
	df_metrics['kurtosis'] = daily_metrics['return'].kurt()
	df_metrics['bps'] = df_metrics['return']/daily_metrics['turnover'].sum()*10000
	df_metrics['volatility_daily'] = daily_metrics['return'].std()
	df_metrics['volatility'] = df_metrics['volatility_daily']*15.87

	df_metrics['sharpe'] = df_metrics['return_daily']/df_metrics['volatility_daily']*15.874
	df_metrics['fitness'] = df_metrics['sharpe']*((abs(df_metrics['return'])/df_metrics['turnover'])**0.5)

	high_water = df_return_cumsum.expanding().max()
	high_water = high_water.fillna(method= 'bfill')
	i = (high_water- df_return_cumsum).idxmax()
	j = pd.Series(index = i.index)
	days_since_high_water = pd.DataFrame()
	for f in factors:
		j.loc[f] = high_water[f][:i[f]].idxmax()
		days_since_high_water[f] = high_water[f].expanding().apply(lambda x: len(x)-np.argmax(np.ma.mask_invalid(x)))
	j = j.astype('datetime64[ns]')

	df_metrics['max_underwater_duration'] = days_since_high_water.max()
	df_metrics['max_drawdown'] = (df_return_cumsum - high_water).min()
	df_metrics['max_dd_duration'] = (i-j)
	df_metrics['calmar'] = (df_metrics['return_daily']*252)/(-df_metrics['max_drawdown'])
	linear_return = pd.DataFrame(data= np.nan, index=df_return_cumsum, columns = df_return_cumsum.columns)
	linear_return.iloc[0]=0
	linear_return.iloc[-1] = df_return_cumsum.iloc[-1]
	linear_return = linear_return.interpolate()
	mse = ((df_return_cumsum - linear_return)**2).mean()**0.5
	df_metrics['linearity'] = df_metrics['return']/mse
	return df_pnl, daily_metrics, df_metrics, df_pd

def optimize_portfolio(df_pf, df, factors, beta_neutral= False, beta_col = 'beta', sector_neutral= False, sector_cols= None):
	from optimization import portfolio_optimizer as pfopt
	opt = pfopt.PortfolioOptimizer()
	opt.set_delta_constraint(0.01)
	opt.set_leverage_constraint(1)

	if beta_neutral:
		opt.set_beta_contraint(min= =-0.05, max=0.05)
		df_pf['beta'] = df[beta_col]
		df_pf['beta'].fillna(1, inplace= True)

	if sector_neutral:
		opt.set_sector_contraint(min=-0.01, max = 0.01)
		df_pf[sector_cols] = df[sector_cols]
		df_pf[sector_cols] = df_pf[sector_cols].fillna(0)

	df_pf_opt = pd.DataFrame(index = df_pf.index)
	print('optimizing the portfolio with various neutral contraint')
	for date in df_pf.index.levels[0]:
		df_pf_today = df_pf.xs(date, level=0)
		if len(df_pf_today) ==0:
			continue
		print(date)

		for factor in factors:
			for solver in ['ECOS', 'CVXOPT', 'ECOS_BB']:
				try:
					result = opt.solve(target_positions= df_pf_today[factor].values, beta= df_pf_today['beta'].vlues if beta_neutral else None, sectors = df_pf_today[sector_cols].values.T if sector_neutral else None, objective = 'min_tracking_error', solver= solver)
				except Exception as e:
					print (e)
					continue

				if result is not None:
					break
			if result is None:
				print("None result after trying all the solver")
				import pdb; pdb.set_trace()
			df_pf_opt.loc[pd.IndexSlice[date,:], factor] = result
	df_pf_opt.fillna(0, inplace= True)
	return df_pf_opt

def analyze_factors(df, factors, universe_condition, norm = True, portfolio='total',return_col = 'ret', quantile_low = 0.1, quantile_high = 0.9, sector_cols = None, sector_neutral= False, remove_beta= False, beta_col = 'beta', mkt_ret_col='mkt_ret', return_lag =2, beta_neutral=False, return_corr= False, universe_min=10, tcost=None):
	if return_col not in df:
		raise ValueError("cant find return col {}".format(return_col))

	if remove_beta:
		if beta_col not in df:
			raise ValueError("cant find beta col {}".format(beta_col))

		if mkt_ret_col not in df:
			raise ValueError("cant find mkt ret col {}".format(mkt_ret_col))

	df_universe = df.query(universe_condition)
	universe_size = df_universe.groupby(level =0).apply(len)
	universe_size_too_small = universe_size[universe_size<universe_min]

	if len(universe_size_too_small) >0:
		print(universe_size_too_small)
		raise ValueError("universe too small")

	if norm:
		df_norm = normalize_factors(df_universe, factors)
	else:
		df_norm = df_universe

	if portfolio == 'total':
		df_pf = construct_total_portfolio(df_norm, factors)
	elif portfolio == 'quantile':
		df_pf = construct_quantile_portfolio(df_norm, factors, quantile_low=quantile_low, quantile_high = quantile_high)
	else:
		raise ValueError("unknown portfolio flag: {}".format(portfolio))

	if beta_neutral or sector_neutral:
		from optimization import portfolio_optimizer as pfopt

		opt = pfopt.PortfolioOptimizer()
		opt.set_delta_constraint(0.01)
		opt.set_leverage_constraint(max = 1)
		opt.set_position_constraint(min =-0.05, max= 0.05)

		if beta_neutral:
			opt.set_beta_contraint(min=-0.05, max = 0.05)
			df_pf['beta'] = df[beta_col]
			df_pf['beta'].fillna(1, inplace=True)

		if sector_neutral:
			opt.set_sector_contraint(min=-0.01, max=0.01)
			df_pf[sector_cols]= df[sector_cols]
			df_pf[sector_cols]=df_pf[sector_cols].fillna(0)

		df_pf_opt = pd.DataFrame(index = df_pf.index)
		print('optimizing the portfolio with various neutral contraint')
		for date in df_pf.index.levels[0]:
			df_pf_today = df_pf.xs(date, level=0)
			if len(df_pf_today) ==0:
				continue
			print(date)

			for factor in factors:
				for solver in ['ECOS', 'CVXOPT', 'ECOS_BB']:
					try:
						result = opt.solve(target_positions= df_pf_today[factor].values, beta= df_pf_today['beta'].vlues if beta_neutral else None, sectors = df_pf_today[sector_cols].values.T if sector_neutral else None, objective = 'min_tracking_error', solver= solver)
					except Exception as e:
						print (e)
						continue

					if result is not None:
						break
				if result is None:
					print("None result after trying all the solver")
					import pdb; pdb.set_trace()
				df_pf_opt.loc[pd.IndexSlice[date,:], factor] = result
		df_pf = df_pf_opt.fillna(0)

	df_pnl, daily_metrics, df_metrics, df_pf = generate_performance(df, df_pf, factors, return_col = return_col, return_lag = return_log, remove_beta = remove_beta, beta_col=beta_col, mkt_ret_col = mkt_ret_col, tcost= tcost)

	df_corr = None
	if return_corr:
		df_corr = daily_metrics['return'].corr()
	result = Result()
	result.df_pf = df_pf
	result.df_norm = df_norm
	result.daily_metrics = daily_metrics
	result.performance_metrics = df_metrics
	result.df_corr = df_corr

	return result
	






