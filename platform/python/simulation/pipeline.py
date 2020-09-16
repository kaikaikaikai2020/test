import os
import pandas as pd

def save_pipelines(pipeline_path, pipelines):
	if not os.path.exists(pipeline_path):
		os.mkdir(pipeline_path)

	for p, dfs in pipelines.items():
		parent_path = os.path.join(pipeline_path, p)
		if isinstance(dfs, pd.Series) or isinstance(dfs, pd.DataFrame):
			path = parent_path +' .hdf'
			dfs.to_hdf(path, key='data')
		elif isinstance(dfs, dict):
			if not os.path.exists(parent_path):
				os.mkdir(parent_path)

			for c, s in dfs.items():
				path = os.path.join(parent_path, c+'.hdf')
				s.to_hdf(path, key='data')

def load_pipelines(pipeline_path, pipeline_names = None):
	pipeline_results = {}
	if not os.path.exists(pipeline_path):
		print("pipelines path {} doesnt exist".format(pipeline_path))
		return pipeline_results

	dirs = os.listdir(pipeline_path)
	for p in dirs:
		if '.hdf' in p:
			p = p[:-4]
		if pipeline_names is None or (pipeline_names is not None and p in pipeline_names):
			parent_path = os.path.join(pipeline_path, p)
			path = parent_path +'.hdf'
			if os.path.exists(path):
				df = pd.read_hdf(path, key='data')
				pipeline_results[p] =df
			elif os.path.exists(parent_path):
				files = os.listdir(parent_path)
				pipeline_results[p] ={}
				for f in files:
					path = os.path.join(parent_path, f)
					name = f.split('.')[0]
					print('loading pipeline {} {}'.format(p, f))
					df = pd.read_hdf(path, key='data')
					pipeline_results[p][name]=df

	return pipeline_results
	