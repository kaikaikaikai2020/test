SECURITY_TYPE_DF = 'FORWARD'
SECURITY_TYPE_OS_DF = "ONSHORE FORWARD"
SECURITY_TYPE_NDF = "NON-DELIVERABLE FORWARD"
SECURITY_TYPE_SPOT = 'SPOT'
SECURITY_TYPE_NDIR = 'NON-DELIVERABLE IRS SWAP'
SECURITY_TYPE_CD = 'CD'

spot_to_ndf = {
	
	'TWD':'NTN',
	'KRW':'KWN',
	'CNY':'CCN',
	'INR':'IRN',
	'CNH':'CNH',
	'IDR':'IHN',
	'MYR':'MRN',
	'THB':'THB',
	'HKD':'HKD',
	'SGD':'SGD',
	'JPY':'JPY',
	'EUR':'EUR', 
	'PHP':'PPN'
}

ndf_to_spot = {

	'NTN':'TWD',
	'KWN':'KRW',
	'CCN':'CNY',
	'IRN':'INR',
	'CNH':'CNH',
	'IHN':'IDR',
	'MRN':'MYR',
	'THB':'THB',
	'HKD':'HKD',
	'SGD':'SGD',
	'JPY':'JPY',
	'EUR':'EUR', 
	'PPN':'PHP'

	
}

ndf_day_count = {
	
	'NTN':360,
	'KWN':365,
	'CCN':365,
	'IRN':360,
	'CNH':360,
	'IHN':360,
	'MRN':365,
	'THB':360,
	'JPY':360,
	'HKD':365,
	'SGD':365,
	'EUR':360,
	'PPN':360

}

ndf_slippage = {
	'TWD':{'1W':1, '1M':1, '3M':2, '6M':4, '9M':5, '12M':5},
	'KRW':{'1W':1, '1M':1, '3M':2, '6M':3, '9M':3, '12M':3},
	'INR':{'1W':2, '1M':2, '3M':3, '6M':4, '9M':6, '12M':6},
	'CNH':{'1W':1, '1M':1, '3M':2, '6M':3, '9M':4, '12M':4},
	'CNY':{'1W':3, '1M':3, '3M':4, '6M':5, '9M':6, '12M':8},
	'MYR':{'1W':10, '1M':10, '3M':12, '6M':15, '9M':20, '12M':25},
	'THB':{'1W':3, '1M':3, '3M':5, '6M':6, '9M':10, '12M':15},
	'IDR':{'1W':3, '1M':3, '3M':5, '6M':6, '9M':10, '12M':15},
	'HKD':{'1W':1, '1M':1, '3M':1, '6M':1, '9M':1, '12M':2},
	'SGD':{'1W':1, '1M':1, '3M':1, '6M':1, '9M':2, '12M':2},
	'JPY':{'1W':0.2, '1M':0.3, '3M':0.5, '6M':1, '9M':1, '12M':2},
	'EUR':{'1W':0.2, '1M':0.3, '3M':0.5, '6M':1, '9M':1, '12M':1}


}


tenors = ['1W','1M','2M','3M','6M','9M','12M']


