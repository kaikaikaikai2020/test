from algo import pair_backtester
import pandas as pa
import traceback
import sys

class OptimParams:
	def __init__(self, max_trading, max_position, omega, cost_building, cost_cuting, sector_function = lambda x:x, sector_limit=None):
		self.max_trading = max_trading
		self.max_position = max_position
		self.omega = omega
		self.cost_building = cost_building
		self.cost_cuting = cost_cuting
		self.sector_function = lambda x: sector_function(str(x))
		self.sector_limit = sector_limit
class pairBacktesterWithOptimizer(pair_backtester.pairBacktest):
	def __init__(self, *liste, **dicte):
		pair_backtester.pairBacktest.__init__(self, *liste, **dicte)

	def singleDayOptim(self, sodRescaled, alpha, thisDayCorrelation= None):
		try:
			if self.compo.loc[self.today].abs().sum()==0:
				try:
					self.myPosition = self.myPosition.append(self.myPosition.ix[-1])
				except:
					print('PB1 on')
					print(self.today)
					newposition = pa.Series(0, index = self.universe)
					newposition.name = self.today
					self.myPosition = self.myPosition.append(newposition)
					return
				L = list(self.myPosition.index)
				L[-1] = self.today
				self.myPosition.index = L
				return
			newposition = self.singleDay(sodRescaled, alpha, self.today, self.backtestconstraint)
			newposition.name = self.today
			self.myPosition = self.myPosition.append(newposition)
			return
		except:
			traceback.print_exc(file=sys.stdout)
			self.myPosition = self.myPosition.append(self.myPosition.ix[-1])

		def generate_alpha_function(self, pair_alpha_generator = None, generate_paire_data=True, reuse_alpha = False):
		'''
		return a function to be input in the backtester
		pair_alpha_generator is a function genrating pair alpha given self (it uses this instance of this class)
		'''
		if not hasattr(self, 'pair_alpha_generator') and pair_alpha_generator is None:
			raise AttributeError("Pair alpha has not been defined yt")

		if reuse_alpha:
			return lambda x:{'alpha': self.backtesteralpha.copy()}
		if not pair_alpha_generator is None:
			self.pair_alpha_generator = pair_alpha_generator

		@pair_backtester.keepdata(self)
		def generate_alpha(backtester_data):
			if not self.first_run_done:
				self.data = backtester_data
			if self.old_comp is None and self.index_name is not None:
				if not self.first_run_done:
					self.comp = (backtester_data['%s_weight'%self.index_name.lower()]>0 & backtester_data['tradable']).unstack()
				if generate_paire_data:
					print(backtester_data.columns)
					self.create_pairs(backtester_data)
					self.first_run_done = True
					self.backtestconstraint= self.generate_constraint(1, 10, omega=10000, cost_building=10, cost_cuting=10, sectorfunction = lambda x:str(x)[:2], sector_limit=0)
				self.pair_alpha = self.pair_alpha_generator(self)
				self.pair_alpha = self.apply_combo(self.pair_alpha)
				self.pair_alpha_list.append(self.pair_alpha)
				self.alpha = self.pair_position_to_stock_position(self.pair_alpha)
				self.backtesteralpha = self.alpha.stack().reindex_like(backtester_data['px_last'])
				self.alpha_list.append(self.backtesteralpha.copy())
				return {'alpha':self.backtesteralpha.copy()}
			return generate_alpha

		def run (self, alphagenerator, optimparams, start_date, end_date):
			self.optimparams = optimparams
			self.makeAllFunction(alphagenerator)
			pair_backtester.pairBacktest.run(self, start_date= start_date, end_date=end_date)
			self.display_summary(self.result)
			


