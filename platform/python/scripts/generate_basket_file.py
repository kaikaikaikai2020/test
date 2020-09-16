import os
import pandas as pd
import numpy as np
from datasets.impact.data_source import FutureSessionDataSource, EquityListingDataSource
def generate_us_stock_file(source_file, target_file, book, micro, destination = None, comment = None):
	src_df = pd.read_csv(source_file)
	current_time = pd.Timestamp.now()
	src_df = src_df[src_df['product']=='stock']

	if len(src_df) == 0:
		return
	split_str = src_df['symbol'].str.split(' ').str
	src_df['mkt'] = split_str[1]
	src_df['SYMBOL'] = split_str[0]
	src_df = src_df[src_df['mkt']=='US']

	if len(src_df) ==0:
		return 

	src_df['timestamp'] = pd.to_datetime(src_df['timestamp'])
	last_timestamp= src_df['timestamp'].max()
	src_df = src_df[(last_timestamp = src_df['timestamp']) <pd.Timedelta(minutes = 1)]
	src_df.drop_duplicates(subset= ['SYMBOL'], keep='last', inplace= True)
	src_df['LIST NAME'] = "{}-{}-{}".format(book, micro, current_time.strftime('%Y%m%d_%H%M%S'))
	src_df.loc[src_df['qty']<0, 'SIDE'] = 'SELL'
	src_df.loc[src_df['qty']>0, 'SIDE'] = 'BUY'
	src_df['ACCOUNT'] = book +'/'+micro
	src_df['LIMIT'] = src_df['price']
	src_df.loc[src_df['algo']=='close', 'LIMIT'] = 'MOC'
	src_df['LIMIT'].fillna('MKT', inplace=True)
	src_df['SHARES'] = src_df['qty']
	src_df['DESTINATION'] = 'USDESK'
	src_df.loc[src_df['algo']=='close', 'algo'] = None
	src_df['algo'] = src_df['algo'].str.upper()

	alg_mask = pd.notnull(src_df['algo'])
	src_df['start'] = np.nan
	src_df['end'] = np.nan
	src_df['max % vol']= np.nan

	src_df.loc[alg_mask, 'start']= src_df['start_time']
	src_df.loc[alg_mask,'exp'] = src_df['end_time']
	src_df.loc[alg_mask, 'max % vol']= src_df['max_vol'].astype(float, errors='ignore').replace('None', 0.05)*100

	src_df['comment'] = comment

	des_df = src_df[['LIST NAME', 'SIDE', 'SYMBOL', 'ACCOUNT', 'LIMIT', 'SHARES','DESTINATION', 'algo', 'start', 'exp', 'max % vol','comment']]
	des_df.to_csv(target_file, index = False)

def generate_int_stock_file(source_file, target_file, book, micro, limit='MKT', destination = None):
	src_df = pd.read_csv(source_file)
	current_time = pd.Timestamp.now()
	src_df = src_df[src_df['product']=='stock']
	if len(src_df) ==0:
		return 

	split_str = src_df['symbol'].str.split(' ').str
	src_df['mkt'] = split_str[1]
	src_df = src_df[src_df['mkt']=='US']

	if len(src_df) ==0:
		return 
	src_df['timestamp'] = pd.to_datetime(src_df['timestamp'])
	last_timestamp= src_df['timestamp'].max()
	src_df = src_df[(last_timestamp = src_df['timestamp']) <pd.Timedelta(minutes = 1)]

	ds = EquityListingDataSource()
	symbols = src_df['symbol'].unique()
	df = ds.get(symbols=symbols, symbol_col = 'bloomberg_key', cols=['bloomberg_key', 'ric'])
	src_df = src_df.merge(df, left_on= 'symbol', right_on='bloomberg_key', how='left')
	src_df['SYMBOL'] = src_df['ric']
	src_df.drop_duplicates(subset=['SYMBOL'],keep='last', inplace=True )
	src_df['LIST NAME'] = "{}-{}-{}".format(book, micro, current_time.strftime('%Y%m%d_%H%M%S'))
	src_df.loc[src_df['qty']<0, 'SIDE'] = 'SELL'
	src_df.loc[src_df['qty']>0, 'SIDE'] = 'BUY'
	src_df['ACCOUNT'] = book +'/'+micro
	src_df['LIMIT'] = src_df['price'].replace(('None','close','vwap'), np.nan).fillna(limit)
	src_df['SHARES'] = src_df['qty']
	src_df['DESTINATION'] = 'JPM ASIA ALGO'

	des_df = src_df[['LIST NAME', 'SIDE', 'SYMBOL', 'ACCOUNT', 'LIMIT', 'SHARES','DESTINATION']]
	des_df.to_csv(target_file, index = False)

def generate_us_future_file(source_file, target_file, book, micro, limit='MKT', destination= None):
	src_df = pd.read_csv(source_file)
	current_time = pd.Timestamp.now()
	src_df = src_df[src_df['product']=='future']

	if len(src_df) == 0:
		return
	src_df = src_df[~src_df['symbol'].str.contain('=')]
	if len(src_df) ==0:
		return

	src_df['timestamp'] = pd.to_datetime(src_df['timestamp'])
	last_timestamp= src_df['timestamp'].max()
	src_df = src_df[(last_timestamp = src_df['timestamp']) <pd.Timedelta(minutes = 1)]

	ds = FutureSessionDataSource()
	symbols = src_df['symbol'].unique()
	df = ds.get(symbols=symbols, symbol_col = 'bloomberg_key', cols=['bloomberg_key', 'ric'])
	src_df = src_df.merge(df, left_on= 'symbol', right_on='bloomberg_key', how='left')
	src_df['SYMBOL'] = src_df['ric']
	src_df.drop_duplicates(subset=['SYMBOL'],keep='last', inplace=True )

	src_df['LIST NAME'] = "{}-{}-{}".format(book, micro, current_time.strftime('%Y%m%d_%H%M%S'))
	src_df.loc[src_df['qty']<0, 'SIDE'] = 'SELL'
	src_df.loc[src_df['qty']>0, 'SIDE'] = 'BUY'
	src_df['ACCOUNT'] = book +'/'+micro
	src_df['LIMIT'] = src_df['price'].replace(('None','close','vwap'), np.nan).fillna(limit)
	src_df['SHARES'] = src_df['qty']
	src_df['DESTINATION'] = 'USDESK'
	src_df.loc[src_df['price']=='vwap', 'DESTINATION'] = 'USDESK VWAP'
	des_df = src_df[['LIST NAME', 'SIDE', 'SYMBOL', 'ACCOUNT', 'LIMIT', 'SHARES','DESTINATION']]
	des_df.to_csv(target_file, index = False)

def generate_in_ssf_file(source_file, target_file, book, micro, limit='MKT', destination= 'Voice'):
	src_df = pd.read_csv(source_file)
	current_time = pd.Timestamp.now()
	src_df = src_df[src_df['product']=='future']

	if len(src_df) == 0:
		return
	
	split_str = src_df['symbol'].str.split(' ').str
	src_df['mkt'] = split_str[1]
	src_df = src_df[src_df['mkt']=='IS']	

	if len(src_df) == 0:
		return

	src_df['timestamp'] = pd.to_datetime(src_df['timestamp'])
	last_timestamp= src_df['timestamp'].max()
	src_df = src_df[(last_timestamp = src_df['timestamp']) <pd.Timedelta(minutes = 1)]

	ds = FutureSessionDataSource()
	symbols = src_df['symbol'].unique()
	df = ds.get(symbols=symbols, symbol_col = 'bloomberg_key', cols=['bloomberg_key', 'ric'])
	src_df = src_df.merge(df, left_on= 'symbol', right_on='bloomberg_key', how='left')
	src_df['SYMBOL'] = src_df['ric']
	src_df.loc[src_df['qty']<0, 'SIDE'] = 'SELL'
	src_df.loc[src_df['qty']>0, 'SIDE'] = 'BUY'
	src_df['ACCOUNT'] = book
	src_df['Micro'] = micro
	src_df['LIMIT'] = src_df['price'].replace(('None','close','vwap'), np.nan).fillna(limit)
	src_df['SHARES'] = src_df['qty'].abs()
	src_df['DESTINATION'] = destination
	des_df = src_df[['LIST NAME', 'SIDE', 'SYMBOL', 'ACCOUNT', 'LIMIT', 'SHARES','DESTINATION','Micro']]
	des_df.to_csv(target_file, index = False)
