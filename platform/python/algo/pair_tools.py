from numpy import *
import pandas as pa
from scipy import sparse
from correlation import *

def keepdata(self):
	def keepdatainner(f):
		def u(*liste, **dico):
			"I am changing the value of the calss"
			x = f(*liste, **dico)
			self.first_run_done = True
			return x
		return u 
	return keepdatainner

def returnAlpha(self):
	def returnAlphainner(f):
		def u(backtester_data):
			self.pair_alpha = f(self)
			self.pair_alpha = self.apply_compo(self.pair_alpha)
			self.pair_alpha_list.append(self.pair_alpha)
			self.alpha = self.pair_position_to_stock_position(self.pair_alpha)
			self.backtesteralpha = self.alpha.stack().reindex_like(backtester_data['px_last'])
			self.alpha_list.append(self.backtesteralpha.copy())
			return {'alpha':self.backtesteralpha.copy()}
		return u 
	return returnAlphainner

class pair_tools(correlation):
	def __init__(self, compo=None, index_name= None, backtestequityonly=False):
		self.backtestequityonly= backtestequityonly
		self.compo = compo
		self.old_compo = compo
		self.alpha_list = []
		self.price_list = []
		self.pair_alpha_list=[]
		self.index_name = index_name
		self.first_run_done = False
	def limitDataToCompo(self, pricedata, sectordata):
		'''
		will reduce price data to only the stocks once in the compo
		we assume pricedata history is shorter than compo history
		'''

		if self.first_run_done:
			return 
		if self.compo is None:
			self.mypricedata = pricedata
			self.mysectordata = sectordata
			self.myuniverse = pricedata.columns
			return 
		else:
			self.compo = self.compo.redindex_like(pricedata)
			self.comp.fillna(0, inplace =True)
			X= self.comp.sum()
			X[X==0]=nan
			X = X.dropna()
			self.myuniverse = X.index
			self.mypricedata = pricedata[self.myuniverse]
			self.mysectordata = sectordata[self.mysectordata]
			self.compo = self.compo[self.myuniverse]

	def create_pairs(self, data):
		price  data.pivot_table ('px_last', 'date','bbgid')
		sectordata = data.pivot_table('gics_sub_industry', 'date', 'bbgid').fillna('0000000000')
		sectordata = sectordata.redindex_like(price).fillna('0000000000')
		if self.backtestequityonly:
			price = price.reindex(columns= [u for u in price.columns if 'equity' in u.lower()])
			sectordata = sectordata.reindex(columns= [u for u in price.columns if 'equity' in u.lower()])

		self.limitDataToCompo(price, sectordata)
		self.stock_return = self.mypricedata.pct_change().fillna(0)
		self.total_return = self.stock_return.cumsum()
		self.price_list.append(self.mypricedata)
		TOT = array(self.total_return)
		stock_name = self.total_return.columns
		date = self.total_return.index_name
		sector_matrix = ones((1, TOT.shape[1]))
		pair_direction = []
		pair_row = []
		pair_column =[]
		Ns = sector_matrix.sum(axis=1)
		print(Ns)
		N = int((Ns*(Ns-1)).sum()/2)
		print(N)
		pair_total_return = zeros((TOT.shape[0], N))
		J = 0

		for sec in sector_matrix:
			stocks = list(where(sec==1)[0])
			while stocks:
				i = stocks.pop(0)
				for j in stocks:
					pair_total_return[:, J]=TOT[:, i]-TOT[:,j]
					pair_direction.append(1)
					pair_column.append(i)
					pair_row.append(J)
					pair_direction.append(-1)
					pair_column.append(j)
					pair_row.append(J)
					J +=1
			pair_stock_matrix = sparse.coo_matrix((pair_direction, (pair_row, pair_column)), (N, TOT.shape[1]))
			pair_stock_matrix = pair_stock_matrix.todense()
			self.pair_total_return = pa.DataFrame(pair_total_return, date)
			self.pair_stock_matrix = pa.DataFrame(pair_stock_matrix, columns = stock_name)
			self.make_pair_composition()
			if not self.first_run_done:
				print('Corrlation')
				self.get_correlation()
				print(self.correlation.dates)


	def pair_position_to_stock_psoition(self, pair_position):
		return pair_position.fillna(0).dot(self.pair_stock_matrix.fillna(0))
	def make_pair_composition(self):
		if self.compo is None:
			self.pair_compo = None
			return 
		else:
			self.pair_compo = self.compo.dot(self.pair_stock_matrix.abs().T)
			self.pair_compo[self.pair_compo!=2]=0
			self.pair_compo[self.pair_compo==2]=1
	def apply_compo(self, alpha, decalage = True):

		'''
		neutralize the alpha of the pairs not in the compo
		'''
		if decalage:
			X = self.pair_compo.shift().fillna(0)
		else:
			X= self.pair_compo
		A = alpha.copy()
		A[X==0]=nan
		return A

	def generate_alpha_function(self, pair_alpha_generator = None, generate_paire_data=True, result_alpha = False):
		'''
		return a function to be input in the backtester
		'''
		if not hasattr(self, 'pair_alpha_generator') and pair_alpha_generator is None:
			raise AttributeError("Pair alpha has not been defined yt")

		if reuse_alpha:
			return lambda x:{'alpha': self.backtesteralpha.copy()}
		if not pair_alpha_generator is None:
			self.pair_alpha_generator = pair_alpha_generator

	def generate_alpha(backtester_data):
		self.data = backtester_data
		if self.old_compo is None and self.index_name is not None:
			if not self.first_run_done:
				self.compo= (backtester_data['%s_weight'%self.index_name.lower()]>0 & backtester_data['tradable']).unstack()

		if generate_paire_data:
			self.create_pairs(backtester_data)
			self.first_run_done= True
		self.pair_alpha = self.pair_alpha_generator(self)
		self.pair_alpha = self.apply_compo(self.pair_alpha)
		self.pair_alpha_list.append(self.pair_alpha)
		self.alpha = self.pair_position_to_stock_psoition(self.pair_alpha)
		self.backtesteralpha = self.alpha.stack().reindex_like(backtester_data['px_last'])
		self.alpha_list.append(self.backtesteralpha.copy())
		return {'alpha':self.backtesteralpha.copy()}
	return generate_alpha
