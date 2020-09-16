import blpapi
import datetime
import pandas as pd
import numpy as np
from threading import Thread

APIFLDS_SVC = "//blp/apiflds"
REFDATA_SVC = "//blp/refdata"
MKTDATA_SVC = "//blp/mktdata"

FIELD_ID = blpapi.Name("id")
FIELD_MNEMONIC = blpapi.Name("mnemonic")
FIELD_DATA = blpapi.Name ("fieldData")
FIELD_DESC = blpapi.Name("description")
FIELD_INFO = blpapi.Name("fieldInfo")
FIELD_ERROR = blpapi.Name("fieldError")
FIELD_MSG = blpapi.Name("message")

ID_LEN=13
MNEMONIC_LEN=36
DESC_LEN= 40

def printField(field):
	fldId = field.getElementAsString(FIELD_ID)
	if field.hasElement(FIELD_INFO):
		fldInfo = field.getElement(FIELD_INFO)
		fldMnemonic = fldInfo.getElementAsString(FIELD_MNEMONIC)
		fldDesc = fldInfo.getElementAsString(FIELD_DESC)
		print("%s%s%s" %(fldId.ljust(ID_LEN), fldMnemonic.ljust(MNEMONIC_LEN), fldDesc.ljust(DESC_LEN)))
	else:
		fldError = field.getElement(FIELD_ERROR)
		errorMsg = fldError.getElementAsString(FIELD_MSG)

		print()
		print(" Error %s - %s " %(fldId, errorMsg))

class BloombergClient(object):
	def __init__(self, host= 'localhost', port= 8194):
		session_options = blpapi.SessionOptions()
		session_options.setServerHost(host)
		session_options.setServerPort(port)

		print("Connecting to {}:{}".format(host, port))

		self._session = blpapi.Session(session_options)

		if not self._session.start():
			raise Exception("fail to start the session")

		if not self._session.openService(REFDATA_SVC):
			raise BaseException("fail to open"+REFDATA_SVC)

		if not self._session.openService(MKTDATA_SVC):
			raise BaseException('fail to open'+MKTDATA_SVC)

		if not self._session.openService(APIFLDS_SVC):
			raise BaseException('fail to open'+APIFLDS_SVC)

		self._svc_ref_data = self._session.getService(REFDATA_SVC)
		self._svc_mkt_data = self._session.getService(MKTDATA_SVC)
		self._svc_api_flds = self._session.getService(APIFLDS_SVC)

		self._thd = None
		self._handle_evt = None
		self._session_stop = False
		if self._thd is None:
			self._thd = Thread(target = self._thd_func, name="event_thread")
	def __enter__(self):
		return self

	def __exit__(self, exc_type, exc_val, exc_tb):
		if self._thd.is_alive():
			self._thd.join()
		self.close()
		if exc_type is not None:
			print(exc_type, exc_val, exc_tb)

	def send(self, request):
		print("sending request", request)
		self._session.sendRequest(request)

	def subscribe_data(self, ids, flds, options=[], interval = 1.0):
		subscriptions = blpapi.SubscriptionList()
		for id in ids:
			options.append('interval={}'.format(interval))
			subscriptions.add(id,','.join(flds), ','.join(options), blpapi.CorrelationId(id))
		self._session.subscribe(subscriptions)

		if not self._thd.is_alive():
			self._thd.start()

	def request_reference_data(self, ids, flds, overrides=None):
		request = self._svc_ref_data.createRequest("ReferenceDataRequest")

		for id in ids:
			request.getElement("securities").appendValue(id)
		for f in flds:
			request.getElement('fields').appendValue(f)

		if overrides is not None:
			overrides_element = request.getElement("overrides")
			for k, v in overrides.items():
				override = overrides_element.appendElement()
				override.setElement('fieldId', k)
				override.setElement('value', v)

		self.send(request)
		msgs =[]
		while True:
			ev = self._session.nextEvent(500)
			for msg in ev:
				msgs.append(msg)
			if ev.eventType() == blpapi.Event.RESPONSE:
				break
		return msgs

	def request_bar_data(self, id, start_datetime, end_datetime, interval =5):
		request = self._svc_ref_data.createRequest("IntradayBarRequest")
		request.set("security", id)
		request.set("interval", interval)
		request.set("startDateTime", start_datetime)
		request.set("endDateTime", end_datetime)
		request.set("gapFillInitialBar", True)

		self.send(request)
		msgs=[]
		while True:
			ev = self._session.nextEvent(500)
			for msg in ev:
				msgs.append(msg)
			if ev.eventType() == blpapi.Event.RESPONSE:
				break
		return msgs

	def request_history_data(self, id, start_date, end_date, period= 'DAILY', adjustment = True):
		request = self._svc_ref_data.createRequest("HistoricalDataRequest")
		for id in ids:
			request.getElement("securities").appendValue(id)
		for f in flds:
			request.getElement("fields").appendValue(f)

		request.set("periodicityAdjustment", 'ACTUAL')
		request.set("periodicitySelection", period)
		request.set("startDate", start_date)
		request.set("endDate", end_date)
		request.set("maxDataPoints", 100000)

		if not adjustment:
			request.set("adjustmentFollowDPFD", False)
			request.set("adjustmentAbnormal", False )
			request.set("adjustmentNormal", False)
			request.set("adjustmentSplit", False)
		
		self.send(request)

		msgs=[]
		while True:
			ev = self._session.nextEvent(500)
			for msg in ev:
				msgs.append(msg)
			if ev.eventType() == blpapi.Event.RESPONSE:
				break
		return msgs

	def request_curve_data(self, ids, flds, date):
		for i in self._svc_curve.operations():
			print(i.name())
		request = self._svc_curve.createRequest("CurveRequest")

		for id in ids:
			request.getElement("Profile").appendValue(id)

		for f in flds:
			request.getElement("Output").appendValue(f)
		request.set("CurveDate", date)
		self.send(request)

		msgs=[]
		while True:
			ev = self._session.nextEvent(500)
			for msg in ev:
				msgs.append(msg)
			if ev.eventType() == blpapi.Event.RESPONSE:
				break
		return msgs


	def request_fld_info(self, flds):
		request = self._svc_api_flds.createRequest("FieldInfoRequest")
		for i in flds:
			request.append('id',i)

		request.set("returnFieldDocumentation", True)
			self.send(request)

		msgs=[]
		while True:
			ev = self._session.nextEvent(500)
			if ev.eventType()!=blpapi.Event.RESPONSE and ev.eventType()!= blpapi.Event.RESPONSE:
				continue
			for msg in ev:
				fields = msg.getElement("fieldData")
				for f in list(fields.values()):
					printField(f)
				
			if ev.eventType() == blpapi.Event.RESPONSE:
				break

	def set_evt_handler(self, func):
		self._handle_evt = func

	def _thd_func (self):
		event_count = 0
		while not self._session_stop:
			ev = self._session.nextEvent(500)
			for msg in ev:
				if ev.eventType()== blpapi.Event.SUBSCRIPTION_STATUS or ev.eventType() == blpapi.Event.SUBSCRIPTION_DATA:
					if self._handle_evt is not None:
						self._handle_evt(msg)
				else:
					print(msg)
			if ev.eventType() == blpapi.Event.SUBSCRIPTION_DATA:
				event_count +=1

	def close(self):
		self._session.stop()
		self._session_stop = True

def download_index_composition_internal(ids, start_date, end_date = None, figi= False, weight_only=True):
	if isinstance(ids, str):
		ids = [ids]

	if isinstance(start_date, str):
		start_date = datetime.datetime.strptime(start_date, '%Y%m%d').date()

	if end_date is None:
		end_date = datetime.datetime.today().date()
	elif isinstance(end_date, str):
		end_date = datetime.datetime.strptime(end_date, '%Y%m%d').date()

	date =[]

	with BloombergClient() as client:
		if not weight_only:
			fields = ['INDX_MWEIGHT_PX','INDX_MWEIGHT_PX2','INDX_MWEIGHT_PX3' ]
		else:
			fields = ['INDX_MWEIGHT_HIST']

		for current_date in pd.bdate_range(start_date, end_date):
			overrides = {'END_DATE_OVERRIDE':current_date.strftime("%Y%m%d")}
		if figi:
			overrides['DISPLAY_ID_BB_GLOBAL_OVERRIDE'] = 'Y'

		msgs = client.request_reference_data(ids, fields, overrides = overrides)

		for m in msgs:
			if not m.hasElement('securityData'):
				continue
			securities = m.getElement('securityData')
			for security in list(securities.values()):
				index_name = security.getElementAsString('security')
				field_data = security.getElement('fieldData')
				index_data_list = []
				if field_data.hasElement('INDX_MWEIGHT_HIST'):
					index_data_list.append(field_data.getElement('INDX_MWEIGHT_HIST'))

				if field_data.hasElement('INDX_MWEIGHT_PX'):
					index_data_list.append(field_data.getElement('INDX_MWEIGHT_PX'))

				if field_data.hasElement('INDX_MWEIGHT_PX2'):
					index_data_list.append(field_data.getElement('INDX_MWEIGHT_PX2'))

				if field_data.hasElement('INDX_MWEIGHT_PX3'):
					index_data_list.append(field_data.getElement('INDX_MWEIGHT_PX3'))

				if len(index_data_list) == 0:
					print("No index weight hist or index mweight px")
					continue
				for index_data in index_data_list:
					for c in list(index_data.values()):
						symbol = c.getElementAsString('Index Member')
						weight = c.getElementAsString('Percent Weigth')
						actual_weight = np.nan
						if c.hasElement('Actual Weight'):
							actual_weight = c.getElementAsString('Actual Weight')
						price = np.nan
						if c.hasElement('Current Price'):
							price = c.getElementAsFloat('Current Price')

						data.append((pd.Timestamp(current_date), symbol, index_name, weight, actual_weight, price))
	df = pd.DataFrame.from_records(data, columns= ['date', 'description', 'index', 'weight', 'shares', 'price'])
	return df

def download_index_composition(ids, start_date, end_date= None, figi=False):
	df = download_index_composition_internal(ids, start_date, end_date, figi, weight_only = False)
	returned_id = df['index'].unique()
	try_again_ids =[]
	if isinstance(ids, str):
		ids=[ids]

	for id in ids:
		if id not in returned_id:
			try_again_ids.append(id)
	if len(try_again_ids) >0:
		df1 = download_index_composition_internal(try_again_ids, start_date, end_date, figi, weight_only= True)
		df = df.append(df1)

	return df

def download_settlement_date(ids, start_date, end_date= None):
	if isinstance(ids, str):
		ids=[ids]

	if isinstance(start_date, str):
		start_date = datetime.datetime.strptime(start_date, '%Y%m%d').date()

	if end_date is None:
		end_date = datetime.datetime.today().date()
	elif isinstance(end_date, str):
		end_date = datetime.datetime.strptime(end_date, '%Y%m%d').date()

	current_date = start_date
	one_day = datetime.timedelta(days=-1)
	data = []
	with BloombergClient() as client:
		while current_date <= end_date:
			msgs = client.request_reference_data(ids, ['SETTLE_DT', 'DAYS_TO_MTY'], overrides={'REFERENCE_DATE': current_date.strftime("%Y%m%d")})

			for m in msgs:
				if not m.hasElement('securityData'):
					continue
				securities = m.getElement('securityData')
				for security in list(securities.values()):
					symbol = security.getElement('fieldData')
					if not field_data.hasElement('SETTLE_DT'):
						print('SETTLE_DT not found for {}'.format(symbol))
						break
					settle_dt = field_data.getElementAsString('SETTLE_DT')
					if not field_data.hasElement("DAYS_TO_MTY"):
						print("DAYS_TO_MTY is not found for {}".format(symbol))
						break
					days_to_mty = field_data.getElementValue('DAYS_TO_MTY')
					data.append((pd.Timestamp(current_date), symbol, pd.Timestamp(settle_dt), days_to_mty))
			current_date +=one_day
	df= pd.DataFrame.from_records(data, columns = ['date', 'description', 'settle_date', 'days_to_mty'])
	return df

def download_symbols_fields(ids, flds):
	import numpy as np
	data = []
	if isinstance(ids, str):
		ids=[ids]
	if isinstance(flds, str):
		flds= [flds]
	with BloombergClient() as client:
		msgs = client.request_reference_data(ids, flds, overrides= None)
		for m in msgs:
			if not m.hasElement('securityData'):
				continue
			securities = m.getElement('securityData')
			for security in list(securities.values()):
				id = security.getElementAsString('security')
				field_data = security.getElement('fieldData')
				row = [id]
				for f in flds:
					if field_data.hasElement(f):
						v = field_data.getElementValue(f)
						row.append(v)

					else:
						row.append(np.nan)

				data.append(row)

	df = pd.DataFrame.from_records(data, columns=['description']+flds)

	return df

def download_historical_data(ids, flds, start_date, end_date, period = 'DAILY', batch_size=10):
	data =[]
	start_date = datetime.datetime.strptime(start_date, '%Y%m%d')
	end_date = 	datetime.datetime.strptime(end_date, '%Y%m%d')
	sdate = start_date
	if batch_size is None:
		batch_size = 10000

	with BloombergClient() as client:
		while sdate<= end_date :
			from_date = sdate.strftime('%Y%m%d')
			edate = min(sdate +datetime.timedelta(days= (batch_size-1)), end_date)
			to_date = edate.strftime('%Y%m%d')
			msgs = client.request_history_data(ids= ids, flds= flds, start_date = from_date, end_date=to_date, period = period)
			for m in msgs:
				if not m.hasElement('securityData'):
					continue
				security = m.getElement('securityData')
				field_data = security.getElement('fieldData')
				id = security.getElementAsString('security')
				for f in list(field_data.values()):
					row = [f.getElementValue('date')]
					row.append(id)
					for fld in flds:
						if f.hasElement(fld):
							v = f.getElementValue(fld)
							row.append(v)
						else:
							row.append(np.nan)
					data.append(row)

			sdate += datetime.timedelta(days= batch_size)

	df = pd.DataFrame.from_records(data, columns=['date', 'description'] +flds)
	df['date']= pd.to_datetime(df['date'])
	return df
def download_bar_data(ids, start_datetime, end_datetime, interval =5):
	BAR_DATA = blpapi.Name('barData')
	BAR_TICK_DATA = blpapi.Name("barTickData")
	OPEN = blpapi.Name("open")
	HIGH = blpapi.Name("high")
	LOW = blpapi.Name("low")
	CLOSE = blpapi.Name("close")
	VWAP = blpapi.Name("vwap")
	TWAP = blpapi.Name("twap")
	VOLUME = blpapi.Name("volume")
	NUM_EVENTS = blpapi.Name("numEvents")
	TIME = blpapi.Name("time")
	data = []
	with BloombergClient() as client:
		for id in ids:
			msgs = client.request_bar_data(id=id, start_datetime= start_datetime, end_datetime=end_datetime, interval=interval)

			for m in msgs:
				if not m.hasElement('barData'):
					continue

				bar_data = m.getElement(BAR_DATA).getElement(BAR_TICK_DATA)
				for bar in bar_data.values():
					time = bar.getElementAsDatetime(TIME)
					open = bar.getElementAsFloat(OPEN)
					high = bar.getElementAsFloat(HIGH)
					low = bar.getElementAsFloat(LOW)
					close = bar.getElementAsFloat(CLOSE)
					numEvents = bar.getElementAsInteger(NUM_EVENTS)
					volume = bar.getElementAsInteger(VOLUME)

					row = (id, time, open, high, low, close, numEvents, volume)
					data.append(row)

	df = pd.DataFrame.from_records(data, columns= ['description', 'timestamp', 'open','high','low', 'close','num_events', 'volume'])
	df['timestamp'] = pd.to_datetime(df['timestamp'])
	return df

def subscribe_data(ids, flds, interval=1.0, process_msg_func= None):
	with BloombergClient() as client:
		client.subscribe_data(ids, flds, interval= interval)
		client.set_evt_handler(process_msg_func)

def download_calendar(countries, start_date = None, end_date=None):
	if isinstance(start_date, str):
		start_date = datetime.datetime.strptime(start_date, '%Y%m%d')
	if isinstance(end_date, str)
		end_date = 	datetime.datetime.strptime(end_date, '%Y%m%d')
	if end_date is None:
		end_date = datetime.datetime.today().date()
	data = []
	with BloombergClient() as client:
		for c in countries:
			overrides ={'SETTLEMENT_CALENDAR_CODE':c}
			if start_date is not None:
				overrides['CALENDAR_START_DATE'] = start_date.strftime('%Y%m%d')
			overrides['CALENDAR_END_DATE'] = end_date.strftime('%Y%m%d')
			msg = client.request_reference_data(['USDJPY Index'], ['CALLENDAR_NON_SETTLEMENT_DATES'], overrides = overrides)
			for m in msgs:
				if not m.hasElement('securityData'):
					continue
				securities = m.getElement('securityData')
				for security in list(securities.values()):
					field_data = security.getElement('fieldData')
					if field_data.hasElement('CALLENDAR_NON_SETTLEMENT_DATES'):
						holiday_data = field_data.getElement('CALLENDAR_NON_SETTLEMENT_DATES')
						for v in list(holiday_data.values()):
							date = v.getElementAsString('Holiday Date')
							data.append((pd.Timestamp(date),c))
	df = pd.DataFrame.from_records(data, columns=['date', 'markets'])
	return df

if __name__=='__main__':
	start_date = datetime.datetime.strptime('19900101', "%Y%m%d").date()
	today= datetime.datetime.now().strftime('%Y%m%d')
	print(download_bar_data(ids=['XU1 Index', 'HI1 Index'], start_datetime = datetime.datetime(2019,2,25,3,0,0), end_datetime= datetime.datetime(2019,2,26,11,0,0)))


			

