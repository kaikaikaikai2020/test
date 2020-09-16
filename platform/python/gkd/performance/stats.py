import pandas as pd
import numpy as np
def generate_stat (df, start_date = None, gmv= None):
	df_stat = pd.DataFrame()
	last_date = df.index[-1]

	if start_date is not None:
		df = df.loc[start_date:].copy()
	else:
		df = df.copy()

	df_stat['Annual Pnl'] = df.mean()*240
	if gmv is not None:
		df_stat['Annual Return(bps)']  = df_stat['Annual Pnl'].div(gmv, axis= 0)*10000
	df_stat['Volatility'] = df.std()
	df_stat['Downside Volatility'] = df[df<0].std()
	df_stat['Sharpe'] = df.mean()/df.std()*15.5
	df_stat['Sortino'] = df.mean()/df_stat['Downside Volatility']*15.5

	df_rolling_mean_240 = df.rolling(window=240, min_period=240).mean()
	df_rolling_std_240 = df.rolling(window=240, min_period=240).std()
	df_rolling_mean_120 = df.rolling(window=120, min_period =120).mean()
	df_rolling_std_120 = df.rolling(window=120, min_period=120).std()

	df_rolling_sharpe_240 = df_rolling_mean_240/df_rolling_std_240 *15.5
	df_rolling_sharpe_120 = df_rolling_mean_120/df_rolling_std_120 *15.5
	df_stat['Sharpe Max 12M'] = df.df_rolling_sharpe_240.max()
	df_stat['Sharpe Min 12M'] = df.df_rolling_sharpe_240.min()
	df_stat['Sharpe Max 6M'] = df.df_rolling_sharpe_120.max()
	df_stat['Sharpe Min 6M'] = df.df_rolling_sharpe_120.min()

	for col in df:
		dd_table = pd.timeseries.gen_drawdown_table(df[col]/gmv[col])
		dd_table['Duration'].fillna((last_date - dd_table['Peak date']).dt.days, inplace=True)
		df_stat.loc[col, 'Max DD'] = dd_table['Net drawdown in %'].iloc[0]*gmv[col]
		df_stat.loc[col, 'Max DD(bps)'] = df_stat.loc[col, 'Max DD']/gmv[col] *100
		df_stat.loc[col, 'Max Underwater Duration'] = dd_table['Duration'].max()
		df_stat.loc[col, 'Calmar'] = df_stat.loc[col,'Annual Pnl'] /df_stat.loc[col, 'Max DD']*100
		df_stat.loc[col, 'Calmax'] = df_stat.loc[col,'Annual Pnl']/(dd_table.iloc[:5]['Net drawdown in %'].mean()/100*gmv[col]*1.5)

	return df_stat

	