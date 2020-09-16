from cvxpy import *
import math

def tan_cost(x, lower, uppder):
	y = max_elemwise(x-lower, 0)/(upper-lower)*0.5*math.pi
	return y+1/3*power(y, 3)+2/15*power(y,5) +17/315 *power(y, 7)+62/2835*power(y,9)