import datetime
import numpy as np
from bbgapi.client import download_historical_data, download_settlement_date
from db.postgres import PostgresClient

import pandas as pd

feed_sources = {
	'JPAF': 'JP Morgan Bank',
	'BBES': 'Barclays Sgp', 
	'REGN': 'Regional BGN', 
	'BGN': 'Bloomberg BGN',
	'BNPT': 'BNP Taiwan', 
	'CMPN': 'Composite'
}

ndf_to_spot ={
	'MRN': ('MYR', ['BBES', 'BGN']),
	'KWN': ('KRW', ['JPAF','BBES', 'BGN']),
	'IHN': ('IDR', ['JPAF','BBES', 'BGN']),
	'IRN': ('INR', ['JPAF','BBES', 'BGN']),
	'PPN': ('PHP', ['JPAF','BBES', 'BGN']),
	'NTN': ('TWD', ['JPAF','BBES', 'BGN', 'BNPT']),
	'CNH': ('CNH', ['JPAF','BBES', 'BGN']),
	'CCN': ('CNY', ['JPAF','BBES', 'BGN']),
	'THB': ('THB', ['JPAF','BGN']),
	'HKD': ('PHP', ['JPAF','BGN']),
	'SGD': ('SGD', ['JPAF','BBES', 'BGN']),
	'JPY': ('JPY', ['BGN']),
	'EUR': ('EUR', ['BGN']),
	'AUD': ('AUD', ['BGN']),
	'NTO': ('TWD', ['BGN','CMPN']),
	'KWO': ('KRW', ['BGN','CMPN']),
	'KWO': ('INR', ['BGN','CMPN'])
}
fields = ['PX_MID', 'PX_LAST', 'PX_LOW', 'PX_HIGH', 'PX_OPEN', 'PX_BID', 'PX_ASK']
tenors = ['1W', '1M', '2M', '3M', '6M', '9M', '12M']

def download_forward(symbols, start_date, end_date, sources= None, settle_date_only =False, insert_db = False, insert_intraday = False, download_implied_yield = False, implied_yield_only= False,download_settle_date= True):
	standard_spots = set()
	spots = set()
	points_ids = []
	outright_ids =[]
	implied_yield_ids =[]
	standard_points_ids =[]
	standard_outright_ids =[]
	standard_implied_yield_ids =[]
	if symbols is None:
		symbols = list(ndf_to_spot.keys())
	for s in symbols:
		spot = '{} Curncy'.format(ndf_to_spot[s][0])
		standard_spots.add(spot)
		if sources is None:
			source_list = ndf_to_spot[s][1]
		else:
			source_list = source

		for f in source_list:
			spot = '{} {} Curncy'.format(ndf_to_spot[s][0], f)
			spots.add(spot)
		for t in tenors:
			points = "{}{} Curncy".format(s, t)
			implied_yield = "{} {} Curncy".format(s, t)
			outright = "{}+{} Curncy".format(s, t)
			standard_points_ids.append(points)
			standard_outright_ids.append(outright)
			standard_implied_yield_ids.append(implied_yield)
			for f in source_list:
				if f!='REGN':
					points = "{}{} {} Curncy".format(s, t,f)
					outright = "{}+{} {} Curncy".format(s, t, f)
					implied_yield = "{} {} {} Curncy".format(s, t,f)
					points_ids.append(points)
					outright_ids.append(outright)
					implied_yield_ids.append(implied_yield)

	standard_spots = list(standard_spots)
	spots = list(spots)
	standard_ids = standard_spots +standard_points_ids+standard_outright_ids
	if download_implied_yield:
		standard_ids +=standard_implied_yield_ids
	client = PostgresClient.get('Data')
	if settle_date_only:
		settle_df = download_settlement_date(standard_spots+standard_points_ids, start_date, end_date)
		dfs =[]
		for s in sources:
			settle_df['feed_sources'] = s
			dfs.append(settle_df.copy())
		settle_df = pd.concat(dfs)
		number_lines = client.insert_dataframe(settle_df, 'bbg', 'curr_asia1', if_exists = 'append', index = False, primary_keys=['date', 'description', 'feed_source'], upsert=True)
		print("{} inserted".format(number_lines))
		return True
	columns = client.query_table_columns('bbg', 'curr_asia1')
	dfs=[]
	for i in standard_ids:
		if 'HKD' in i and i not in standard_spots:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format('HKD21M Curncy'))
		elif 'THB' in i and i not in standard_spots:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format('THB21M Curncy'))
		elif 'SGD' in i and i not in standard_spots:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format('SGD21M Curncy'))
		elif 'JPY' in i and i not in standard_spots:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format('JPYDEC Curncy'))
		elif 'EUR' in i and i not in standard_spots:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format('EUR Curncy'))
			row = list(result[0])
			row[12] = 'FORWARD'
			result[0] = row
		elif 'AUD' in i and i not in standard_spots:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format('AUD Curncy'))
			row = list(result[0])
			row[12] = 'FORWARD'
			result[0] = row
		else:
			result = client.query("select * from bbg.curr_asia1 where description = '{}' order by date desc limit 1".format(i))

		if len(result)==0:
			print("None result from db query for symbol {}".format(i))
			continue
		df = pd.DataFrame.from_records(result, columns= columns)
		df['description'] =i
		dfs.append(df)
	meta_df = pd.concat(dfs)

	if implied_yield_only:
		ids = implied_yield_ids
	else:
		ids = spots + points_ids + outright_ids
		if download_implied_yield:
			ids+=implied_yield_ids
	price_df = download_historical_data(ids=ids, flds= fields, start_date=start_date, end_date=end_date)
	splits = price_df['description'].str.split(' ').str #need to check
	standard_id = splits[0] +' Curncy'
	price_df['description'] = standard_id
	price_df['feed_source'] = splits[1]

	price_df = price_df.set_index(['date', 'description', 'feed_source'])
	price_df = price_df.sort_index()
	if 'BBES' in price_df.index.levels[2].unique():
		for tenor in tenors:
			for field in fields:
				if 'NTN' in symbols:
					if pd.Timestamp('20161121')<= price_df.index.levels[0][0]:
						price_df.loc[pd.IndexSlice[slice(None), 'NTN'+tenor+' Curncy', 'BBES'], field]/= 1000.0
					else:
						price_df.loc[pd.IndexSlice['20161121':, 'NTN'+tenor+' Curncy', 'BBES'], field]/= 1000.0
				if 'CNH' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'CNH'+tenor+' Curncy', 'BBES'], field]/= 10000.0
				if 'SGD' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'SGD'+tenor+' Curncy', 'BBES'], field]/= 10000.0

	if 'JPAF' in price_df.index.levels[2].unique():
		start = pd.Timestamp('20120717')
		end= pd.Timestamp('2014-516')
		days_to_adjust = []
		for d in price_df.index.levels[0].unique():
			if d<start or d>end:
				days_to_adjust.append(d)

		for tenor in tenors:
			for field in fields:
				if 'CNH' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'CNH'+tenor+' Curncy', 'JPAF'], field]/= 10000.0
				if 'CCN' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'CCN'+tenor+' Curncy', 'JPAF'], field]/= 10000.0

				if 'IRN' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'IRN'+tenor+' Curncy', 'JPAF'], field]/= 100.0
				if 'THB' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'THB'+tenor+' Curncy', 'JPAF'], field]/= 100.0
				if 'HKD' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'HKD'+tenor+' Curncy', 'JPAF'], field]/= 10000.0

				if 'NTN' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'NTN'+tenor+' Curncy', 'JPAF'], field]/= 1000.0
				if 'KWN' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'KWN'+tenor+' Curncy', 'JPAF'], field]/= 100.0

				if 'PPN' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'PPN'+tenor+' Curncy', 'JPAF'], field]/= 100.0
				if 'SGD' +tenor+' Curncy' in price_df.index.leves[1]:
					price_df.loc[pd.IndexSlice[slice(None), 'SGD'+tenor+' Curncy', 'JPAF'], field]/= 10000.0

	if 'BGN' in price_df.index.levels[2].unique():
		for tenor in tenors:
			for field in fields:
				if 'JPY' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'JPY'+tenor+' Curncy', 'BGN'], field]/= 100.0
				if 'EUR' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'EUR'+tenor+' Curncy', 'BGN'], field]/= 10000.0
				if 'AUD' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'AUD'+tenor+' Curncy', 'BGN'], field]/= 10000.0
				if 'THB' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'THB'+tenor+' Curncy', 'BGN'], field]/= 100.0
				if 'IRO' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'IRO'+tenor+' Curncy', 'BGN'], field]/= 100.0

	if 'CMPN' in price_df.index.levels[2].unique():
		for tenor in tenors:
			for field in fields:
				if 'IRO' in symbols:
					price_df.loc[pd.IndexSlice[slice(None), 'IRO'+tenor+' Curncy', 'CMPN'], field]/= 100.0

	price_df = price_df.unstack(level=(1,2))
	for p, o in zip(standard_points_ids, standard_outright_ids):
		spot = ndf_to_spot[p[:3]][0] + ' Curncy'
		if sources is None:
			source_list = ndf_to_spot[p[:3]][1]
		else:
			source_list = sources
		for s in source_list:
			if s not in price_df.columns.levels[2].unique():
				continue
			for f in fields:
				if (f, p, s) in price_df and (f, o, s) not in price_df:
					print("fill {} {} {}".format(f,o, s))

					if f== 'PX_BID' or f=='PX_ASK':
						if ('PX_MID', spot, s) in price_df:
							price_df.loc[:, (f,o,s)]=price_df.loc[:, (f,p,s)]+price_df.loc[:,('PX_BID', spot, s)]
					else:
						if (f, spot, s) in price_df:
							price_df.loc[:, (f,o,s)]=price_df.loc[:, (f,p,s)]+price_df.loc[:,(f, spot, s)]
				elif (f, p, s) not in price_df and (f, o, s) in price_df:
					print("fill {} {} {}".format(f,p, s))

					if f== 'PX_BID' or f=='PX_ASK':
						if ('PX_MID', spot, s) in price_df:
							price_df.loc[:, (f,p,s)]=price_df.loc[:, (f,o,s)]+price_df.loc[:,('PX_BID', spot, s)]
					else:
						if (f, spot, s) in price_df:
							price_df.loc[:, (f,p,s)]=price_df.loc[:, (f,o,s)]+price_df.loc[:,(f, spot, s)]


	price_df = price_df.stack('description').stack('feed_source')
	price_df.reset_index(inplace=True)
	price_df['pricing_source'] = price_df['feed_source'].map(feed_source)
	new_cols = [c.lower() for c in price_df.columns]
	price_df.columns = new_cols
	final_df = price_df.merge(meta_df, how='left', left_on='description', right_on= 'description', suffixes= ('', '_meta'))
	col_to_drop =[]
	for c in final_df.columns:
		if '_meta' in c:
			col_to_drop.append(c)

	final_df = final_df.drop(col_to_drop, axis=1)
	final_df['last_update'] = datetime.datetime.now()
	final_df['last_update_dt'] = datetime.datetime.combine(datetime.date.today(), datetime.datetime.min.time())
	final_df = final_df.drop(['settle_date', 'days_to_mty'], axis=1)

	if download_settlement_date:
		settle_df = download_settlement_date(standard_spots+standard_points_ids, start_date, end_date)
		outright_settle_df = settle_df[settle_df['description'].isin(standard_points_ids)].copy()
		root = outright_settle_df['description'].str[0:3]
		suffix = outright_settle_df['description'].str[3:]
		outright_settle_df['description']= root +'+'+suffix
		settle_df = settle_df.append(outright_settle_df)
		final_df = final_df.merge(settle_df, left_on = ['date', 'description'], right_on=['date', 'description'], how='left')

	if insert_db:
		number_lines = client.insert_dataframe (final_df, 'bbg', 'curr_asia1', if_exists='append', index=False, primary_keys=['date','description','feed_source'], upsert = True)

		if insert_intraday:
			final_df['timestamp'] = datetime.datetime.now()
			number_lines = client.insert_dataframe(final_df, 'bbg', 'curr_intraday', if_exists='append', index=False)
		print(number_lines, 'inserted')
	else:
		return final_df
if __name__=='__main__':
	import pytz
	start_date = '20180101'
	end_date = datetime.datetime.now().strftime('%Y%m%d')
	download_forward(['IRO'],'20080101', '20091231', sources=['BGN'], settle_date_only=False, insert_db = True)


