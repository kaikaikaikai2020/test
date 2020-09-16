from numpy import *
from cvxopt_matrix_fix import *
from cvxopt import *
solvers.options['show_progress']=False
from myNone import *
import pandas as pa

class trading_position_structure:
	def __init__(self, max_trading = None, max_position = None):
		self.max_trading = max_trading
		self.max_position=max_position
		self.constraint_type = "trading_position_constraint"

	def __getitem__(self, date):
		return self
	def apply_target(self, x):
		return self

class cost_structure:
	def __init__(self, cost=None, cost_building=None, cost_cuting = None):
		self.constraint_type = "cost_constraint"
		self.cost = cost
		if cost_building is not None:
			self.cost_building = cost_building
		elif cost is None:
			self.cost_building = 0
		else:
			self.cost_building = cost

		if cost_cuting is not None:
			self.cost_building = cost_building
		elif cost is None:
			self.cost_cuting = 0
		else:
			self.cost_cuting = cost

		if cost is None and cost_building is None and cost_cuting is None:
			self.no_cost = True
		else:
			self.no_cost = False

	def apply_target(self, x, date= None):
		if date is not None and date.weekday()==0:
			return cost_structure(cost_building = self.cost_building, cost_cuting= self.cost_cuting)
		elif date is not None and date.weekday()==1:
			return cost_structure(cost_building = self.cost_building, cost_cuting = self.cost_cuting)
		else:
			return self
	def __getitem__(self, date):
		return self

class beta_structure:
	def __init__(self, beta_matrix= myNone(), beta_neutral = False, sector_beta_netrual=False, sector_matrix = None):
		self.constraint_type = "beta_constraint"
		self.beta_matrix = beta_matrix
		self.beta_neutral = beta_neutral
		self.sector_beta_netrual = sector_beta_netrual
		self.sector_matrix = sector_matrix

		if beta_neutral and sector_beta_netrual: 
			raise
	def apply_target(self, targetable):
		if self.beta_matrix is None:
			return self
		elif not self.sector_beta_netrual:
			self.beta_matrix= array(self.beta_matrix.loc[:,targetable])
			return self
		else:
			self.beta_matrix = array(self.beta_matrix.loc[:targetable])
			self.sector_matrix = array(self.sector_matrix.loc[:, targetable])
			return self
class beta_structure_iterator(beta_structure):
	def __getitem__(self, date):
		return beta_structure(self.beta_matrix.getByDate(date), self.beta_neutral, self.sector_beta_netrual, self.sector_matrix)
class sector_structure:
	def __init__(self, sector_matrix = None, sector_netural = False, sector_limit = None):
		self.sector_matrix = sector_matrix
		self.sector_netural = sector_netural
		self.sector_limit = sector_limit
		self.constraint_type = "sector_constraint"

	def squareSector(self, _Serie):
		sec = set(_Serie)
		S = pa.DataFrame(0, index = sec, columns = _Serie.index)
		for s in _Serie.index:
			S.loc[_Serie.loc[s],s]=1
		return  S

	def __getitem__(self, date):
		if self.sector_matrix is None:
			return sector_structure(None)
		else:
			return sector_structure(self.squareSector(self.sector_matrix.loc[date]), sector_netural=self.sector_netural, sector_limit = self.sector_limit)

	def apply_target(self, targetable):
		if self.sector_matrix is None:
			return sector_structure(None)
		else:
			sub_sector_matrix = self.sector_matrix.loc[:, targetable]
			good_index = where(sub_sector_matrix.sum(axis=1)>0)[0]
			if len(good_index):
				sub_sector_matrix = sub_sector_matrix= array(sub_sector_matrix.iloc[good_index])
			else:
				sub_sector_matrix = None
			return sector_structure(sub_sector_matrix, self.sector_netural, self.sector_limit)
class delta_structure:
	def __init__(self, delta_neutral= True):
		self.delta_neutral = delta_neutral
		self.constraint_type = "delta_constraint"

	def __getitem__(self, i):
		return self
	def apply_target(self, targetable):
		return self
class risk_structure:
	def __init__(self, covariance_matrix= None, omega=None):
		self.omega = omega
		self.covariance_matrix = covariance_matrix
		self.constraint_type = 'risk_contraint'

	def __getitem__(self, date):
		if self.covariance_matrix is not None:
			C = self.covariance_matrix.getByDate(date)
			return risk_structure(C, self.omega)
		else:
			return self
	def apply_target(self, targetable):
		if self.covariance_matrix is None:
			return self
class constraint_wrapper:
	def __init__(self):
		self.trading_position_constraint = trading_position_structure()
		self.sector_constraint = sector_structure()
		self.delta_constraint = delta_structure()
		self.risk_contraint = risk_structure()
		self.cost_constraint = cost_structure()
	def setTrading(self, trading_max, pose_max):
		self.trading_position_constraint = trading_position_structure(trading_max, pose_max)
	def setSector(self, sector_matrix, sector_limit):
		self.sector_constraint = sector_structure(sector_matrix = sector_matrix, sector_limit = sector_limit)
		print(self.sector_constraint)
	def setRisk(self, covariance_matrix, omega):
		self.risk_contraint = risk_structure(covariance_matrix, omega)
	def setCost(self, cost_building, cost_cuting):
		self.cost_constraint = cost_structure(cost_building = cost_building, cost_cuting = cost_cuting)
	def getConstraint(self):
		return constaint_structure(self.trading_position_constraint, self.sector_constraint, self.delta_constraint, self.risk_contraint, self.cost_constraint)

class contraint_structure:
	def __init__(self, trading_position_constraint=trading_position_structure(), sector_constraint = sector_structure(), delta_constraint= delta_structure(), risk_contraint = risk_structure(), cost_constraint = cost_structure()):
		self.trading_position_constraint = trading_position_constraint
		self.cost_constraint = cost_constraint
		self.delta_constraint = delta_constraint
		self.risk_contraint = risk_contraint
		self.sector_constraint = sector_constraint
		self.constraint_list = ["trading_position_constraint", "sector_constraint", "delta_constraint", "risk_contraint", "cost_constraint"]
		self.extra_constraint = []
		if self.sector_constraint.sector_netural:
			self.delta_constraint.delta_neutral = False
	def __getitem__(self, i):
		X = constaint_structure(**dict(zip(self.constraint_list,[getattr(self, u)[i] for u in self.constraint_list])))
		for c in self.extra_constraint:
			X.addconstraint(c[i])
		return X

	def apply_target(self, targetable):
		X = constaint_structure(**dict(zip(self.constraint_list,[getattr(self, u).apply_target for u in self.constraint_list])))
		for c in self.extra_constraint:
			X.addconstraint(c[i])
		return X

	def __getattr__(self, name):
		for c in self.constraint_list:
			if hasattr(getattr(self, c), name):
				return getattr(getattr(self, c), name)
		raise AttributeError
	def addconstraint(self, constraint):
		if isinstance(constraint, cost_structure):
			raise
		self.extra_constraint.append(constraint)

class sigle_day_optim(cvxopt_matrix_fix):
	def cost_transform (self, Q, p, G, h, A, b, cost, initial, target):
		nb_of_stocks = len(p)
		newQ = hstack([Q, -Q])
		newQ = vstack([newQ, -newQ])
		newp = p +column_stack(dot(column_stack(initial), Q))
		initial_positive = (initial>0)
		initial_negative = (initial<0)
		if isinstance(cost, (float, int)):
			newp = vstack([newp+cost, -newp+cost])
		elif isinstance(cost, cost_structure):
			newp = vstack([newp+cost.cost_cuting*row_stack(initial_negative)+cost.cost_building*(1-row_stack(initial_negative)), -newp+cost.cost_cuting*row_stack(initial_positive)+cost.cost_building*(1-row_stack(initial_positive))])
		else:
			raise

		newG = hstack([G,-G])
		Tpostiveconstraint = -vstack([hstack([identity(nb_of_stocks), zeros(Q.shape)]), hstack([zeros(Q.shape), identity(nb_of_stocks)])])
		newG = vstack([newG, Tpostiveconstraint])
		newh = vstack([h-dot(G, row_stack(initial)), zeros(p.shape), zeros(p.shape)])
		newA = hstack([A, -A])
		newb = b -dot(A, row_stack(initial))
		notarget = (target ==0)
		initial_positive*=notarget
		initial_negative*=notarget
		ipo = where(initial_positive)[0]
		ine = where(initial_negative)[0]
		if len(ipo)+len(ine) >0:
			AA = zeros((len(ipo)+len(ine), 2*nb_of_stocks))
			for i , j in enumerate(ipo):
				AA[i, j] =1
			shift = len(ipo)
			for i, j in enumerate(ine):
				AA[i+shift, j+nb_of_stocks]=1
			newA = vstack([newA, AA])
			newb = vstack([newb, zeros((AA.shape[0],1))])
		return newQ, newp, newG,newh, newA, newb
	def add_beta_constraint(self, beta_info= None, sector_matrix = None, equality_constraint_a = None, equality_constraint_b = None):
		if beta_info is None:
			return equality_constraint_a, equality_constraint_b
		else:
			if beta_info.beta_neutral:
				return self.add_product_neutral_constraint(column_stack(beta_info.beta_matrix), equality_constraint_a, equality_constraint_b)
			elif beta_info.sector_netural:
				return self.add_product_neutral_constraint(beta_info.sector_matrix*beta_info.beta_matrix, equality_constraint_a, equality_constraint_b)
			else:
				print("no beta")
				return equality_constraint_a, equality_constraint_b
	def add_product_neutral_constraint(self, sector_matrix = None, equality_constraint_a = None, equality_constraint_b = None):
		if sector_matrix is None:
			return equality_constraint_a, equality_constraint_b
		else:
			S = array(sector_matrix)
			Z = abs(S).sum(axis=1)
			S = S[where(Z)]
			b = zeros((S.shape[0],1))
			if equality_constraint_a is None:
				return S, b
			else:
				return vstack([equality_constraint_b,S]), vstack([equality_constraint_b, b])

	def add_product_limitation_constraint(self, sector_max, sector_matrix=None, ineq_constraint_g = None, ineq_constraint_h = None):
		if sector_matrix is None:
			return ineq_constraint_g, ineq_constraint_h
		else:
			G = vstack([sector_matrix, -sector_matrix])
			h = ones((sector_matrix.shape[0],1))*sector_max
			if ineq_constraint_g is None:
				return G, h
			else:
				return vstack([ineq_constraint_g, G]), vstack([ineq_constraint_h, h, h])
	def add_convariance_matrix(self, covariance_matrix= None, omega = None, Q_matrix= None, targetable = None):
		if covariance_matrix is None:
			return Q_matrix
		elif Q_matrix is None:
			if targetable is None:
				return omega*covariance_matrix
			return omega*covariance_matrix[targetable][:,targetable]
		else:
			if targetable is None:
				return Q_matrix+0.5*omega *covariance_matrix
			else:
				return Q_matrix+0.5*omega*covariance_matrix[targetable][:,targetable]
	def add_delta_neutral_constraint(self, nb_of_stocks = None, equality_constraint_a = None, equality_constraint_b = None):
		if nb_of_stocks is not None:
			A = ones((1, nb_of_stocks))
			b = array([0.])
			return A, b
		else:
			A = ones((1, equality_constraint_a.shape[1]))
			b = array([0.])
			return vstack([equality_constraint_a, A]), vstack([equality_constraint_b, b])
	def add_max_position_constraint_structure(self, adv_constraint, ineq_constraint_g= None, ineq_constraint_h = None):
		nb_of_stocks = len(adv_constraint.max_position)
		return self.add_max_position_constraint(adv_constraint.max_position, nb_of_stocks, ineq_constraint_g = ineq_constraint_g, ineq_constraint_h = ineq_constraint_h)

	def add_max_position_contraint(self, max_pose, nb_of_stocks= None, ineq_constraint_g= None, ineq_constraint_h = None):
		if nb_of_stocks is None:
			nb_of_stocks = ineq_constraint_g.shape[1]

		I = identity(nb_of_stocks)
		h = ones((nb_of_stocks, 1))*max_pose
		G = vstack([I, -I])
		h = vstack([h, h])

		if ineq_constraint_g is None:
			return G, h
		else:
			return vstack([ineq_constraint_g, G]), vstack([ineq_constraint_h,h])
	def add_max_trading_csonstraint_structure(self, initial_positive, adv_constraint, ineq_constraint_g=None, ineq_constraint_h=None, incompo = None):
		max_trading = adv_constraint.max_trading
		nb_of_stocks = len(initial_position)
		return self.add_product_limitation_constraint(initial_position, max_trading, nb_of_stocks, ineq_constraint_g=ineq_constraint_g, ineq_constraint_h = ineq_constraint_h, incompo = incompo)
	def add_max_trading_constraint(self, initial_position, max_trading, nb_of_stocks=None, ineq_constraint_g=None, ineq_constraint_h=None, incomp=None):
		if nb_of_stocks is None:
			nb_of_stocks = len(initial_position)

		I = identity(nb_of_stocks)
		if incompo is None:
			h1 = ones((nb_of_stocks,))*max_trading+initial_position
			h2 = ones((nb_of_stocks,))*max_trading- initial_position
		else:
			h1 = ones((nb_of_stocks,))*max_trading+initial_position
			h2 = ones((nb_of_stocks,))*max_trading- initial_position
			notincompo=~incompo
			tosell = (initial_position >0) *notincompo
			if tosell.sum():
				h1[tosell] = maximum(0, initial_position[tosell]-max_trading)
				h2[tosell] = 0
			tobuy = (initial_position<0 )*notincompo
			if tobuy.sum():
				h2[tobuy] = maximum(0, initial_position[tobuy]-max_trading)
				h1[tobuy] =0
		G = vstack([I, -I])
		h = vstack([row_stack(h1), row_stack(h2)])
		if ineq_constraint_g is None:
			return G, h
		else:
			return vstack([ineq_constraint_g, G]), vstack([ineq_constraint_h,h])

	def single_theo_optim (self, target_position, initial_position, max_pose, max_trading, delta_neutral = True, covariance_matrix= None, omega = None, targetable = None, solve = True, sector_matrix = None, sector_netural = False, sector_limit = None, beta_info= None):
		nb_of_stocks = len(target_position)
		G, h = self.add_max_position_constraint(max_pose, nb_of_stocks)
		G, h = self.add_max_trading_constraint(initial_position, max_trading, ineq_constraint_g=G, ineq_constraint_h = h)
		if sector_netural:
			if len(where(sector_matrix.sum(axis=0)==1)[0])<nb_of_stocks: 
				A, b = self.add_delta_neutral_constraint(nb_of_stocks)
				if delta_neutral:
					A, b = self.add_product_neutral_constraint(sector_matrix, A, b)
			else:
				A, b = self.add_product_neutral_constraint(sector_matrix)
		elif delta_neutral:
			A, b = self.add_delta_neutral_constraint(nb_of_stocks)
		else:
			A = None
			b = None
		A, b = self.add_beta_constraint(beta_info, sector_matrix, A, b)

		if sector_limit is not None:
			G, h = self.add_product_limitation_constraint(sector_limit, sector_matrix, G,h)
		p = 2*row_stack(target_position)
		# p -2 *row_stack(target_position)

		Q = 2*identity(nb_of_stocks)
		Q = self.add_convariance_matrix(covariance_matrix, omega, Q,targetable)

		if solve:
			sol = self.ownqp(Q, p, G,h, A, b)
			return self.retrieve_matrix(sol['x'])
		else:
			return Q, p, G, h,A, b

class theo_optim(single_theo_optim):
	@staticmethod
	def provide_sector_matrix(total_sector_matrix, targetable = None):
		if total_sector_matrix is None:
			return None
		if targetable is None:
			sub_sector_matrix = total_sector_matrix
		else:
			sub_sector_matrix = total_sector_matrix[:, targetable]
		good_index = where(sub_sector_matrix.sum(axis=1)>0)[0]

		if len(good_index):
			return sub_sector_matrix[good_index]
		else:
			return None

	def provide_beta_matrix(self, beta, targetable):
		if beta is None:
			return None
		else:
			beta.apply_target(targetable)
			return beta
			






























