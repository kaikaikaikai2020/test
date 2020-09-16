import datetime
import numpy as np
from bbgapi.client import download_historical_data, download_settlement_data, download_symbols_fields
from db.postgres import PostgresClient
import pandas as pd

tenors = ['1Y','2Y', '5Y','10Y']
ids = ['CTKRW'+t+' Corp' for t in tenors]
df = download_historical_data(ids, ['PX_LAST', 'YLD_YTM_MID', 'YLD_CNV_MID'], '20160101','20190129')
import pdb; pdb.set_trace()