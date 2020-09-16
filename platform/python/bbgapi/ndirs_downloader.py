import datetime
import numpy as np
from bbgapi.client import download_historical_data, download_settlement_date, download_symbols_fields
from db.postgres import PostgresClient
import pandas as pd
from datasets.bloomberg.data_source import BBGIPXDataSource
tenors = ['F', 'I', '1','1F', '2','3','4','5','6','7','8','9','10','12', '15','20']
root_map = {
	'KWSWNI': ['KRW', 'KWCDC Curncy', tenors],
	'TDSWNI': ['TWD', 'TAIBOR3M Index', tenors],
	'IRSWNI': ['INR', 'IN00O/N Index', tenors],
	'TBSWNI': ['THB', 'THFX6M Index', tenors],
	'USSW': ['USD', 'US0003M Index', tenors],
	'EUSA': ['EUR', 'EUR006M Index', tenors],
	'JYSW': ['JPY', 'JY0006M Index', tenors],
	'CCSWNI': ['CNY', 'CNRR007 Index', tenors],
	'USSO': ['USD', 'US0003M Index', ['F','1']],
}

fields = ['PX_MID','PX_LAST','PX_LOW','PX_HIGH','PX_OPEN','PX_BID','PX_ASK']
def download_ndirs_float(symobols = None, start_date = None, end_date=None, insert_db = False):
	fields= ['PX_MID','PX_LAST','PX_LOW','PX_HIGH','PX_OPEN']
	if symbols is None:
		symbols = list(root_map.keys())
	ids = []
	for s in symbols:
		float_leg = root_map[s][1]
		if 'Index' in float_leg:
			ids.append(float_leg)

	client = PostgresClient.get('Data')
	columns = client.query_table_columns('bbg', 'ipx_2018')
	price_df = download_historical_data(ids=ids, flds = fields, start_date= start_date, end_date = end_date)

	other_fields=[]
	columns.remove('date')
	columns.remove('description')
	for c in columns:
		if c.upper() not in fields:
			other_fields.append(c.upper())

	ref_df = download_symbols_fields(ids=ids, flds=other_fields)
	ref_df.columns = [c.lower() for c in ref_df.columns]
	ref_df['dvd_ex_dt'] = pd.to_datetime(ref_df['dvd_ex_dt'])
	ref_df['px_close_dt'] = pd.to_datetime(ref_df['px_close_dt'])
	ref_df['last_update'] = pd.Timestamp.now()
	ref_df['last_update_dt_exch_tz'] = pd.to_datetime(ref_df['last_update_dt_exch_tz'])
	ref_df['high_dt_52week'] = pd.to_datetime(ref_df['high_dt_52week'])
	ref_df['low_dt_52week'] = pd.to_datetime(ref_df['low_dt_52week'])
	ref_df['px_close_dt'] = pd.to_datetime(ref_df['px_close_dt'])
	ref_df['prev_bus_trr_dt'] = pd.to_datetime(ref_df['prev_bus_trr_dt'])
	ref_df['region'] = 'custom'

	df = price_df.merge(ref_df, on='description', how='left', suffixes = ('','_dup'))
	col_to_drop =[]
	for c in df.columns:
		if '_dup' in c:
			col_to_drop.append(c)
	final_df = df.drop(col_to_drop, axis=1)

	if insert_db:
		ds = BBGIPXDataSource()
		number_lines = ds.append(final_df)
		print(number_lines, ' inserted')
	else:
		return final_df

def download_ndirs(symbols = None, tenors= None, start_date= None, end_date= None, insert_db = False, insert_intraday= True, float_only= False, download_settle_date = False):
	if symbols is None:
		symbols = list(root_map.keys())

	standard_ids =[]
	for s in symbols:
		float_leg = root_map[s][1]
		if 'Curncy' in float_leg:
			standard_ids.append(float_leg)
		if float_only:
			continue
		for t in tenors if tenors is not None else root_map[s][2]:
			standard_ids.append(s+t+' Curncy')

	client = PostgresClient.get('Data')
	columns = client.query_table_columns('bbg', 'curr_asia1')

	ids = []
	for s in standard_ids:
		if 'Curncy' in s:
			ids.append(s.split(' ')[0]+ ' CMPN '+s.split(' ')[1])

	price_df = download_historical_data(ids=ids, flds=fields, start_date = start_date, end_date= end_date)

	other_fields = []
	columns.remove('date')
	columns.remove('description')
	columns.remove('region')
	columns.remove('last_update')
	columns.remove('last_update_dt')
	columns.remove('settle_date')
	columns.remove('days_to_mty')
	columns.remove('update_timestamp')

	for c in columns:
		if c.upper() not in fields:
			other_fields.append(c.upper())

	ref_df = download_symbols_fields(ids=ids, flds=other_fields)

	df = price_df.merge(ref_df, on='description', how='left', suffixes=('', '_dup'))
	splits = df['description'].str.split(' ').str
	standard_id = splits[0] +' Curncy'
	df['description'] = standard_id
	col_to_drop = []
	for c in df.columns:
		if '_dup' in c:
			col_to_drop.append(c)

	final_df = df.drop(col_to_drop,axis = 1)
	final_df['last_update']= datetime.datetime.now()
	final_df['last_update_dt'] = datetime.datetime.combine(datetime.date.today(), datetime.datetime.min.time())
	final_df['region'] = 'asia1'

	if download_settle_date:
		settle_df = download_settlement_date(standard_ids, start_date, end_date)
		final_df = final_df.merge(settle_df, left_on= ['date', 'description'], right_on=['date','description'], how='left')

	if insert_db:
		number_lines = client.insert_dataframe(final_df, 'bbg', 'curr_asia1', if_exists = 'append', index = False, primary_keys= ['date','description','feed_source'], upsert = True)

		if insert_intraday:
			final_df['timestamp'] = datetime.datetime.now()
			number_lines = client.insert_dataframe(final_df, 'bbg', 'curr_intraday', if_exists= 'append', index= False)

		print(number_lines, ' inserted')
	else:
		return final_df

if __name__ = '__main__':
	download_ndirs(symbols=['USSO'], tenors = None, start_date = '20190724', end_date= '20190808', insert_db = True, float_only = False)
	
