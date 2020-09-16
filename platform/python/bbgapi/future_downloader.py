from bbgapi.client import download_historical_data
from datasets.bloomberg.data_source import BBGFPXNonstandardDataSource

symbol_list =[
	'CL1 Comdty'
	]

def download_nonstandard_futures(symbols= None, start_date = None, end_date = None, insert_db = False):
	fields = ['PX_LAST']
	if symbols is None:
		symbols = symbol_list
	price_df = download_historical_data(ids= symbols, flds= fields, start_date= start_date, end_date= end_date)

	if insert_db:
		ds = BBGFPXNonstandardDataSource()
		number_lines = ds.append(price_df, upsert = True)
		print(number_lines, ' inserted')
	else:
		return price_df
if __name__ == '__main__':
	download_nonstandard_futures(symbols= None, start_date='20090101', end_date = '20190723', insert_db= True)
