import pandas as pd
import numpy as np

def generate_linear_weight(count):
	seq = np.linspace(1, count, count)
	return pd.Series(data= seq/seq.sum())

def generate_exponential_weight(count, alpha):
	seq = np.linspace(count-1,0, count)
	seq = np.power(1-alpha, seq)
	return pd.Series(data= seq/seq.sum())

if __name__=='__main__':
	print(generate_linear_weight(100))
	print(generate_exponential_weight(100,0.9))