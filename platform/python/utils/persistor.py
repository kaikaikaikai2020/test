import cloudpickle
import os
import logging
import xarray as xr
import pandas as pd

CloudPickle_EXT = 'copkl'
HDF5_EXT = 'hdf'
Dill_EXT = 'dill'
Pickle_EXT = 'pikl'
NetCDF_EXT = 'nc'

def add_ext(path, ext):
	name, cur_ext = os.path.splitext(path)
	if len(cur_ext) == 0:
		return path +'.'+ext
	else:
		return path

class Persistor(object):
	@staticmethod
	def save(obj, path):
		name, ext = os.path.splitext(path)
		if len(ext) == 0:
			if isinstance(obj, xr.Dataset):
				PersistorNetCDF.save(obj, path)
			if isinstance(obj, pd.DataFrame) or isinstance(obj, pd.Series):
				PersistorHDF.save(obj, path)
			else:
				PersistorCloudPickle(obj, path)

		else:
			if ext == CloudPickle_EXT:
				PersistorNetCDF.save(obj, path)
			elif ext == HDF5_EXT:
				PersistorHDF.save(obj, path)
			else:
				PersistorCloudPickle.save(obj, path)

	@staticmethod
	def load(path):
		name, ext = os.path.splitext(path)
		if len(ext) == 0:
			if os.path.exists(path +'.'+NetCDF_EXT):
				return PersistorNetCDF.load(path)
			elif os.path.exists(path +'.'+CloudPickle_EXT):
				return PersistorCloudPickle.load(path)
			elif os.path.exists(path +'.'+ HDFS_EXT):
				return PersistorHDF.load(path)
			else:
				ValueError("unknown file type: {}".format(path))

		else:
			if ext == CloudPickle_EXT:
				return PersistorCloudPickle.load(path)
			elif ext == NetCDF_EXT:
				return PersistorNetCDF.load(path)
			elif ext== HDFS_EXT:
				return PersistorHDF.load(path)
			else:
				return PersistorCloudPickle.load(path)

	@staticmethod
	def exist(path):
		name, ext = os.path.splitext(path)
		if len(ext) == 0:
			if os.path.exists(path +'.'+NetCDF_EXT):
				return path +'.'+NetCDF_EXT
			elif os.path.exists(path+'.'+CloudPickle_EXT):
				return path +'.'+CloudPickle_EXT
			else:
				return False
		else:
			return os.path.exists(path)

class PersistorCloudPickle(object):
	ext = CloudPickle_EXT
	@staticmethod
	def save(obj, path):
		cloudpickle.dump(obj, open(add_ext(path, PersistorCloudPickle.est), 'wbh'))

	@staticmethod
	def load(path):
		return cloudpickle.load(open(add_ext(path, PersistorCloudPickle.ext), 'rh'))

class PersistornetCDF(object):
	ext = CloudPickle_EXT
	@staticmethod
	def save(obj, path):
		obj.to_netcdf(add_ext(path, PersistorNetCDF.ext))

	@staticmethod
	def load(path):
		return xr.open_dataset(add_ext(path, PersistorNetCDF.ext))

class PersistorHDF(object):
	ext= HDFS_EXT
	@staticmethod
	def save(obj, path):
		if not (isinstance(obj, pd.DataFrame) or isinstance(obj, pd.Series)):
			raise ValueError("persistor hdf only support dataframe and series")
		obj.to_hdf(add_ext(path, self.ext))

	@staticmethod
	def load(path):
		return pd.read_hdf(add_ext(path, self.ext))




