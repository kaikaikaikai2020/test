from algorithm.algorithm import Algorithm
from algorithm.api import (order, order_target, order_target_value, add_pipeline, get_alg_params, get_logger, get_logger, get_current_date, get_trade_date)
from utils.dotdict import dotdict
from operators.common import sma, ema, mean, diff, shift, rolling_sum, rolling_std, std, rolling_cov
from operators.indicator import kama, mama
from optimization.portfolio_optimizer import PortfolioOptimizer
from utils.number import int_max, int_min, is_number
from utils.epsilon import equal_zero, EPSILON
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import scale
from scipy.stats import norm
import datetime

import pandas as pd
import numpy as np
import math
import pytz

logger = get_logger('Algorithm')

def prepare_optimization_input(input_df, current_df):
	params = get_alg_params()
	pf_size = params.opt.portfolio_size
	trade_limit = current_df['adv']*params.opt.max_trade_adv_pct /pf_size
	position_limit = current_df['adv'] *params.opt.max_weight_adv_pct /pf_size
	input_df['trade_min'] = -trade_limit
	input_df['trade_max'] = trade_limit
	input_df['trade_min'] = input_df['trade_min'].where(input_df['tradable'],0)
	input_df['trade_max'] = input_df['trade_max'].where(input_df['tradable'],0)

	input_df['pos_cons'] = position_limit
	pos_limit_per_portfolio = params.opt.max_weight_pct
	input_df['pos_cons'] = input_df['pos_cons'].where(input_df['pos_cons']<pos_limit_per_portfolio, pos_limit_per_portfolio)
	input_df['pos_cons'] = input_df['pos_cons'].where(current_df[params.alpha.index]>0,0)
	input_df['size_overflow_long'] = (input_df['init_pos'] - input_df['pos_cons']).clip(lower= 0)
	input_df['size_overflow_short'] = (input_df['init_pos'] - input_df['pos_cons']).clip(upper= 0)
	input_df.loc[input_df['tradable'], 'trade_min'] = input_df['trade_min'].clip(upper = -input_df['size_overflow_long'])
	input_df.loc[input_df['tradable'], 'trade_max'] = input_df['trade_max'].clip(lower = -input_df['size_overflow_short'])
	input_df.loc[~input_df['tradable'], 'pos_cons'] = input['init_pos'].abs()
	input_df['target_pos'] = input_df['alpha']*input_df['pos_cons']

def generate_alpha(data):
	main_data = data['main']
	params = get_alg_params()
	main_data['close_ema'] = ema(main_data['close_adj'], halflife= params.alpha.ema_hl, min_periods = params.alpha.ema_hl)
	main_data['reversion'] = main_data['close_adj'] - main_data['close_ema']
	main_data['universe'] = (main_data[params.alpha.index]>0)

	m = mean(main_data.loc[main_data['universe'],'reversion'], level= 0)
	s = std(main_data.loc[main_data['universe'], 'reversion'], level=0)
	norm = (main_data['reversion'] -m)/s
	main_data['alpha'] = -norm.clip(-2.0,2.0)/2
	main_data['alpha'].fillna(0, inplace = True)

	return main_data[['universe','close_ema', 'reversion', 'alpha']]

def generate_cov(data):
	main_data = data['main']
	main_data = main_data[main_data['product'] == 'stock']
	close_unstack = main_data['close_adj'].unstack()
	ret_unstack = close_unstack.ffill().pct_change().fillna(0)

	cov = ret_unstack.rolling(120).cov()
	cov = cov.groupby(level=1).ffill()

	cov_ema = ema(cov, halflife =4, min_periods = 4)
	return cov_ema

def init(context):
	params = get_alg_params()
	opt = PortfolioOptimizer()
	opt.set_delta_contraint(0)
	opt.set_leverage_contraint(max=1)
	opt.set_trade_total_contraint(params.opt.max_total_trade_pct)
	context.opt = opt
	add_pipeline('alpha', generate_alpha)
	add_pipeline('cov', generate_cov)

def handle_data(context, data):
	params = get_alg_params()
	pf_size = params.opt.portfolio_size
	main_data = data.current()

	if main_data is None:
		logger.error("None main current")
		return True

	alpha_data = data.get_data('alpha').current()
	stat_data = data.get_data('instrument_stat').current()
	cov_raw = data.get_data('cov').current()
	universe_mask = (main_data['product']=='stock')
	main_data = main_data[universe_mask]
	main_data = main_data.reset_index().set_index('bbgid')
	if len(main_data) == 0:
		return True

	input_df = pd.DataFrame(index= main_data.index)
	input_df['alpha'] = alpha_data['alpha']
	input_df['tradable'] = main_data['tradable']
	input_df['close'] = main_data['close']
	input_df['init_pos'] = (stat_data['sod_pos']*input_df['close']/pf_size).fillna(0)
	logger.info('preparing optimization input')
	prepare_optimization_input(input_df, main_data)
	cov = None
	if len(input_df[input_df['tradable']])==0:
		logger.info("nothing tradable skip optimization")
		return True

	input_df = input_df[(input_df['init_pos'].abs()>0.001)|(input_df['alpha'].abs()>0.01)]
	input_df - input_df.dropna(subset= ['alpha', 'trade_max','trade_min', 'pos_cons', 'init_pos'])

	if len(input_df)==0:
		logger.info("nothing to optimize skip")
		return True

	opt = context.opt
	opt.set_position_constraint(min= -input_df['pos_cons'].values, max= input_df['pos_cons'].values)
	opt.set_trade_constraint(min= input_df['trade_min'].values, max= input_df['trade_max'].values)
	logger.info("running optimization")
	logger.info("{}  names to optimization ".format(len(input_df)))

	result = None

	try:
		result = opt.solve(input_df['init_pos'].values, alpha = input_df['alpha'].values, target_position = input_df['target_pos'].values, cov= cov, objective= params.opt.get('objective', 'max_mean_var'), solver = 'ECOS')
	except Exception as e :
		print(e)

	if result is None:
		logger.error("None optimzation result")
		import pdb; pdb.set_trace()
		return True
	input_df['result_target'] = result
	input_df['target_value'] = input_df['result_target'] * pf_size
	logger.info("sending order")
	for sym in input_df.index:
		if pd.isnull(input_df.loc[sym, 'target_value']):
			import pdb; pdb.set_trace()
		order_target_value(sym, input_df.loc[sym, 'target_value'])

alg = Algorithm(init= init, handle_data = handle_data, name='StarArb')

alg_params_default ={
	
	'opt': {
	'objective': 'min_tracking_error',
	'portfolio_size':20000000,
	'max_weight_pct':0.1,
	'max_weight_adv_pct': 0.1,
	'max_trade_adv_pct': 0.02,
	'max_total_trade_pct': 0.2

	}
}

