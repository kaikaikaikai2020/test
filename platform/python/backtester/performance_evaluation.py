import pandas as pd
import numpy as np
from utils.epsilon import equal_zero

from loader.data_loader import DataLoader

def generate_performance_from_trades(trades, universe, symbology= 'bbgid', instrument_data=None):
	dates = trades.index.levels[0]
	start_date = dates.min()
	end_date = dates.max()

	if instrument_data is not None:
		loader = DataLoader()
		data = loader.load(datasets = {'main':'dataset.price.px'}, universe= universe, symbology= symbology, start_date=start_date, end_date=end_date)
		instrument_data = data.dfs['main']

def generate_max_dd(ts):
	result={}
	cum_pnl = ts.cumsum()
	high_water = cum_pnl.expanding().max()
	high_water = high_water.fillna(method='bfill')
	i = np.argmax(high_water - cum_pnl)
	j = np.argmax(high_water[:i])
	days_since_high_water = high_water.expanding().apply(lambda x:len(x)-np.argmax(np.ma.masked_invalid(x)))
	if np.isnan(np.max(days_since_high_water)):
		result['max_underwater_duration']=np.nan
	else:
		result['max_underwater_end_date'] = days_since_high_water.idmax()
		result['max_underwater_begin_date'] = days_since_high_water.loc[:result['max_underwater_end_date']].iloc[::-1].idxmin()
		result['max_underwater_duration'] = (result['max_underwater_end_date'] - result['max_underwater_begin_date']).days
	result['max_drawdown'] = (cum_pnl-high_water).min()

	if (not isinstance(i, pd.Timestamp)) or (not isinstance(j, pd.Timestamp)):
		result['max_dd_duration'] = np.nan
	else:
		result['max_dd_duration'] = (i-j).days
		result['max_dd_begin_date']=j
		result['max_dd_end_date'] = i
	return result