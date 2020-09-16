from copy import deepcopy , copy

class dotdict(dict):
	__getattr__ = dict.get
	__setattr__ = dict.__setitem__
	__delattr__ = dict.__delitem__


def to_dotdict(d):
	new_dict = {}
	for k, v in d.items():
		if isinstance(v, dict):
			dd = to_dotdict(v)
			new_dict[k] = dd
		elif hasattr(v, '__iter__') and not isinstance(v, str):
			new_list = []
			for i in v:
				if isinstance(i, dict):
					dd = to_dotdict(i)
					new_list.append(dd)

				else:
					new_list.append(i)

			new_dict[k] = new_list

		else:
			new_dict[k] = v
	return dotdict(new_dict)

def merge(src, dest):
	if dest is None:
		result = {}
	else:
		result = deepcopy(dest)

	for key, value in src.items():
		if isinstance(value, dict):
			node = result.setdefault(key, {})
			if isinstance(node, dict):
				result[key] = merge(value, node)
			else:
				result[key] = value

		else:
			result[key] = value

	return result

def compare_dict(a, b, pred= None):
	for k, v in a.items():
		if k not in b:
			if pred is None:
				print('{} not found in right dict'.format(k))

			else:
				print('{} not found in right dict'.format(pred+','+k))
		else:
			if isinstance(a[k],dict) and isinstance(b[k],dict):
				if pred is None:
					pred = k
				compare_dict(a[k], b[k], pred= pred+ '.' +k)

			else:
				if a[k]!= b[k]:
					if pred is None:
						print('{} != {} at {}'.format(a[k], b[k], k))
					else:
						print('{} != {} at {}'.format(a[k], b[k], pred+'.'+k))