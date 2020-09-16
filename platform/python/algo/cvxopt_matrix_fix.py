from covopt import matrix, solver, sparse
import struct
from numpy import array

class cvxopt_matrix_fix:
	def construct_matrix(self, numpyarray, apply_sparse=False):
		if numpyarray is None:
			return None
		if apply_sparse:
			return sparse(matrix(numpyarray))
		return matrix(numpyarray)
	def retrieve_matrix(self, cvxoptmatrix):
		return array(cvxoptmatrix)
	def ownqp(self, Q, p, G, h, A,b):
		newQ = self.construct_matrix(Q)
		newP = self.construct_matrix(p)
		newG = self.construct_matrix(G, True)
		newh = self.construct_matrix(h)
		newA = self.construct_matrix(A, True)
		newb = self.construct_matrix(b)
		return solvers.qp(newQ, newP, newG, newh, newA, newb)
	
