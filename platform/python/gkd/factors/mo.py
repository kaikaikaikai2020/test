import pandas as pd
import numpy as np

from operators.common import sma, ema, shift
def mo_1 (df, price_col = 'close', ret_col ='ret', cap_col = 'lncap'):
	if price_col not in df:
		raise ValueError('price_col {} not found in the data'.format(price_col))

	windows = [3,5,10,20,50,100,200]

	for window in windows:
		df['price_ma_{}'.format(window)] = sma(df[price_col], window = window, min_period= window)
		df['price_ma_{}_%'.format(window)] = df['price_ma_{}'.format(window)]/df[price_col]

	ret_windows = [2,5,10,20]
	for win in ret_windows:
		df['ret_ma_{}'.format(win)] = sma(df[ret_col],window = win, min_period= win)
		df['ret_ma_{}_next'.format(win)] = shift(df[ret_col], period = -win)

	df['ret_next'] = shift(df[ret_col], period=-1)

	df['ret_252'] = df[price_col].groupby(level=1).pct_change(periods=252)
	df['ret_22'] = df[price_col].groupby(level=1).pct_change(periods=22)
	df['ret_252_22'] = df['ret_252'] = df['ret_22']

def generate_price_ma(df, price_col='close', windows = [3,5,10,20,100,200]):
	cols = []
	for window in windows:
		df['price_ma_{}'.format(window)] = sma(df[price_col], window= window, min_period= window)
		cols.append('price_ma_{}_diff'.format(window))

def generate_price_ma_diff(df, price_col='close', price_ma_cols):
	cols = []
	for ma_col in price_ma_cols:
		df[price_col]/df[col]-1

