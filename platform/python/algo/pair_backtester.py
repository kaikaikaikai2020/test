from utils.config import Config
from operators import indicator as id 
from simulation.algorithm import Algorithm
from simulation.backtest import Backtest
from simulation.api import order, order_target, order_target_value, add_pipeline
import pair_tools;reload(pair_tools)

from pair_tools import *
import optimizer_class;reload(optimizer_class)
from optimizer_class import *
from correlation import *
from theo_optim_constraint import *
from universewrapper import *

class backtesterParamsConstructor:
	def __init__(self, **args):
		self.__myParams = args
		if not self.__myParams.has_key('scale_facotr'):
			self.__myParams['scale_facotr'] =1
		if not self.__myParams.has_key('atol'):
			self.__myParams['atol'] = 1e-7
		if not self.__myParams.has_key('rtol'):
			self.__myParams['rtol']= 1e-5
		self.modifyParams()
	def modifyParams(self):
		if self.__myParams.has_key('slippage'):
			if self.__myParams['slippage']>=0.1:
				print("slippage is %s bps "%self.__myParams['slippage'])
				self.__myParams['slippage']/=10000.

		for s, u in self.__myParams.items():
			if 'financing' in s:
				if abs(u)>0.1:
					print("%s is %s bps"%(s,u))
					self.__myParams[s]/=10000.


	def unpdateParams(self, **args):
		self.__myParams.update(args)
		self.modifyParams()
	def getParams(self):
		return self.__myParams.copy()

class pairBacktest(pair_tools, optimizerClass, Backtest, theo_optim_constraint):
	def __init__(self, universe, sim_params_class = backtesterParamsConstructor(), comp=None, index_name = None, update_cache = False):
		Config().read('config.ini')
		self.sim_params_class= sim_params_class
		sim_params = self.sim_params_class.getParams()
		if update_cache:
			sim_params['update_cache'] = True
		pair_tools.__init__(self, compo, index_name)
		optimizerClass.__init__(self, sim_params['scale_facotr'])
		Backtest.__init__(self, sim_params)
		self.universe = universe
	def makeAllFunction(self, pair_alpha_generator=None, sameDay= True, generate_paire_data = True, reuse_alpha=False):
		self.mygenerate_alpha = self.generate_alpha_function(pair_alpha_generator, generate_paire_data, reuse_alpha)
		self.myinit = lambda context:add_pipeline('generate_alpha'), self.mygenerate_alpha
		self.myhandle_data = self.generateHandleData(sameDay)
		self.myalg = Algorithm(init = self.myinit, handle_data = self.myhandle_data)
	def makeAllFunctionNoAlphaRecomputation(self, sameDay= True):
		self.makeAllFunction(sameDay = sameDay)
	def run(self, start_date, end_date):
		self.result = Backtest.run(self,self.myalg, universe = self.universe, start_date = start_date, end_date=end_date)

	def get_correlation(self, shift =10):
		correlation.get_correlation(self, self.stock_return)
		self.correlation.shift(shift)
	def generate_constraint(self, max_traing, max_position, sector_limit = None, omega = None, cost_buidling = 10, cost_cuting = 10, sectorfunction = lambda x:x):
		print(locals())
		C = constraint_wrapper()
		C.setTrading(max_trading, max_position)
		if sector_limit is not None:
			C.setSector(self.mysectordata.applymap(sectorfunction), sector_limit)
		if omega:
			C.setRisk(self.correlation, omega)
		C.setCost(cost_buidling, cost_cuting)
		return C.getConstraint()
		

