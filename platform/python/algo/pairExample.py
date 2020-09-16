from algo import pair_backtester
universe = {
	'stocks':{
		'indices':['HSI'],
	},
	'future':{
		'symbols':['HI','HC']
	},
	'currencies':{
		'symbols':['CNY Curncy', 'CNH Curncy']
	}

}

#instanciate the backtester: we will the pair trading within HSI
lBacktester = pair_backtester.pair_backtester(universe, index_name='hsi')
#Alpha is the total return of the pair ove the past 120 days
lBacktester.makeAllFunction(lambda x:-x.pair_total_return.diff(120))
#run the back tester over 2014~2016
lBacktester.run(start_date = '20140101', end_date='20161231')
#display the result
lBacktester.display_summary(lBacktester.result)
