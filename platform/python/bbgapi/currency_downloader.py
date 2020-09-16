from bbgapi.client import download_historical_data
from datasets.bloomberg.data_source import BBGCurNonstandardDataSource
currency_list = ['IRSW01', 'IRSW03', 'IRSW05', 'IRSWM1', 'IRSWM3', 'IRSWM5', 'KWSWN1', 'KWSWN2', 'KWSWN3', 'KWUSWO1', 'KWUSWO2', 'KWUSWO3', 'KWUSWO4', 'KWUSWO5']
currency_list_new = []
def download_nonstandard_currencies (symbols = None, start_date = None, end_date = None, insert_db = False):
	fields = ['PX_LAST']
	if symbols is None:
		symbols = currency_list
	symbols_new = []
	for sym in symbols:
		if 'Curncy' not in sym:
			symbols_new.append(sym +' Curncy')
		else:
			symbols_new.add(sym)

	price_df = download_historical_data(ids= symbols_new, flds= fields, start_date = start_date, end_date=end_date)

	if insert_db:
		ds = BBGCurNonstandardDataSource()
		number_lines = ds.append(price_df, upsert=True)
		print(number_lines, ' inserted')
	else:
		print(price_df)

if __main__ == '__main__':
	download_nonstandard_currencies(symbols = currency_list, start_date='20080101', end_date='20081231', insert_db=True)
	
