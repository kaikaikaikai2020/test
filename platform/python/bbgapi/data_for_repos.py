import sys
sys.path.append("S:\\platform\\python")

from bbgapi.client import BloombergClient
from db.postgres import PostgresClient
import datetime
import pandas as pd
import numpy as np
FUT_DVD_TO_EXP = 'FUT_DVD_TO_EXP'
FUT_ACT_DAYS_EXP = 'FUT_ACT_DAYS_EXP'

universe =[
		('SG', 'QZ', 'SIMSCI', 'SIBF1M'),
		('HK', 'HC', 'HSCEI', 'HIHD01M'),
		('HK', 'HI', 'HSI', 'HIHD01M'),
		('XU', 'XU', 'XIN9I', 'CNHI1M'),
		('JP', 'NK', 'NKY', 'JY0001M'),
		('JP', 'TP', 'TPX', 'JY0001M'),
		('IN', 'IN', 'NIFTY', 'IRNI1M'),
		('IN', 'NZ', 'NIFTY', 'IRNI1M'),
		('IN', 'AF', 'NSEBANK', 'IRNI1M'),
		('TW', 'TW', 'TAMSCI', 'TRNI1M'),
		('TW', 'FT', 'TWSE', 'TRNI1M'),
		('CN', 'IFB', 'SHSZ300','CNHI1M'),
		('CN', 'FFB', 'SSE50', 'CNHI1M'),
		('CN', 'FFD', 'SH000905','CNHI1M'),
		('AU', 'XP', 'AS51','BBSW1M'),
		('KR', 'KM','KOSPI2', 'KWNI1M'),
		('KR', 'KST', 'KOSDQ150', 'KWNI1M'),
		('MY', 'IK', 'FBMKLCI', 'MRNI1M'),
		('TH', 'BC', 'SET50', 'THBI1M')]

time_map ={
	810: ['AU', 'JP', 'KR'],
	840: ['AU', 'JP', 'KR'],
	910: ['TW', 'CN','SG','MY'],
	940: ['HK', 'TW', 'CN', 'SG', 'MY'],
	1010: ['HK'],
	1100: ['TH'],
	1130: ['TH'],
	1140: ['IN'],
	1210: ['IN'],
	1310: ['TW'],
	1320: ['TW'],
	1330: ['TW'],
	1340: ['AU', 'JP'],
	1350: ['AU', 'JP'],
	1400: ['AU', 'JP'],
	1410: ['KR'],
	1420: ['KR'],
	1430: ['KR'],
	1440: ['CN'],
	1450: ['CN'],
	1500: ['CN'],
	1540: ['HK'],
	1550: ['HK'],
	1600: ['HK'],
	1640: ['SG', 'MY'],
	1650: ['SG', 'MY'],
	1700: ['SG', 'MY'],
	1740: ['IN', 'TH'],
	1750: ['IN', 'TH'],
	1800: ['IN', 'TH']

}

if __name__ =='__main__':
	now = datetime.datetime.now()
	trigger_time = now.hour *100 +now.minute
	trigger_countries = []
	for i in time_map:
		if abs((trigger_time -i ))<2:
			trigger_countries +=time_map[i]

	trigger_universe = []
	for i in universe:
		if i[0] in trigger_countries:
			trigger_universe.append(i)
	if len(trigger_universe) == 0:
		print("no country is trigger")
		exit(0)

	with BloombergClient() as client:
		data=[]
		for row in trigger_countries:
			print()
			c = row[0]
			f1 = row[1] +'1 index'
			f2 = row[1] +'2 index'
			s = 'S:' +row[1]+row[1] + ' 1-2 index'
			spot = row[2] + ' Index'
			ir = row[3] + ' Index'
			ids = [spot, f1, f2, ir, s]
			flds = [FUT_DVD_TO_EXP, FUT_ACT_DAYS_EXP, 'PX_LAST', 'PX_VOLUME']
			now = datetime.datetime.now()
			msgs = client.request_reference_data(ids, flds)
			for m in msgs:
				r = []
				r.append(datetime.datetime.today().date())
				r.append(c)
				r.append(spot)
				r.append(row[1])
				r.append(ir)
				if not m.hasElement('securityData'):
					continue
				securities = m.getElement('securityData')
				for security in list(securities.values()):
					id = security.getElementAsString('security')
					field_data = security.getElement('fieldData')
					last = np.nan
					if field_data.hasElement('PX_LAST'):
						last = field_data.getElementValue('PX_LAST')
					r.append(last)

					if id==f1 or id==f2:
						dvd_exp = field_data.getElementValue(FUT_DVD_TO_EXP)
						r.append(dvd_exp)
						days_exp = field_data.getElementValue(FUT_ACT_DAYS_EXP)
						r.append(days_exp)
					if id==f1 or id==f2 or id==s:
						vol = np.nan
						if field_data.hasElement('PX_VOLUME'):
							vol = field_data.getElementValue('PX_VOLUME')

						r.append(vol)

				r.append(now)
				data.append(r)

		df = pd.DataFrame(data, columns= ['date', 'country', 'index', 'fut', 'interest', 'spot', 'f1', 'd1', 't1', 'v1', 'd2', 'v2', 'ir', 'roll', 'v_roll', 'update_time'])	
		PostgresClient.get('Data').insert_dataframe(df, schema = 'rates', table_name='repos', if_exists='append', index=False, primary_keys=['date', 'country', 'index', 'fut','interest'], upsert=True)
