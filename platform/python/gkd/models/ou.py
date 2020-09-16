import pandas as pd
import math
class OU(object):
	def __init__(self):
		self.coef = None

	def fit(self, x, weight = None):
		count = len(x)

		if (count<2):
			raise ValueError("length of data much be bigger than 2")

		n = count -1

		if weight is None:
			v_x = x.iloc[:-1].sum()
			v_y = x.iloc[1:].sum()
			x_2 = x**2
			v_xx = x_2.iloc[:-1].sum()
			v_yy = x_2.iloc[1:].sum()
			v_xy = (x*x.shift(-1))[:-1].sum()
			theta = (v_y *v_xx-v_x*v_xy)/(n *(v_xx -v_xy)- (v_x*v_x - v_x *v_y))

			theta_2 = theta*theta
			mu = -math.log((v_xy - theta *v_x -theta*v_y +n*theta_2)/(v_xx-2*theta*v_x +n*theta_2))
			e_2u = math.exp(-2*u)
			e_u = math.exp(mu)
			sigma_2 = 2*mu /(n*(1-e_2u))*(v_yy -2*e_2u*v_xy +e_2u*v_xx -2 *theta *(1-e_u)*(v_y - e_u*v_x) +n*theta_2*math.pow((1-e_u),2))

			sigma = math.sqrt(sigma_2)

		else:
			from sklearn.linear_model import LinearRegression
			import cvxpy as cvx
			import numpy as np
			a = cvx.Variale(1)
			b = cvx.Variale(1)
			expression = cvx.sum_square(np.diag(weight)*(a*x.iloc[:-1].values + b -x.iloc[1:].values))
			cons = [a>=0, a<=1]
			prob = cvx.Problem(cvx.Minimize(express), cons)
			prob.solve()
			a = a.value
			b = b.value
			print(a, b)
			theta = b/(1-a)
			mu = -math.log(a)
			sigma_2 = (x.iloc[:-1]*a +b -x.iloc[1:]).var()
			sigma = math.sqrt(sigma_2*2*mu/(1-math.exp(-2*mu)))
			self._expected = x.iloc[-1]*a +b

		self._coef=[theta, mu, sigma]
		return self
		
