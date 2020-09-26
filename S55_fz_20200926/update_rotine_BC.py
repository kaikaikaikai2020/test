
# coding: utf-8
"""
按照会计期间分段下载
"""

import uqer
from uqer import DataAPI
client = uqer.Client(token='8b1df403d1bfb39b588d35a43e8526f454d779351d0b439b9ad7b299cd61d9df')
import os
from yq_toolsS45 import get_file_name

#1获取所有可转债日度数据
#获取symbol的list
#import zipfile
import pandas as pd
#import time
#import datetime
#import numpy as np 
from multiprocessing.dummy import Pool as ThreadPool
import multiprocessing
num_core = min(multiprocessing.cpu_count()*10,20)

datadir='dataset_uqer'
if not os.path.exists(datadir):
    os.makedirs(datadir)


_,fn_exist=get_file_name(datadir,'.csv')

def list_files():
    return fn_exist

def save_data_adair(fn_d1,x,fn_d2=None):
    if fn_d2 is None:
        fn_d2 = fn_d1
    fn1_d1 =os.path.join(datadir, '%s.csv' % fn_d1)
    #fn2_d1 = '%s.zip' % fn_d2
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

z1,z=get_symbol_adair()

def get_tradingdate_adair(tt):
    x=DataAPI.TradeCalGet(exchangeCD=u"XSHG",beginDate=u"20000101",endDate=tt,field=u"calendarDate,isOpen",pandas="1")
    t=x.calendarDate[x.isOpen==1].values
    return t

#########################################################################################################################
#1 合并利润表 (Point in time)  合并利润表(所有会计期末最新披露)
#归属母公司的净利润 NIncomeAttrP 
#营业收入 revenue 
def get_20_day(inputdata):
    t0,tt,secCode=inputdata
    #  新闻热度指数（新版，不包括当天） 最好20-40天间隔
    def NewsHeatIndexNewGet_adair(t0,tt):
        if tt <='2015-04-03':
            return        
        info = '新闻热度指数（新版，不包括当天）'
        fn_d1 = 'NewsHeatIndexNewGetS55FZ_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        x=DataAPI.NewsHeatIndexNewGet(beginDate=t0,endDate=tt,secID="",exchangeCD=u"",ticker=u"",secShortName=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1))  
    #新闻情感指数（新版，按天统计） 最好20-40天间隔
    def NewsSentiIndexGet_adair(t0,tt):
        if tt <='2015-04-03':
            return
        info = '新闻情感指数（新版，按天统计）'
        fn_d1 = 'NewsSentiIndexGetS55FZ_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        
        x=DataAPI.NewsSentiIndexGet(beginDate=t0,endDate=tt,secID="",exchangeCD=u"",ticker=u"",secShortName=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1)) 
    # 一致预期数据表(申万行业) 20-40
    def ResConInduSwGet_adair(t0,tt):
        if tt < '2014-01-02':
            return
        info = '一致预期数据表(申万行业)'
        fn_d1 = 'ResConInduSwGet18_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        x= DataAPI.ResConInduSwGet(beginDate=t0,endDate=tt,secCode=u"",secName="",field="",pandas="1") 
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1)) 
    #10-35
    #个股一致预期衍生数据表
    def ResConSecDerivativeGet_adair(t0,tt):
        if tt<'2010-01-04':
            return
        
        info = '个股一致预期衍生数据表'
        fn_d1 = 'ResConSecDerivativeGet18_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        x=DataAPI.ResConSecDerivativeGet(secCode=secCode,secName=u"",endDate=u"20200920",beginDate=u"20200910",field=u"",pandas="1")
        
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1))  
        
    #max(41) 20比较合适
    #获取一致预期目标价与评级表
    def ResConTarpriScoreGet_adair(t0,tt):
        if tt<'20050104':
            return
        info='获取一致预期目标价与评级表'
        fn_d1='ResConTarpriScoreGet18_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        
        x=DataAPI.ResConTarpriScoreGet(secCode=u"",endDate=tt,beginDate=t0,field="",pandas="1")   
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1)) 
        
    NewsHeatIndexNewGet_adair(t0,tt)
    NewsSentiIndexGet_adair(t0,tt)
    ResConInduSwGet_adair(t0,tt)
    ResConSecDerivativeGet_adair(t0,tt)
    ResConTarpriScoreGet_adair(t0,tt)
        
def get_5_day(inputdata):
    t0,tt,secCode=inputdata
    #获取一致预期个股数据表
    #ResConSecDataGet18 0-5天 
    def ResConSecDataGet_adair(t0,tt):
        if tt < '2005-01-04':
            return
        info = '一致预期个股数据表'
        fn_d1 = 'ResConSecDataGet18_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        x= DataAPI.ResConSecDataGet(secCode=u"",endDate=tt,beginDate=t0,field="",pandas="1") 
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1)) 
    #0-5
    #获取一致预期个股营业收入表
    def ResConSecIncomeGet_adair(t0,tt):
        if tt<'20050104':
            return
        info='获取一致预期个股营业收入表'
        fn_d1='ResConSecIncomeGetS18_%s' % tt
        fn2_d2=  '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        x=DataAPI.ResConSecIncomeGet(secCode=u"",endDate=tt,beginDate=t0,field="",pandas="1")        
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1))  
        
    ResConSecDataGet_adair(t0,tt)
    ResConSecIncomeGet_adair(t0,tt)

def tref_split(tref,r=20):
    t0_1=[]
    tt_1=[]
    i=0    
    T = len(tref)
    while i <T-1:
        j=i+r-1
        if j>T-1:
            j=T-1
        t0_1.append(tref[i])
        tt_1.append(tref[j])
        i=i+r       
    return t0_1,tt_1
#按照年
secCode=pd.read_csv('resconsecderivativeget18_secCode.py',dtype={'secCode':str})
secCode = secCode.secCode.tolist()
#tref = pd.date_range('20000101','20200926').astype(str).tolist()
#tref0 = [i.replace('-','') for i in tref]
tref = pd.read_csv('BC_date.py').tref.tolist()
tref = [i.replace('-','') for i in tref]
#tref=tref[-5:]
t0_1,tt_1=tref_split(tref,20)
p=[secCode]*len(t0_1)

pool = ThreadPool(processes=num_core)
temp = pool.map(get_20_day,zip(t0_1,tt_1,p))
pool.close()
pool.join()     


t0_1,tt_1=tref_split(tref,5)
p=[secCode]*len(t0_1)
pool = ThreadPool(processes=num_core)
temp = pool.map(get_5_day,zip(t0_1,tt_1,p))
pool.close()
pool.join()   

