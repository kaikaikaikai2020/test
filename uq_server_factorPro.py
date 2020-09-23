# coding: utf-8
#import toolkits
#toolkits.delete_files(list_files())
#并行版本
#多线程版本
"""
历史数据爬取
爬取普通权限因子数据

"""
from yq_toolsS45 import time_use_tool
from yq_toolsS45 import get_file_name
import uqer
from uqer import DataAPI
from multiprocessing.dummy import Pool as ThreadPool
import multiprocessing
import os
import zipfile
import pandas as pd
import time
import datetime
import numpy as np 
num_core = min(multiprocessing.cpu_count()*10,20)
client = uqer.Client(token='8b1df403d1bfb39b588d35a43e8526f454d779351d0b439b9ad7b299cd61d9df')
datadir='dataset_uqer'
if not os.path.exists(datadir):
    os.makedirs(datadir)

_,fn_exist=get_file_name(datadir,'.csv')
#清空 zip 保留csv
#import toolkits
import os

def list_files():
    return fn_exist
def get_file_list(atr='zip'):
    temp = list_files()
    temp1 = []
    for i in temp:
        ad = i.split('.')
        if len(ad)==2:
            if ad[1] == atr:
                temp1.append(i)
    return temp1
#获取symbol的list
def save_data_adair(fn_d1,x,fn_d2=None):
    if fn_d2 is None:
        fn_d2 = fn_d1
    fn1_d1 =os.path.join(datadir, '%s.csv' % fn_d1)
    x.to_csv(fn1_d1,index=False)
    
def get_symbol_adair():
    x=DataAPI.EquGet(secID=u"",ticker=u"",equTypeCD=u"A",listStatusCD=u"",field=u"",pandas="1")
    y=x['ticker']
    z=''
    z1=[]
    k=0;
    for i in y:
        if len(i)==6:
            if i[0]=='3' or i[0]=='0' or i[0:2]=='60':
                z1.append(i)
                if k==0:
                    z=i
                else:
                    z=z+','+i
                k = k +1
    return z1,z

def get_tradingdate_adair(tt):
    x=DataAPI.TradeCalGet(exchangeCD=u"XSHG",beginDate=u"20000101",endDate=tt,field=u"calendarDate,isOpen",pandas="1")
    t=x.calendarDate[x.isOpen==1].values
    return t

            
def get_databy_day(inputData):
    t0,z1 = inputData
    sub_clock = time_use_tool()
    def get_MktStockFactorsOneDayProGet_full(t0,z1):
        sub_tt=t0
        #sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        #sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'MktStockFactorsOneDayProGet%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = fn1_d1
        info = 'MktStockFactorsOneDayProGet_full'
        key_str = u""
        if fn2_d1 not in list_files():
            sub_t=sub_tt
            sub_t = sub_t.replace('-','')
            x=DataAPI.MktStockFactorsOneDayProGet(tradeDate=sub_t,secID=u"",ticker=z1,field=key_str,pandas="1")
            save_data_adair(fn_d1,x,'MktStockFactorsOneDayProGet')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，未执行' % (fn2_d1)) 
            return None
    
    
    get_MktStockFactorsOneDayProGet_full(t0,z1)
    sub_clock.use('complete %s' % t0)
#一次计算10给交易日（2个星期的数据）
    
def try_getdaydata(inputData):
    try:
        get_databy_day(inputData)
    except:
        print('error')
        
if __name__ == '__main__':
    #get_databy_day(['20200910','20200917'])
    t_f = '2020-09-21'
    tref = get_tradingdate_adair(t_f)
    z1,z=get_symbol_adair()
    tref = [i for i in tref if i >='2007-01-04']
    #tref = tref[-4:]
    tref = [i.replace('-','') for i in tref]
    T = len(tref)
    input_data1=[]
    for sub_t in tref:
        input_data1.append((sub_t,z1))
    
    
    pool = ThreadPool(processes=num_core)
    temp = pool.map(get_databy_day, input_data1)
    pool.close()
    pool.join()     
