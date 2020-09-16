import win32com.client
import pandas as pd
import datetime
import time
from db.postgres import PostgresClient
from utils.config import Config

import pytz

def download_yield_curve (start_date, end_date, insert_db=False):
	xl = win32com.client.Dispatch("Excel.Application")
	wb = xl.WorkbooksOpen(Filename = "S:\\yield_downloader.xlsx", ReadOnly=1)
	ws = wb.Worksheets("Sheet2")
	cur_date = start_date
	one_day = datetime.timedelta(1)
	client = PostgresClient.get('Data')
	dfs=[]
	while cur_date <= end_date:
		rows = []
		print("Request curve for {}".format(cur_date))
		ws.Cells(31,1).Value = cur_date.strftime('%Y%m%d')
		time.sleep(5)
		while ws.Cells(33,5).Value.strftime('%Y%m%d') < cur_date.strftime('%Y%m%d'):
			print("Request not done yet wait another 2 seconds")
			time.sleep(2)
		for i in range(33, 59):
			if ws.Cells(i,2).Values == "SERIAL_FUTURE" or ws.Cells(i,2).Values == 'DEPOSIT':
				continue
			row = [cur_date]
			append_row = True
			for j in range(1,10):
				if j==5 or j==6:
					try:
						row.append(datetime.datetime.strftime(ws.Cells(i,j).Value.strftime('%Y%m%d'), '%Y%m%d'))
					except Exception as e:
						print(e, "fail to convert the date ", ws.Cells(i,j).Value)
						append_row = False
						break
				else:
					row.append(ws.Cells(i,j).Value)
			if append_row:
				rows.append(row)

		df = pd.DataFrame.from_records(data = rows, columns=['date', 'Term', 'InstType','Instrument', 'InstDes', 'StartDate', 'Maturity', 'Bid','Ask', 'Pcs'])
		if insert_db:
			number_inserted = client.insert_dataframe(df, 'bbg', 'usd_ois_curve', if_exists='append', index = False, chunksize = 10000, primary_keys=['date', 'Instrument','Maturity'], upsert=True)
			print(number_inserted, " inserted")

		else:
			dfs.append(df)
		cur_date +=one_day
	wb.Close(False)
	df = pd.concat(dfs)
	return df

if __name__=='__main__':
	Config().read('N:\\projects\\platform\\python\\config\\config.ini')
	today = datetime.datetime.strptime(datetime.datetime.now(pytz.timezone('Asia/Hong_Kong')).strftime('%Y%m%d'), '%Y%m%d')
	start_date = datetime.datetim.strptime('20180202', '%Y%m%d')
	end_date = datetime.datetime.strptime('20180117', '%Y%m%d')
	download_yield_curve(start_date, today, insert_db=True)

