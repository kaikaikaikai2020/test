import pandas as pd
import numpy as np
import struct
from utils.dotdict import dotdict
from utils.number import is_number, int_max, int_min
from utils.epsilon import equal_zero

from cvxopt import matrix, solvers, sparse
from cvxpy import *
from optimization.cost_func import *

class TrackingOptimizer(object):
	def __init__(self):
		self.cons = dotdict({
			'delta':None,
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
		self.custom_objs={}
		self.disable_tcost = False
	def set_leverage_constraint(self, max_leverage=None):
		if max is None:
			raise ValueError("None max leverage")
		self.cons.leverage_max = max_leverage
	def set_delta_constraint(self, max_delta=None):
		if max_delta is None:
			raise ValueError("None max delta")
		self.cons.delta = max_delta

	def set_position_constraint(self,  max_positions = None):

		if max_positions is None:
			raise ValueError("none max positions")

		self.cons.positions = max_positions
	def set_trade_contraint(self, min = None, max = None):
		if min is None:
			raise ValueError("none min trade")

		if max is None:
			raise ValueError("none max trade")

		self.cons.trade_min = min
		self.cons.trade_max = max

	def set_trade_total_constraint(self, value):
		self.cons.trade_total = value

	def set_variance_contraint(self, value):
		self.cons.variance = value

	def set_variance_contraint_soft(self, lo, hi, factor):
		self.cons.var_soft - {'lo':lo, 'hi':hi, 'factor': factor}

	def set_risk_coef(self, value = None):
		if value is None:
			raise ValueError("None risk coef")

		self.params.gamma = value

	def set_tcost_coef(self, value = None, pos_value = None, neg_value = None):
		if pos_value is None or neg_value is None:
			self.params.pos_theta = value
			self.params.neg_theta = value
		else:
			self.params.pos_theta = pos_value
			self.params.neg_theta = neg_value

	def disable_tcost(self):
		self.disable_tcost = True

	def enable_tcost(self):
		self.disable_tcost = False

	def add_custom_obj(self, name, expr, coef):
		self.custom_objs[name] = dotdict({})
		con = self.custom_objs[name]
		con.expr = expr
		con.coef = dotdict(coef)

	def add_custom_contraint(self, name, expr, coef):
		self.cons.custom[name] = dotdict({})
		con = self.cons.custom[name]
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
			result +=obj

		return result

	def solve(self,initial_positions = None, target_tracking = None, compo_weight= None, cov = None, logging= False, solver = None, **kwargs):
		n = None
		x = None
		target = None
		risk = None
		tcost = None
		tracking_error = None

		self.x0 = initial_positions
		self.cov = cov

		if target_tracking is None:
			raise ValueError("None target tracking")
		n = len(compo_weight[0])
		x = Variable(n)
		expr = -norm(compo_weight*x -target_tracking)

		if self.params.gamma is not None and cov is not None:
			risk = quad_form(x, cov)
			expr = expr -0.5*self.params.gamma*risk

		if (not self.disable_tcost) and self.params.pos_theta is not None:
			if self.x0 is not None:
				tcost = norm(pos(x-self.x0)*self.params.pos_theta.T +neg(x-self.x0)*self.params.neg_theta.T, 1)
			else:
				tcost = norm(self.params.pos_theta*pos(x) +self.params.neg_theta*neg(x),1)
			expr = expr - tcost

		if self.cons.var_soft is not None:
			var_soft - self.cons.var_soft
			var = quad_form(x, self.cov)
			expr = expr - var_soft['factor'] +tan_cost(var, var_soft['lo'], var_soft['high'])

		expr = self._add_custom_objs(expr, x)

		target = Maximize(expr)
		cons = self._construct_constraints(x)
		prob = Problem (target, cons)
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

	def _construct_constraint(self,x):
		cons = []
		if self.cons.delta is not None:
			cons.append(abs(sum_entries(x))<=self.cons.delta)

		if self.cons.leverage is not None:
			cons.append(norm(x,1)<=self.cons.leverage)

		if self.cons.positions is not None:
			max_positions = None
			if is_number(self.cons.positions):
				max_positions = np.full(x.size, self.cons.positions)

			else:
				max_positions = self.cons.positions


			cons.append(x<= max_positions.T)

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

		for i, j in self.cons.custom.items():
			coef - j.coef
			con = eval(j.expr)
			cons.append(con)

		return cons
