
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
def get_year_data(inputdata):
    t0,tt=inputdata
    #年
    def IdxCloseWeightGet_adair(t0,tt): 
        if tt<'20050101':
            return
        fn_d2 = 'IdxCloseWeightGet%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        tickercode = ['000001','000002','000003','000004','000005','000006','000007','000008','000009','000010','000011','000012','000013','000015',
                      '000016','000020','000090','000132','000133','000300','000852','000902','000903','000904','000905','000906','000907','000922',
                      '399001','399002','399004','399005','399006','399007','399008','399009','399010','399011','399012','399013','399015','399107',
                      '399108','399301','399302','399306','399307','399324','399330','399333','399400','399401','399649','000985']
        x=[]
        for i,sub_ticker in enumerate(tickercode):
            sub_x=DataAPI.IdxCloseWeightGet(secID=u"",ticker=sub_ticker,beginDate=t0,endDate=tt,field=u"effDate,ticker,consTickerSymbol,weight",pandas="1")
            x.append(sub_x)
            print('%d-%s' % (i,sub_ticker))
        x=pd.concat(x)
        save_data_adair(fn_d2,x,'IdxCloseWeightGet')
        print('%s已经更新' % fn_d2) 
    
    #按照年更新没有问题
    #2000-01-01
    def MktIborGet_adair(t0,tt):
        t0_0=t0
        sub_t0=t0_0
        sub_tt=tt
        fn_d1= 'MktIborGet_adair_%s' % sub_tt
        fn2_d2 = '%s.csv' % fn_d1
        if fn2_d2 in list_files():
            return
        info = '银行间同业拆借利率'
        
        ticker=['Hibor10M', 'Hibor11M', 'Hibor1D', 'Hibor1M', 'Hibor1W', 'Hibor1Y', 
                'Hibor2M', 'Hibor2W', 'Hibor3M', 'Hibor4M', 'Hibor5M', 'Hibor6M', 'Hibor7M', 'Hibor8M', 'Hibor9M',
             'Libor10M', 'Libor11M', 'Libor1D', 'Libor1M', 'Libor1W', 'Libor1Y', 
             'Libor2M', 'Libor2W', 'Libor3M', 'Libor4M', 'Libor5M', 'Libor6M', 'Libor7M', 'Libor8M', 'Libor9M', 'Shibor1D',
             'Shibor1D10D', 'Shibor1D20D', 'Shibor1D5D', 'Shibor1M', 'Shibor1M10D',
             'Shibor1M20D', 'Shibor1M5D', 'Shibor1W', 'Shibor1W10D', 'Shibor1W20D', 'Shibor1W5D', 'Shibor1Y', 'Shibor1Y10D',
             'Shibor1Y20D', 'Shibor1Y5D', 'Shibor2W', 'Shibor2W10D', 'Shibor2W20D', 
             'Shibor2W5D', 'Shibor3M', 'Shibor3M10D', 'Shibor3M20D', 'Shibor3M5D', 'Shibor6M', 'Shibor6M10D', 'Shibor6M20D',
             'Shibor6M5D', 'Shibor9M', 'Shibor9M10D', 'Shibor9M20D', 'Shibor9M5D', 
             'Tibor10M', 'Tibor11M', 'Tibor12M', 'Tibor1M', 'Tibor1W', 'Tibor2M', 'Tibor3M', 'Tibor4M', 'Tibor5M', 'Tibor6M',
             'Tibor7M', 'Tibor8M', 'Tibor9M']
        x=DataAPI.MktIborGet(secID=u"",ticker=ticker,tradeDate=u"",beginDate=sub_t0,endDate=sub_tt,currency=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x,'MktIborGet_adair')
        print('%s已经更新到%s' % (info,fn_d1))    
    
    IdxCloseWeightGet_adair(t0,tt)
    MktIborGet_adair(t0,tt)
       

def get_halfyear_data(inputdata):
    t0,tt=inputdata
    #按照年频率更新    
    def MktMFutdGet_adair(t0,tt):
        if tt<'20010102':
            return
        info='期货主力、连续合约日行情'
        fn_d2 = 'MktMFutdGet_adair%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        x=DataAPI.MktMFutdGet(mainCon=u"",contractMark=u"",contractObject=u"",
                              tradeDate=u"",startDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktMFutdGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))    
    #半年
    def FundETFConsGet_adair(t0,tt):
        if tt<'20160104':
            return
        fn_d2 = 'FundETFConsGet_adair %s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        x = []
        for sub_code in ['510050','510300','510500']:
            sub_x=DataAPI.FundETFConsGet(secID=u"",ticker=sub_code,beginDate=t0,endDate=tt,field=u"",pandas="1")
            x.append(sub_x)
        x=pd.concat(x)
        save_data_adair(fn_d2,x,'FundETFConsGet_adair')
        print('已经更新到%s' % (fn_d2)) 
        
    MktMFutdGet_adair(t0,tt)
    FundETFConsGet_adair(t0,tt)
    
        

year_f = 2021
year_0 = 2000 #must be repair before update
    
t0_1 = ['%d0101' % i for i in range(year_0,year_f)]
tt_1 = ['%d1231' % i for i in range(year_0,year_f)]
pool = ThreadPool(processes=num_core)
temp = pool.map(get_year_data, zip(t0_1,tt_1))
pool.close()
pool.join() 

t0_1 = ['%d0101' %i for i in range(year_0,year_f)] + ['%d0701' %i for i in range(year_0,year_f)]
t0_1.sort()
tt_1 = ['%d0630' % i for i in range(year_0,year_f)]+['%d1231' % i for i in range(year_0,year_f)]
tt_1.sort()
pool = ThreadPool(processes=num_core)
temp = pool.map(get_halfyear_data, zip(t0_1,tt_1))
pool.close()
pool.join() 
   
