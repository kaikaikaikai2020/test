import os

path = os.path.abspath(__file__)
dir_path = s.path.dirname(path)
config_path = os.path.join(dir_path, 'config.ini')
from config.config import Config

Config().read(config_path)