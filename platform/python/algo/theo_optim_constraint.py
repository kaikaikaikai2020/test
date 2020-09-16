from theo_optim import *
from scipy.linalg import svd

class single_day_optim_constraint(single_day_optim):
	optim_type = "normal"
	def manage_constraint(self, contraint, target, initial_position, Q_matrix = none, p_matrix = None, ineq_constraint_g=None, ineq_constraint_h=None,equlity_constraint_a =None, equlity_constraint_b = None, incompo=None):
		if self.optim_type =='cost' and not isinstance(constraint, cost_structure)		:
			raise
		if isinstance(constraint, trading_position_structure):
			if constraint.max_trading is not None:
				ineq_constraint_g, ineq_constraint_h = self.add_max_trading_constraint(initial_position, constraint.max_trading, ineq_constraint_g =ineq_constraint_g, ineq_constraint_h = ineq_constraint_h, incompo= incompo)
			if constraint.max_trading is not None:
				ineq_constraint_g, ineq_constraint_h = self.add_max_trading_constraint(constraint.max_trading, ineq_constraint_g = ineq_constraint_g, ineq_constraint_h=ineq_constraint_h, incompo =incompo)
			elif isinstance(constraint, delta_structure):
				if constraint.delta_neutral:
					if equlity_constraint_a is None:
						equlity_constraint_a, equlity_constraint_b = self.add_delta_neutral_constraint(len(target))
					else:
						equlity_constraint_a, equlity_constraint_b = self.add_delta_neutral_constraint(equlity_constraint_a = equlity_constraint_a, equlity_constraint_b=equlity_constraint_b)
				else:
					pass
			elif isinstance(constraint, sector_structure):
				if constraint.sector_matrix is not None:
					if constraint.sector_netural:
						equlity_constraint_a, equlity_constraint_b = self.add_product_neutral_constraint(constraint.sector_matrix, equlity_constraint_a=equlity_constraint_a, equlity_constraint_b=equlity_constraint_b)
					elif constraint.sector_limit is not None:
						ineq_constraint_g, ineq_constraint_g = self.add_product_limitation_constraint(constraint.sector_limit, constraint.sector_matrix,, ineq_constraint_g=ineq_constraint_g, ineq_constraint_h=ineq_constraint_h)
					else:
						raise
				else:
					pass
			elif isinstance(constraint, beta_structure):
				if constraint.beta_matrix is not None:
					equlity_constraint_a, equlity_constraint_b = self.add_beta_contraint(contraint, equlity_constraint_a=equlity_constraint_a, equlity_constraint_b=equlity_constraint_b)
			elif isinstance(constraint, risk_structure):
				Q_matrix = self.add_covariance_matrix(constraint.covariance_matrix, constraint.omega, Q_matrix=Q_matrix)
			elif isinstance(constraint, cost_structure):
				if constraint.no_cost:
					pass
				else:
					self.optim_type ="cost"
					return self.cost_transform(Q_matrix,p_matrix, ineq_constraint_g, ineq_constraint_h, equlity_constraint_a, equlity_constraint_b, constraint, initial_position, target)
			else:
				raise
			return Q_matrix, p_matrix,ineq_constraint_g, ineq_constraint_h, equlity_constraint_a,equlity_constraint_b

	
	def single_simple_theo_optim_constraint(self, target_position, initial_position, constraint, solve=True, incomp=None):
		nb_of_stocks = len(target_position)
		p = -2*row_stack(target_position)
		Q = 2*identity(nb_of_stocks)
		G=None
		h=None
		A=None
		b = None
		for extra_constraint in constraint.extra_constraint:
			Q, p, G, h, A, b =self.manage_constraint(constraint = extra_constraint,target=target_position,initial_position = initial_position, Q_matrix =Q, p_matrix=p, ineq_constraint_g=G, ineq_constraint_h=h, equlity_constraint_a=A, equlity_constraint_b=b, incompo=incompo)
		for constraint_type in constraint.constraint_list:
			Q, p, G, h, A, b =self.manage_constraint(constraint = getattr(constraint, constraint_type),target=target_position,initial_position = initial_position, Q_matrix =Q, p_matrix=p, ineq_constraint_g=G, ineq_constraint_h=h, equlity_constraint_a=A, equlity_constraint_b=b, incompo=incompo)

		if A is not None:
			R = linalg.matrix_rank(A)
			if R<A.shape[0]:
				U, S , V =svd(A)
				UT=U.T
				A = dot(UT,A)[:R]
				b =dot(UT, b)[:R]
		if solve:
			sol = self.ownqp(Q,p,G,h,A,b)
			return self.build_solution(sol, initial_position)
		else:
			return Q,p,G,h,A,b

	def build_solution(self, sol, initial_position=None):
		if self.optim_type =="normal":
			return self.retrieve_matrix(sol['x']).flatten()
		elif self.optim_type =='cost':
			Y self.retrieve_matrix(sol['x']).flatten()
			return initial_position+Y[:int(len(Y)/2)] -Y[int(len(Y)/2):]

class theo_optim_constraint(single_day_optim_constraint, theo_optim):
	def SingleDay(self, sodPosition, todayAlpha, today, constraint):
		self.optim_type ="normal"
		mySod = sodPosition.fillna(0)
		A = todayAlpha.loc[self.stock_return.columns].fillna(0)
		targetable1 = A.index[sorted(set(where(A!=0)))]
		S = mySod.loc[self.stock_return.columns]
		targetable2 = S.index[sorted(set(where(abs(S)>contraint.max_trading)[0]))]
		targetable = sorted(set(targetable1)|(set(targetable2)))
		if(len(targetable)==0):
			return pa.Series(0, todayAlpha.index)
		T = array(A.loc[targetable])
		incompo=T!=0

		theo = T
		prev = array(S.loc[targetable])
		single_constraint = constraint[today]
		single_constraint = single_constraint.apply_target(targetable)
		solution = self.single_simple_theo_optim_constraint(theo, prev, single_constraint, incompo=incompo)
		return pa.Series(solution, targetable).reindex_like(todayAlpha).fillna(0)
		