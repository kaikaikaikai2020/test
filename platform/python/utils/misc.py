import pandas as pd

def infer_freq(df):
	if len(df.index.names) >1:
		time_index = df.index.levels[0]
	else:
		time_index = df.index

	try:
		freq = pd.infer_freq(time_index)
		if freq is not None:
			return freq

	except Exception as e:
		print(e)

		return None

	unique_time = time_index.unique()
	unique_delta = unique_time[1:] - unique_time[:-1]
	min_delta = unique_delta.min()

	if min_delta >= pd.Timedelta(days=1):
		return 'D'

	elif min_delta >= pd.Timedelta(hours =1):
		return 'H'
	elif min_delta >= pd.Timedelta(minutes=1):
		return 'T'

	elif min_delta >= pd.Timedelta(seconds=1):
		return 'S'
	else:
		return None