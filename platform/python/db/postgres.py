import os
import re
import six
import json
import socket
import getpass
import logging
import time
import psycopg2 as pg
import pyscopg2.extras as pg_extras
import numpy as np
import pandas as pd
import asyncpg
import asyncio
import nest_asyncio

from datetime import datetime
from datetime import timedelta
from functools import partial
from dateutil.tz import tzlocal
from sqlalchemy import create_engine

logger = logging.getLogger('Postgres')

class PostgresClient(object):
	clients = {}
	def __init__(self, host, port, user, password, database, async_conn= None):
		self.host = host
		self.port = port
		self.user = user
		self.pwd = password
		self.db = database
		self.conn = pg.connect(database= self.db, user= self.user, password= self.pwd, host = self.host, port = self.port)
		self.conn.autocommit = True
		nest_asyncio.apply()
		if async_conn is None:
			self.external_async_conn = False
			async def run():
				self.async_conn = await asyncpg.connect(database = self.db, user= self.user, password = self.pwd, host = self.host, port = self.port)

			asyncio.get_event_loop().run_until_complete(run())
		else:
			self.async_conn = async_conn
			self.external_async_conn = True

	def __enter__(self):
		return self

	def __exit__(self, exc_type, exc_value, traceback):
		self.close()
		if exc_type is not None:
			print((exc_type, exc_value, traceback))

	def getEngine(self):
		return create_engine("postgresql+psycopg2://{}:{}@{}:{}/{}".format(self.user, self.pwd, self.host, self.port, self.db))

		if keyspace_meta is None:
			logger.warning("Keyspace [{}] does not exist in database".format(keyspace))
			return False
		else:
			return True

	def create_table(self, schema_name, table_name, name_type_tuple_list, primary_keys= None, index_keys= None):
		logger.info("creating table {} ".format(table_name))

		name_type_list = ["{} {}".format(i[0], i[1]) for i in name_type_tuple_list]
		name_type_str = ','.join(name_type_list)
		if primary_keys is None:
			self.execute("create table if not exist {}.{} ({})".format(schema_name, table_name, name_type_str))
		else:
			self.execute("create table if not exist {}.{} ({}, primary key ({}))".format(schema_name, table_name, name_type_str, ','.join(primary_keys)))

		if index_keys is not None:
			for key in index_keys:
				self.execute('create index {0}_{2}_idx on {1}.{0} ({2})'.format(table_name, schema_name, key))

	def create_schema(self, schema):
		logger.info("creating schema {}".format(schema))

		cur = self.conn.cursor()
		cur.execute("create schema if not exists {}".format(schema))

	def execute(self, statement):
		logger.debug(statement)
		cur = self.conn.cursor()
		cur.execute(statement)

	def query(self, statement, chunksize = None):
		if chunksize is not None:
			logger.debug(statement)
			results = []

			async def run():
				async with self.async_conn.transaction():
					cur= await self.async_conn.cursor(statement)
					while True:
						r = await cur.fetch (chunksize)
						if len(r) == 0:
							break
						else: 
							results.extend(r)
			nest_asyncio.get_event_loop().run_until_complete(run())
			return results

		else:
			results = []
			async def run():
				r = await self.async_conn.fetch(statement)
				results.extend(r)

			asyncio.get_event_loop().run_until_complete(run())
			return results

	def query_table_columns(self, schema, table):
		result = self.query("select column_name from information_schema.columns where table_schema = '{}'  and table_name = '{}'".format(schema, table))
		return [i[0] for i in result]


	def query_table_pkeys(self, schema, table):
		logger.debug("calling query_table_pkeys(): {}.{}".format(schema, table))

		query = "SELECT a.attname as key_name, format_type (a.atttypid, a.atttypmode) as key_type" + "FROM pg_attribute a " +"JOIN (SELECT *, GENERATE_SUBSCRIPTS(indkey, 1) AS indkey_subscript " + "FROM pg_index) AS i " + "ON i.indisprimary AND i.indrelid = a.attrelid " + "AND a.attnum = i.indkey[i.indkey_subscript] " + "WHERE a.attrelid = '{}.{}'::regclass ".format(schema, table) + "ORDER BY indkey_subscript; "

		logger.debug(query)
		keys = []
		try:
			cur = self.conn.cursor()
			cur.execute(query)
			for result in cur:
				keys.append(result[0])
		except pg.Error as ex:
			logger.error("fail to query table primary key with pgcode={}, pgerror ={}".format(ex.pgcode, ex.pgerror))
			logger.error("sql string: {}".format(query))

			raise
		logger.debug("keys for {}.{}: {}".format(schema, table, keys))
		return keys, True


	def get_all_the_tables(self, schema, table_name_wildcard):
		query = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '{}' AND TABLE_TYPE = 'BEASE TABLE'".format(schema)
		if table_name_wildcard is not None:
			query +=" AND TABLE_NAME LIKE '{}'".format(table_name_wildcard)

		result = self.query(query)
		return [r[0] for r in result]

	def table_exists(self, schema, table):
		result = self.query("SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = '{}' AND table_name = '{}')".format(schema, table))
		return result[0][0]

	def schema_exists(self, schema):
		result = self.query("SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE schema_name = '{}' AND table_name = '{}')".format(schema))
		return result[0][0]

	def drop_table(self, schema, table):
		logger.info("drop table {}.{}".format(schema, table))
		self.execute("drop table if exists {}.{} cascade".format(schema, table))

	def truncate_table(self, schema, table):
		logger.info("Truncate table {}.{}".format(schema, table))
		self.execute("truncate table {}.{}".format(schema, table))

	def delete_table(self, schema, table):
		logger.info("delete from {}.{}".format(schema, table))
		self.execute("delete from {}.{}".format(schema, table))

	def insert(self, statement, arg):
		pass

	def insert_batch(self,schema, table, columns, arglist):
		async def run():
			awai self.async_conn.copy_records_to_table(table_name=table, schema_name = schema, columns= columns, records=arglist)
			asyncio.get_event_loop().run_until_complete(run())

	def update_batch(self, chema, table, columns, arglist, keys = None, ignore_conflict = False):
		if keys is None:
			keys, ret = self.query_table_pkeys(schema, table)
			if not ret:
				return False
		cur = self.conn.cursor()
		if ignore_conflict:
			pg_extras.execute_values(cur, "insert into {}.{} ({}) values %s on conflict ({}) do nothing".format(schema, table, ','.join(columns), ','.join(keys), ','.join(["{} = EXCLUDE.{}".format(c,c) for c in columns])))
		else:
			pg_extras.execute_values(cur, "insert into {}.{} ({}) values %s on conflict ({}) do update set {}".format(schema, table, ','.join(columns), ','.join(keys), ','.join(["{} = EXCLUDE.{}".format(c,c) for c in columns])), arglist)

	def update(self, statement):
		pass

	def delete(self, statement):
		pass
	def close(self):
		self.conn.close()
		if not self.external_async_conn:
			async def run():
				await self.asnc_conn.close()
			asyncio.get_event_loop().run_until_complete(run())


	def get_list_of_tables(self, schema= None, table_name_wildcard= None):
		where_stat = ""
		if schema is not None:
			where_stat +="table_schema = '{}'".format(schema)

		if table_name_wildcard is not None:
			where_stat += " and table_name like '{}'".format(table_name_wildcard)

		query = "select table_name from information_schema.tables"
		if len(where_stat)>0:
			query +=" where {}".format(where_stat)

		result = self.query(query)
		return result

	def from_dtype(self, type):
		if type  == np.float64 or type == np.float32:
			return 'float8'

		elif type == 0:
			return 'text'
		elif type == np.int32:
			return 'int'
		elif type == np.int64:
			return 'int8'
		elif type == np.bool_:
			return 'boolean'
		elif type == 'datetime64[ns]' or type =='<M8[ns]' or type =='timedelta64[ns]':
			return 'timestamp'

		else:
			raise ValueError("unknown type " +str(type))


	def read_dataframe(self, schema, table_name, columns = None, where= None, chunksize = 10000, include_index = False, other_condition = None):
		logger.debug("reading dataframe {} {} {} {}".format(table_name, schema, columns, other_condition, where))
		statement = "select column_name from information_schema.columns where "
		if schema is not None:
			statement +="table_schema =  '{}' and ".format(schema)

		statement +="table_name =  '{}' and ".format(table_name)
		result = self.query(statement)
		if columns is None:
			columns = [r[0] for r in result]

		primary_keys, _ = self.query_table_pkeys(schema, table_name)
		if len(primary_keys)>0 and include_index:
			columns = list(set(columns).union(set(primary_keys)))

		if schema is not None:
			table_name = schema + '.' +table_name

		statement = "select {} from {}".format(','.join(columns) if columns is not None else '*', table_name)

		if other_condition is not None:
			statement += ' ' +other_condition
		if where is not None:
			statement +=' where ' + where

		records = self.query(statement , chunksize= chunksize)

		df = pd.DataFrame()
		if columns is not None:
			df = df.from_records(records, columns = columns)
		else:
			df = df.from_records(records, columns= [r[0] for r in result])

		if include_index:
			df.set_index(primary_keys, inplace=True)

		return df


	def insert_dataframe(self, df, schema, table_name, if_exists = 'fail', index = True, index_label = None, chunksize = 10000, primary_keys= None, upsert= False, clean_cols= true, upsert_keys=None, index_keys = None, ignore_conflict = False):
		logger.info("insert datatframe start: {}".format(time.time()))		

		if index:
			number_of_index = len(df.index.names)
			df = df.reset_index()

		if clean_cols:
			col_map = {}
			for c in df.columns:
				new_c = c.lower()
				if c[0]>='0' and c[0]<='9':
					new_c = '_'+new_c

				new_c = re.sub('[^A-Za-z0-9]+', '', new_c)
				col_map[c] = new_c

			df = df.rename(columns= col_map)

		if index and primary_keys is None:
			primary_keys = df.columns[0:number_of_index]

		if if_exists =='replace':
			self.drop_table(schema, table_name)

			name_type_tuple_list = []
			for i in df.columns:
				num_type = (i, self.from_dtype(df[i].dtype))
				name_type_tuple_list.append(num_type)
			self.create_table(schema,table_name, name_type_tuple_list, primary_keys, index_keys)

		elif if_exists=='truncate':
			if self.table_exists(schema, table_name):
				self.truncate_table(schema, table_name)
			else:
				name_type_tuple_list = []
				for i in df.columns:
					num_type = (i, self.from_dtype(df[i].dtype))
					name_type_tuple_list.append(num_type)
				self.create_table(schema, table_name, name_type_tuple_list, primary_keys, index_keys)

		elif if_exists == 'delete':
			if self.table_exists(schema, table_name):
				self.delete_table(schema, table_name)

			else:
				name_type_tuple_list = []
				for i in df.columns:
					num_type = (i, self.from_dtype(df[i].dtype))
					name_type_tuple_list.append(num_type)
				self.create_table(schema,table_name, name_type_tuple_list, primary_keys, index_keys)

		elif if_exists=='append':
			if not self.table_exists(schema, table_name):
				name_type_tuple_list = []
				for i in df.columns:
					num_type = (i, self.from_dtype(df[i].dtype))
					name_type_tuple_list.append(num_type)
				self.create_table(schema,table_name, name_type_tuple_list, primary_keys, index_keys)
		else:
			raise ValueError("invalid option for if_exists : {}".format(if_exists))					

		result = self.query("select column_name from information_schema.columns where table_schema = '{}'  and table_name = '{}'".format(schema, table_name))
		columns_set = set([i[0] for i in result])
		for c in df.columns:
			if c not in columns_set:
				self.execute("alter table {}.{} and column {} {} NULL".format(schema, table_name, c, self.from_dtype(df[c].dtype)))

		number_of_chunks =1 
		if chunksize is not None:
			number_of_chunks = int(df.shape[0]/chunksize+1)
		else:
			chunksize = df.shape[0]

		for i in range(number_of_chunks):
			start = i* chunksize
			end = min((i+1)*chunksize, df.shape[0])
			slice = df.iloc[start:end]
			slice = slice.where(pd.notnull(slice), None)
			col_insert = []
			old_columns = slice.columns
			for c in slice.columns:
				if slice[c].dtype == 'datetime64[ns]' or slice[c].dtype == '<M8[ns]':
					new_col = c+"_c"
					slice.is_copy = False
					slice[new_col] slice[c].astype(object, copy= True).where(slice[c].notnull(), None)
					col_insert.append(new_col)
				else:
					col_insert.append(c)

			data_to_insert = slice[col_insert].to_records(index = False, convert_datetime64=True).tolist()
			if upsert:
				self.upsert_batch(schema, table_name , [k for k in old_columns], data_to_insert, keys=upsert_keys, ignore_conflict = ignore_conflict) 
			else:
				self.upsert_batch(schema, table_name , [k for k in old_columns], data_to_insert) 

			logger.info("{} lines inserted: {}".format(end, time.time()))

			if end == df.count:
				break

		logger.info("insert dataframe end : {}".format(time.time()))
		return end
	@staticmethod
	def get(name, new = False):
		if not new:
			if name not in PostgresClient.clients:
				section = "Postgres_"+name
				from config.config import Config
				config = Config().get()
				if section not in config:
					raise ValueError(section + 'not found in config')
				host = config[section]['host']
				port = config[section]['port']
				user = config[section]['user']
				pwd = config[section]['pwd']
				db = config[section]['db']
				client = PostgresClient(host = host, port =port, user= user, password = pwd, database = db)
				PostgresClient.clients[name] = client
			return PostgresClient.clients[name]

		else:
			section = 'Postgres_'+name
			from config.config import Config
			config = Config().get()
			if section not in config:
				raise ValueError(section +' not found in config')
			host = config[section]['host']
			port = config[section]['port']
			user = config[section]['user']
			pwd = config[section]['pwd']
			db = config[section]['db']
			client = PostgresClient(host = host, port =port, user= user, password = pwd, database = db)
			return client

class PostgresPool(object):
	def __init__(self, name):
		section = 'Postgres_' +name
		from config.config import Config
		config = Config().get()
		if section not in config:
			raise ValueError(section +' not found in config')
		self.host = config[section]['host']
		self.port = config[section]['port']
		self.user = config[section]['user']
		self.pwd = config[section]['pwd']
		self.db = config[section]['db']

		async def run():
			self.pool = await asyncpg.create_pool(database= self.db, user= self.user, password = self.pwd, host = self.host, port = self.port)
		asyncio.get_event_loop().run_until_complete(run())

	def acquire(self):
		async def run():
			con = await self.pool.acquire()
			logger.debug("acquired: {}".format(con))
			return con
		con = asyncio.get_event_loop().run_until_complete(run())
		return PostgresClient(self.host, self.port, self.user, self.pwd, self.db, async_conn = con)

	def release(self, client):
		async def run():
			logger.debug("try to release: {}".format(client.async_conn))
			await self.pool.release(client.async_conn)
		asyncio.get_event_loop().run_until_complete(run())

if __name__ =='__main__':
	with PostgresClient('pxsrfpgolkon003.mlp.com', 5432, 'gol_dev', 'gol_dev', 'test') as client:
		client.create_schema('bloomberg')
		client.create_table("bloomberg", "test", [('date', 'date'), ('sym', 'text'), ('close', 'float'), ('vwap', 'float')], ['date', 'sym'])

		result = client.get_list_of_tables(schema= 'bloomberg')

		print(result)
		print((client.query_table_columns('bloomberg','test')))

		import pandas as pd
		import numpy as np

		data_list =[]
		start_date = datetime(2000,1,1).date()
		for i in range(1000):
			start_date+=timedelta(days=1)
			for i in range(1000):
				data_list.append([start_date, str(i), ' .HK', np.random.random(), np.random.random()])
		df = pd.DataFrame(columns = ("date", "sym", "close", "vwap"), data = data_list)
		client.insert_dataframe(df, 'bloomberg', 'test', if_exists='append', index=False, chunksize=10000, primary_keys= 'sym', upsert = False)

		df = client.read_dataframe('bloomberg', 'test')

		print(df)


		




