from numpy import *
from myNone import *

class correlation:
	def get_correlation(self, stock_return, depth=120):
		X = stock_return
		initial_cov = zeros((len(stock_return.columns), len(stock_return.col)))
		self.correlation = mySeries([initial_cov for i in range(depth+1)] + [cov(array(X.ix[i-depth:i]).T) for i in range(depth+1, len(stock_return.index)-1)], stock_return
			.index, stock_return.columns)
		
