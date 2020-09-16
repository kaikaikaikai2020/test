import configparser

def config_to_dict(config):
	d = dict(config._sections)
	for k in d:
		d[k] = dict(config._defaults, **d[k])
		d[k].pop('__name__', None)
	return d

class Config(object):
	_config = None

	@staticmethod
	def read(path):
		print("Reading config file:", path)
		config = configparser.ConfigParser()
		config.read(path)
		Config._config = config_to_dict(config)

	@staticmethod
	def get():
		return Config._config