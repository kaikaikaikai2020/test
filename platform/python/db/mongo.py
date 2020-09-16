from pymongo import MongoClient
class MongoDBClient(object):
	clients = {}
	def __init__(self, host=None, port = None, user= None, pwd= None, db=None):
		self.pwd = pwd
		self.host = host
		self.port = port
		self.user = user
		self.db = db
		self.uri = "mongodb://{0}:{1}@{2}:{3}/{4}?authMechanism=SCRAM-SHA-1".format(self.user, self.pwd, self.host, self.port, self.db)
		self.client = MongoClient(self.uri)

	def find(self, db, collection, statement):
		r = self.client[db][collection].find(statement)
		return [i for i in r]

	def find_one (self, db, collection, statement):
		r = self.client[db][collection].find_one(statement)
		return r

	def insert (self, db, collection, data):
		if isinstance(data, list):
			self.client[db][collection].insert_many(data).acknowledged
		elif isinstance(data, dict):
			return self.client[db][collection].insert_one(data).acknowledged
		else:
			raise ValueError("Invalid data")

	def replace(self, db, collection, filter, data):
		self.client[db][collection].replace_one(filter, data)

	def update(self, db, collection, filter, data):
		self.client[db][collection].update_one(filter, {'$set': data}).acknowledged

	@staticmethod
	def get(name):
		if name not in MongoDBClient.clients:
			section = 'Mongo_'+name
			from config.config import Config
			config = Config().get()
			if section not in config:
				raise ValueError(section + ' not found in config')
			host = config[section]['host']
			port = config[section]['port']
			user = config[section]['user']
			pwd  = config[section]['pwd']
			db = config[section]['db']
			client = MongoDBClient(host = host, port = port, user= user, pwd = pwd, db=db)
			MongoDBClient.clients[name] = client
		return MongoDBClient.clients[name]

if __name__=="__main__":
	client = MongoDBClient()
	r = client.find_template('test')
	print(r)