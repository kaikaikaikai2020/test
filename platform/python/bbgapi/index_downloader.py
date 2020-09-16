from bbgapi.client import download_historical_data
from datasets.bloomberg.data_source import BBGIPXNonstandardDataSource

index_list = [
	'EMCFPROX',
	'JBDNTWD',
	'JBDCTWD',
	'JBDPTWD',
	'CECICTWD',
	'CIICCTWD',
	'CESITWD',
	'TWEOELY',
	'TWINDPIY',
	'ECOPTWN',
	'ECOGBTWN',
	'GVTW10YR',
	'FXVIX',
	'LBUSTRUU',
	'LWXPTREU', 
	'TINFNET$',
	'PRIMTA',
	'NTON',
	'TWD11',
	'JBDNKRW',
	'JBDCKRW',
	'JBDPKRW',
	'CECICKRW',
	'CESIKRW',
	'CIICCKRW',
	'JBDNINR',
	'JBDCINR',
	'JBDPINR',
	'CECICINR',
	'CESIINR',
	'CIICCINR',
	'VIX',
	'SPX',
	'DXY',
	'KRBO1M',
	'KRBO3M',
	'KRBO6M',
	'KRBO12M',
]

index_list_new = []

def download_nonstandard_indics(symbols= None, start_date = None, end_date = None, insert_db = False):
	fields = ['PX_LAST']
	if symbols is None:
		symbols = symbol_list

	symbols_new = []
	for sym in symbols:
		if 'Index' not in sym:
			symbols_new.append(sym+ ' Index')
		else:
			symbols_new.add(sym)

	price_df = download_historical_data(ids= symbols_new, flds= fields, start_date= start_date, end_date= end_date)

	if insert_db:
		ds = BBGFPXNonstandardDataSource()
		number_lines = ds.append(price_df, upsert = True)
		print(number_lines, ' inserted')
	else:
		return price_df

if __name__ == '__main__':
	download_nonstandard_indics(symbols= index_list, start_date='20080101', end_date='20081231', insert_db= True)
	