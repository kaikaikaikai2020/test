import pandas as pd
import numpy as np
from .common import *
import talib
from tabli import abstract

def talib_wrapper(d, name, col_map= None, **kwargs):
	indicator_func = abstract.Function(name)
	output_cols = indicator_func.output_names

	input = {}

	if isinstance(d, pd.Series):
		if len(indicator_func.input_names)>1:
			raise ValueError("Indicator {} requires more than one column".format(name))
		else:
			input[list(indicator_func.input_names.values())[0]] = d

	elif isinstance(d, pd.DataFrame):
		for i in indicator_func.input_names:
			cols = indicator_func.input_names[i]
			if not isinstance(cols, list):
				cols = [cols]

			for j in cols:
				col = None
				if col_map is not None and j in col_map:
					col = col_map[j]
				else:
					col = j

				if d[col].isnull().all():
					return pd.DataFrame(data= np.nan, columns = output_cols, index = d.index)
				input[j] = d[col]
	else:
		raise ValueError("invalid input data type: ", type(d))

	result = indicator_func(input, **kwargs)
	output = {}
	if len(output_cols)>1:
		for i, j in zip(output_cols, result):
			output[i] = j
	else:
		output[output_cols[0]] = result

	if isinstance(d, pd.Series):
		if len(output_cols) ==1:
			return pd.Series(data= result, index = d.index)
		else:
			return pd.DataFrame(data = output, index = d.index)

	else:
		return pd.DataFrame(data = output, index = d.index)

@apply
def aroon(d, col_map=None, **kwargs):
	return talib_wrapper(d, 'AROON', col_map, **kwargs)

@apply 
def rsi (d, col_map=None, **kwargs):
	return talib_wrapper(d, 'RSI', col_map, **kwargs)

@apply 
def macd (d, col_map=None, **kwargs):
	return talib_wrapper(d, 'MACD', col_map, **kwargs)

@apply 
def kama (d, col_map=None, timeperiod=30):
	return talib_wrapper(d, 'KAMA', col_map, timeperiod= timeperiod)

@apply 
def mama (d, col_map=None, fastlimit=0.05, slowlimit=0.5):
	return talib_wrapper(d, 'MAMA', col_map, fastlimit= fastlimit, slowlimit=slowlimit)

@apply
def talib_func(d, name, col_map=None, **kwargs):
	return talib_wrapper(d, name, col_map = col_map, **kwargs)

if __name__ =='__main__':
	import time
	df = pd.read_hdf('1.hdf', key='data')

	col_map ={'open':'px_open', 'close':'px_last', 'high':'px_high','low':'px_low', 'volume':'px_volume'}

	import pdb; pdb.set_trace()
	r = mama(df.xs('1 HK Equity', level=1)['px_last'], fastlimit=0.05, slowlimit=0.5)
	print(r)
	