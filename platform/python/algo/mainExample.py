from pairOptimizer import *

universe = {
	'stock': { 
				#'symbols': ['5 HK Equity']
				'indices': ['HSI Index']
				},
	'futures' : {
				'symbols':['HI']
	},
}

lBacktester = pairBacktesterWithOptimizer(universe, update_cache = False, index_name = 'hsi')
lBacktester.run(lambda x:-x.pair_total_return.diff(10), optimParams(1,10,10000,10,10, lambda x:x[:2], second_limit=0), start_date='20140101', end_date='20161230')