# -*- coding: utf-8 -*-
"""
Created on Sat Sep 26 18:39:02 2020
S56历史数据临时程序
20201007 升级港股数据
@author: adair2019
"""
import uqer
from uqer import DataAPI
client = uqer.Client(token='8b1df403d1bfb39b588d35a43e8526f454d779351d0b439b9ad7b299cd61d9df')
import os
from yq_toolsS45 import get_file_name
from yq_toolsS45 import time_use_tool 
import datetime
import numpy as np
obj_t= time_use_tool()
import pandas as pd
from multiprocessing.dummy import Pool as ThreadPool
import multiprocessing


#from yq_toolsSFZ import engine
server_sel = True
if server_sel:
    from yq_toolsSFZ import engine
    from yq_toolsSFZ import pn as datadir
else:
    from yq_toolsS45 import engine
    from yq_toolsS45 import pn as datadir

num_core = min(multiprocessing.cpu_count()*10,20)

#datadir='dataset_uqer'
if not os.path.exists(datadir):
    os.makedirs(datadir)


_,fn_exist=get_file_name(datadir,'.csv')

def get_ini_data(tn,var_name,db=engine):
    sql_str = 'select %s from %s order by %s desc limit 1' % (var_name,tn,var_name)
    t0 = pd.read_sql(sql_str,db)
    return t0[var_name].astype(str).values[0]
def list_files():
    return fn_exist

def save_data_adair(fn_d1,x,fn_d2=None):
    if fn_d2 is None:
        fn_d2 = fn_d1
    fn1_d1 =os.path.join(datadir, '%s.csv' % fn_d1)
    #fn2_d1 = '%s.zip' % fn_d2
    x.to_csv(fn1_d1,index=False)

#DataAPI.MktUsequdGet(ticker=u"",tradeDate=u"20180720",beginDate=u"",endDate=u"",exchangeCD=u"XNAS",field=u"",pandas="1")
def get_all_date(t0_num=2000):
    t0 = '%d-01-01' % t0_num
    tt = '%d-12-31' % t0_num
    temp = pd.date_range(t0,tt).astype(str).tolist()
    temp = [i.replace('-','') for i in temp]
    return temp

for num in range(2000,2021):
    tref = get_all_date(num)
    x=[]
    fn_d1='MktUsequdGetS54_%d' % num
    if '%s.csv' % fn_d1 in list_files():
        continue
    for i,sub_t in enumerate(tref):
        if sub_t>'20201008':
            break
        sub_x=DataAPI.MktUsequdGet(ticker=u"",tradeDate=sub_t,beginDate=u"",endDate=u"",exchangeCD=u"",field=u"",pandas="1")
        x.append(sub_x)
        if i/20==np.floor(i/20):
            print(i,sub_t)
    X=pd.concat(x)
    save_data_adair(fn_d1,X)