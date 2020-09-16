import pandas as pd
import datetime
import os
from .client import download_index_composition, download_symbols_fields

def generate_dip(indices):
	latest_date = None
	indices = [i +' Index' for i in indices]
	today = datetime.datetime.now()
	for date in pd.bdate_range(datetime.datetime(2017,1,1), today)[::-1]:
		file_path_apac = os.path.join('X:\\', 'Markit', 'DividendForest', '%s', '%s', '%s', 'MRKT_Div_StockLevel_APAC_%s.zip')%(date.year, str(date.month).zfill(2), str(date.day).zfill(2), date.strftime('%Y%m%d'))
		if os.path.isfile(file_path_apac):
			latest_date = date
			print('Using dividend data from: %s' % date.strftime('%Y-%m-%d'))
			break

	if latest_date is None:
		raise ValueError('No data found')

	print("reading the file ", file_path_apac)
	data_apac = pd.read_csv(file_path_apac, sep = '\t', compression='zip')
	file_path_emea = os.path.join('X:\\', 'Markit', 'DividendForest', '%s', '%s', '%s', 'MRKT_Div_StockLevel_EMEA_%s.zip')%(date.year, str(date.month).zfill(2), str(date.day).zfill(2), date.strftime('%Y%m%d'))
	print("reading the file", file_path_emea)
	data_emea = pd.read_csv(file_path_emea, sep = '\t', compression='zip')
	file_path_amer = os.path.join('X:\\', 'Markit', 'DividendForest', '%s', '%s', '%s', 'MRKT_Div_StockLevel_Amer_%s.zip')%(date.year, str(date.month).zfill(2), str(date.day).zfill(2), date.strftime('%Y%m%d'))
	print("reading the file ", file_path_amer)
	data_amer = pd.read_csv(file_path_amer, sep = '\t', compression='zip')
	data = pd.concat([data_apac, data_emea, data_amer])

	for col in ['DataDate', 'ExDividendDate']:
		data[col] = pd.to_datetime(data[col], format = '%Y-%m-%d')

	data = data[data['ExDividendDate']>today]
	idx_con = download_index_composition(indices, today.strftime('%Y%m%d'))

	idx_con['description'] +=' Equity'
	names = idx_con['description'].unique()

	isins = download_symbols_fields(names, ['ID_ISIN', 'CRNCY'])
	isins = isins.rename(columns= {'ID_ISIN':'ISIN'})
	idx_div = download_symbols_fields(indices, ['INDX_DIVISOR'])
	idx_div = idx_div.rename(columns ={'description': 'index'})
	idx_con = idx_con.merge(isins, left_on='description', right_on='description')
	idx_con = idx_con.rename ({'description':'con'})
	idx_data = idx_con.merge (data, left_on = 'ISIN', right_on= 'ISIN')
	idx_data = idx_data.merge(idx_div, left_on= 'index', right_on = 'index')
	idx_data = idx_data.rename(columns = {'CRNCY': 'px_cur', 'DividendCCY':'dvd_cur'})
	idx_data['dvd_cur'] += ' Curncy'
	idx_data['px_cur'] += ' Curncy'

	currencies = set()
	currencies |= set(idx_data['dvd_cur'].unique().tolist())
	currencies |= set(idx_data['px_cur'].unique().tolist())

	fx = download_symbols_fields(currencies, 'PX_LAST')
	fx = fx.rename (columns= {'description':'cur', 'PX_LAST':'spot'})

	idx_data = idx_data.merge(fx, left_on= 'px_cur', right_on='cur')
	idx_data = idx_data.merge(fx, left_on= 'dvd_cur', right_on='cur', suffixes= ('', '_dvd'))

	idx_data['fx'] = idx_data['spot']/idx_data['spot_dvd']
	idx_data['dvd_points'] = (idx_data['UnadjustedGrossAmt'] *idx_data['shares'] *idx_data['fx'])/idx_data['INDX_DIVISOR']
	idx_data['amount_unconfirmed'] = idx_data['div_points'].where(idx_data['AmountConfirmed']!='Yes',0)
	idx_data['exdate_unconfirmed'] = idx_data['div_points'].where(idx_data['XDDConfirmed']!='Yes',0)
	idx_data = idx_data.set_index(['index', 'ExDividendDate'])
	idx_data = idx_data.sort_index()
	dip_sum = idx_data.groupby(level= (0,1))['div_points'].sum()
	dip_sum = dip_sum.to_frame()
	dip_sum['description'] = '_TOTAL'
	idx_data = pd.concat([idx_data, dip_sum])
	idx_data = idx_data.sort_index()
	return idx_data[['description', 'div_points', 'amount_unconfirmed', 'exdate_unconfirmed', 'UnadjustedGrossAmt', 'dvd_cur']]

if __name__ =='__main__':
	indices = ['HSI', 'HSCEI', 'TAMSCI', 'SIMSCI', 'SET50', 'XIN9I']
	result = generate_dip(indices)
	for i in indices:
		result.loc[i + ' Index'].reset_index().to_csv('N:\\{}.csv'.format(i), index=False)
