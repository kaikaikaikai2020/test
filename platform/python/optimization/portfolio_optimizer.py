import pandas as pd
import numpy as np
import struct
from utils.dotdict import dotdict
from utils.number import is_number, int_max, int_min
from utils.espsiln import equal_zero

from cvxopt import matrix, solvers, sparse
from cvxpy import *
from .cost_func import *

try:
	from cvxpy import sum_entries
except Exception as e:
	from cvxpy import sum as sum_entries

class PortfolioOptimizer(object):
	def __init__(self):
		self.cons = dotdict({
			'delta':0,
			'leverage' :None,
			'positions':None,
			'trade_min':None,
			'trade_max':None,
			'sector_min':None,
			'sector_max': None,
			'beta_min':None,
			'beta_max':None,
			'trade_total':None,
			'var':None,
			'var_soft': None,
			'custom':{},
			})
		self.params = dotdict({
			'gamma': None,
			'theta': None
			})
		self.x0 = None
		self.objectives = {
		'min_var' : 'max(-w*sigma*wT)',
		'max_mean' : 'max(alphaT*w)',
		'max_mean_var' : 'max(alphaT*w -0.5*gamma*w*sigma*wT)',
		'min_tracking_error' : 'max(-(w-w0)^2'
		}

		self.objective = 'max_mean'
		self.custom_objs = {}
	def print_objectives_available(self):
		for k,v in self.objectives.items():
			print(k, v)

	def set_objective(self, objective= None):
		if objective is None:
			raise ValueError("None objective")

		if objective not in self.objectives:
			self.print_objectives_available()
			raise ValueError("invalid objective")
		else:
			self.objective = objective
	def set_leverage_constraint(self, min= None, max=None):
		if max is None:
			raise ValueError("None max leverage")
		self.cons.leverage_min = min
		self.cons.leverage_max = max

	def set_delta_constraint(self, max_delta=None):
		if max_delta is None:
			raise ValueError("None max delta")
		self.cons.delta = max_delta
		
	def set_position_constraint(self, min=None, max = None):
		if min is None:
			raise ValueError("none min positions")

		if max is None:
			raise ValueError("none max positions")

		self.cons.pos_min = min
		self.cons.pos_max = max

	def set_trade_contraint(self, min = None, max = None):
		if min is None:
			raise ValueError("none min trade")

		if max is None:
			raise ValueError("none max trade")

		self.cons.trade_min = min
		self.cons.trade_max = max

	def set_trade_total_constraint(self, value):
		self.cons.trade_total = value

	def set_sector_contraint(self, min= None, max=None):
		self.cons.sector_min = min
		self.cons.sector_max = max

	def set_beta_contraint(self, min= None, max=None):
		self.cons.beta_min = min
		self.cons.beta_max = max
	def set_variance_contraint(self, value):
		self.cons.variance = value
		
	def set_variance_contraint_soft(self, lo, hi, factor):
		self.cons.var_soft - {'lo':lo, 'hi':hi, 'factor': factor}

	def set_risk_coef(self, value = None):
		if value is None:
			raise ValueError("None risk coef")

		self.params.gamma = value

	def set_tcost_coef(self, value = None):
		if value is None:
			raise ValueError("None tcost coef")

		self.params.theta = value

	def disable_tcost_coef(self, name, expr, coef):
		self.cons.custom[name] = dotdict({})
		con = self.cons.custom[name]
		con.expr = expr
		con.coef = dotdict(coef)

	def add_custom_obj(self, name, expr, coef):
		self.custom_objs[name] = dotdict({})
		con = self.custom_objs[name]
		con.expr = expr
		con.coef = dotdict(coef)

	def set_custom_constraint_coef(self, name , **kwargs):
		if name in self.cons.custom:
			coef = self.cons.custom[name].coef
			for k, v in kwargs.items():
				coef[k]=v

	def set_custom_obj_coef(self, name, **kwargs):
		if name in self.custom_objs:
			coef = self.custom_objs[name].coef
			for k, v in kwargs.items():
				coef[k] =v 

	def _add_custom_objs(self, expr, x):
		result = expr
		for i, j in self.custom_objs.items():
			coef = j.coef
			obj = eval(j.expr)
			result -=obj #need to think about it minus or plus

		return result

	def solve(self,initial_positions = None, alpha = None, target_positions = None, cov = None, beta = None, sectors= None, objective = None, logging = False, solver = None, two_norm_tcost = False, integer = False, position_transform = None, weight = None, norm_factor =1, **kwargs):
		n = None
		x = None
		target = None
		ret = None
		risk = None
		tcost = None
		tracking_error = None
		self.x0 = initial_positions
		self.cov = cov
		self.beta = beta
		self.sectors = sectors

		if objective is not None:
			if objective not in self.objectives:
				self.print_objectives_available()
				raise ValueError("invalid objectives")

		else:
			objective = self.objective

		if objective == 'max_mean':
			if alpha is None:
				raise ValueError ("None alpha")

			n = len(alpha)

			if integer:
				x = Variable(n, integer= True)
			else:
				x = Variable(n)

			expr = alpha.T *x

		elif objective == 'max_mean_var':
			if alpha is None:
				raise ValueError("None alpha")

			if self.params.gamma is None or cov is None:
				raise ValueError("none variance coef or none covariance matrix")

			n = len(alpha)
			if integer:
				x = Variable(n, integer= True)
			else:
				x = Variable(n)

			expr = alpha.T *x

		elif objective == "min_var":
			if cov is None:
				raise ValueError("none covariance matrix")

			n = len(cov)
			if integer:
				x = Variable(n, integer= True)
			else:
				x = Variable(n)

			expr = -quad_form(x, cov)
		elif objective =='min_tracking_error':
			if target_positions is None:
				raise ValueError("none target positions")

			if position_transform is not None:
				n = len (position_transform)
				if integer:
					x = Variable(n, integer= True)
				else:
					x = Variable(n)
				if len(target_positions.shape) ==1:
					target_func = position_transform.T *x -target_positions
				else:
					target_func = position_transform.T *x -target_positions.T[0]

			else:
				n = len(target_positions)
				if integer:
					x = Variable(n, integer= True)
				else:
					x = Variable(n)

				target_func = x-target_positions

			if weight is not None:
				target_func - target_func * weight

			expr = - norm(target_func, norm_factor)
		else:
			raise ValueError("unsupported objective")

		if self.params.gamma is not None and cov is not None and objective not in ('max_mean', 'min_var'):
			risk = quad_form (x, cov)
			expr = expr - 0.5*self.params.gamma *risk

		if self.params.theta is not None:
			if two_norm_tcost:
				if self.x0 is not None:
					if isinstance(self.params.theta, np.ndarray):
						tcost = norm(self.params.theta *(x-self.x0),2)
					else:
						tcost = self.params.theta *sum_squares(x - self.x0)

				else:
					if isinstance(self.params.theta, np.ndarray):
						tcost = norm(self.params.theta *x, 2)
					else:
						tcost = self.params.theta *sum_squares(x)

			else:
				if self.x0 is not None:
					if isinstance(self.params.theta, np.ndarray):
						tcost = norm(self.params.theta*abs(x-self.x0),1)
					else:
						tcost = self.params.theta *sum_entries(abs(x-self.x0))
				else:
					if isinstance(self.params.theta, np.ndarray):
						tcost = norm(self.params.theta*abs(x),1)
					else:
						tcost = self.params.theta *sum_entries(abs(x))

			expr = expr - tcost
		if self.cons.var_soft is not None:
			var_soft = self.cons.var_soft
			var = quad_form(x, self.cov)
			expr = expr - var_soft['factor'] *tan_cost(var, var_soft['lo'], var_soft['hi'])

		expr = self._add_custom_objs(expr, x)

		target = Maximize(expr)

		cons = self._construct_constraints(x)

		prob = Problem(target, cons)
		if solver is None:
			solver = 'CVXOPT'

		prob.solve(solver = solver, **kwargs)

		if x.value is None:
			print("status: ", prob.status)
			return None

		else:
			if logging:
				print('optimal value', prob.value)

				if ret is not None:
					print('ret: ', ret.value )

				if risk is not None:
					print('risk: ', risk.value)

				if tcost is not None:
					print('tcost: ', tcost.value)

				if tracking_error is not None:
					print('tracking_error: ', tracking_error.value)

				if hasattr(x.value, 'A1'):
					print('positions: ', x.value.A1)
				else:
					print('positions:', x.value)

		if hasattr(x.value, 'A1'):
			r = [0 if equal_zero(i) else i for i in x.value.A1]
		else:
			if isinstance(x.value, np.ndarray):
				r = [0 if equal_zero(i) else i for i in x.value]
			else:
				r = [0 if equal_zero(x.value) else x.value]

		if integer:
			r = [round(i) for i in r]

		return r

	def _construct_constraints(self, x)	:
		cons = []
		if self.cons.delta is not None:
			cons.append(abs(sum_entries(x))<=self.cons.delta)

		if self.cons.leverage_max is not None:
			cons.append(norm(x,1)<=self.cons.leverage_max)

		if self.cons.leverage_min is not None:
			cons.append(norm(x,1)>=self.cons.leverage_min)			

		if self.cons.pos_min is not None:
			min_pos = None
			if is_number(self.cons.pos_min):
				min_pos = np.full(x.size, self.cons.pos_min)

			else:
				min_pos = self.cons.pos_min

			cons.append(x>=min_pos.T)

		if self.cons.pos_max is not None:
			max_pos = None
			if is_number(self.cons.pos_max):
				max_pos = np.full(x.size, self.cons.pos_max)

			else:
				max_pos = self.cons.pos_max

			cons.append(x<= max_pos.T)

		if self.cons.trade_min is not None:
			trade_min = None
			if is_number(self.cons.trade_min):
				trade_min = np.full(x.size, self.cons.trade_min)
			else:
				trade_min = self.cons.trade_min

			if self.x0 is None:
				cons.append(x>=trade_min.T)
			else:
				cons.append((x-self.x0.T)>= trade_min.T)

		if self.cons.trade_max is not None:
			trade_max = None
			if is_number(self.cons.trade_max):
				trade_max = np.full(x.size, self.cons.trade_max)
			else:
				trade_max = self.cons.trade_max

			if self.x0 is None:
				cons.append(x<=trade_max.T)
			else:
				cons.append((x-self.x0.T)<= trade_max.T)

		if self.cons.trade_total is not None:
			if self.x0 is None:
				cons.append(norm(x,1)<= self.cons.trade_total)
			else:
				cons.append(norm(x-self.x0.T, 1)<=self.cons.trade_total)

		if self.cons.variance is not None:
			if self.cov is None:
				raise ValueError("None cov matrix")

			else:
				var = quad_form(x, self.cov)
				cons.append(var <= self.cons.variance)

		if self.cons.beta_min is not None:
			cons.append((self.beta.T*x)>=self.cons.beta_min)

		if self.cons.beta_max is not None:
			cons.append((self.beta*x)>= self.cons.beta_max)
		if self.cons.sector_min is not None:
			for v in self.sectors:
				cons.append((v*x)>=self.cons.sector_min)

		if self.cons.sector_max is not None:
			for v in self.sectors:
				cons.append((v*x)<=self.cons.sector_max)

		for i, j in self.cons.custom.items():
			coef - j.coef
			con = eval(j.expr)
			cons.append(con)

		return cons

if __name__ =='__main__':
	opt = PortfolioOptimizer()
	opt.set_delta_constraint(0)
	opt.set_leverage_constraint(10)
	opt.set_position_constraint(min=-1, max=1)
	opt.set_trade_contraint(min=-.5, max =0.5)
	opt.set_riks_coef(1)

	









