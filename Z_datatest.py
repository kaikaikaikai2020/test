# -*- coding: utf-8 -*-
"""
Created on Sun Sep 27 01:32:09 2020

@author: adair2019
"""
import pandas as pd

from yq_toolsSFZ import engine


tn = 'yq_mktstockfactorsonedayproget'

x=pd.read_sql('select * from %s limit 1' % tn,engine)
print(x.shape)


x=pd.read_sql('select count(*) from %s limit 1' % tn,engine)
print(x)