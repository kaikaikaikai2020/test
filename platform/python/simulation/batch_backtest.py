from .backtest import Backtest
import copy

def batch_run(sim_params = None, alg_params_base = None, alg_params_overrides = None, alg_params_grid = None, **kwargs):
	alg_params_expand ={}
	if alg_params_overrides is not None:
		for k, v in alg_params_overrides.items():
			alg_params = copy.deepcopy(alg_params_base)
			for i, j in v.items():
				keys = i.split('.')
				value = alg_params
				for key_idx in range(0, len(keys)-1):
					value = value.get(keys[key_idx])
					if value is None:
						raise ValueError("fail to find the param {}".format(i))

				value[keys[-1]] = j

			alg_params_expand[k] = alg_params
	elif alg_params_grid is not None:
		from sklearn.model_selection import ParameterGrid
		grids = list (ParameterGrid(alg_params_grid))

		k = 0
		for g in grids:
			alg_params = copy.deepcopy(alg_params_base)
			for i, j in g.items():
				keys = i.split('.')
				value = alg_params
				for key_idx in range(0, len(keys)-1):
					value = value.get(keys[key_idx])
					if value is None:
						raise ValueError("fail to find the param {}".format(i))

				value[keys[-1]] = j

			k = k+1
			alg_params_expand[k] = alg_params

	results= {}
	for k, v in alg_params_expand.items():
		bt = Backtest(sim_params = sim_params)
		result = bt.run(alg_params=v, **kwargs)
		results[k] =result.id

	return results

	