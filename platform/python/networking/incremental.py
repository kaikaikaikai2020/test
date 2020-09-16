import pandas as pd
import numpy as np
import math
def ema_one(pre, cur, halflife):
	alpha = 1- math.exp(math.log(0.5)/halflife)
	return (1-alpha)*pre +alpha*cur
