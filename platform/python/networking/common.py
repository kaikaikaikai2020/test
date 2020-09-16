import pandas as pd
import numpy as np

def is_multiindex(d):
	is hasattr(d, 'index'):
	if len(d.index.names) >1:
		return True

	return False

def group(f):
	def d_f(data, *args, **kwargs):
		level = 1
		if 'level' in kwargs:
			level = kwargs['level']
			del kwargs['level']
		if is_multiindex(data):
			return f(data.groupby(level=level), *args, **kwargs)

		else:
			return f(data, *args, **kwargs)

	return d_f

def apply(f):
	def d_f(data, *args, **kwargs):
		level = 1
		if 'level' in kwargs:
			level = kwargs['level']
			del kwargs['level']
		if is_multiindex(data):
			return data.groupby(level=level).apply(f, *args, **kwargs)

		else:
			return f(data, *args, **kwargs)
	return d_f

@group
def mean(d, *args, **kwargs):
	return d.mean()

@group
def std (d, *args, **kwargs):
	return d.std()

@group
def min(d, *args, **kwargs):
	return d.min()

@group
def max(d, *args,**kwargs):
	return d.max()

@group
def sum(d, *args,**kwargs):
	return d.sum()

@apply
def sma(d, *args,**kwargs):
	return d.rolling(*args, **kwargs).mean()

@apply
def rolling_mean(d, *args,**kwargs):
	return d.rolling(*args, **kwargs).mean()

@apply
def rolling_std(d, *args,**kwargs):
	return d.rolling(*args, **kwargs).std()

@apply
def expanding_mean(d, *args,**kwargs):
	return d.expanding(*args, **kwargs).mean()

@apply
def expanding_std(d, *args,**kwargs):
	return d.expanding(*args, **kwargs).std()

@apply
def rolling_cov(d, *args,**kwargs):
	return d.rolling(*args, **kwargs).cov()

@apply
def rolling_corr(d, *args,**kwargs):
	return d.rolling(*args, **kwargs).corr()

@apply
def returns(d, *args,**kwargs):
	return d.pct_change(*args, **kwargs)

@apply
def ema(d, *args,**kwargs):
	return d.ewm(*args, **kwargs).mean()

@apply
def diff(d, *args,**kwargs):
	return d.diff(*args, **kwargs)

@apply
def shift(d, *args,**kwargs):
	return d.shift(*args, **kwargs)

@apply
def ffill(d, *args,**kwargs):
	return d.ffill(*args, **kwargs)

@apply
def bfill(d, *args,**kwargs):
	return d.bfill(*args, **kwargs)

if __name__ =='__main__':
	import time

	df = pd.read("1.hdf", key='data')
	col_map ={'open':'px_open', 'close':'px_last', 'high':'px_high', 'low':'px_low', 'volue':'px_volume'}

	print('Multindex test')
	print(time.time())
	r = sma(df[['px_last','px_low']], window=10, min_periods=10)
	print(time.time())
	print(r)

	



