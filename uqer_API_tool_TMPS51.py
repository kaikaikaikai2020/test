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

fund_secID = DataAPI.FundGet(secID=u"",ticker=u"",etfLof=u"",listStatusCd=u"",
                        category=['E','H','B','SB','M','O'],idxID=u"",idxTicker=u"",
                        operationMode=u"",beginDate=u"",endDate=u"",status="",field='secID',pandas="1")
fund_secID=fund_secID.secID.unique().tolist()


z1,z=get_symbol_adair()

def get_tradingdate_adair(tt):
    x=DataAPI.TradeCalGet(exchangeCD=u"XSHG",beginDate=u"20000101",endDate=tt,field=u"calendarDate,isOpen",pandas="1")
    t=x.calendarDate[x.isOpen==1].values
    return t


tickerHK0=DataAPI.HKEquGet(secID=u"",ticker=u"",listStatusCD=u"",ListSectorCD=[1,2],equTypeCD=u"",connect=u"",field=u"",pandas="1")
tickerHK=tickerHK0.ticker.tolist()
trefHK0=DataAPI.TradeCalGet(exchangeCD=u"XHKG",beginDate=u"19900101",endDate=u"20300101",isOpen=u"",field=u"",pandas="1")
trefHK = trefHK0[trefHK0.isOpen==1].calendarDate.tolist()



def get_FundAssetsGet(t0):
    sub_tt = t0
    fn_d1= 'yq_FundAssetsGet_S51_%s' % sub_tt
    fn1_d1 = '%s.csv' % fn_d1
    fn2_d1 = fn1_d1
    info = '基金资产配置'
    if fn2_d1 not in list_files():
        x=DataAPI.FundAssetsGet(secID=u"",ticker=u"",reportDate=u"",updateTime=sub_tt,
                                beginDate=u"",endDate=u"",field=u"",pandas="1") 
        save_data_adair(fn_d1,x,'get_FundAssetsGet')
        print('%s已经更新到%s' % (info,fn2_d1))  
        return x
    else:
        print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
        return None
        
        
def get_all_date(tt):
    return pd.date_range('2000-01-01',tt).astype(str).tolist()

#执行依次，至少使用api60次
if __name__ == '__main__':
    #获取初始时间处理       
    tt = datetime.datetime.strftime( datetime.datetime.today(),'%Y%m%d')
    t0='2020-07-01'
    
    tref0 = get_all_date(tt)
    tref0=[i.replace('-','') for i in tref0 if i>=t0]
    
    _,fn_exist=get_file_name(datadir,'.csv')
    pool = ThreadPool(processes=num_core)
    pool.map(get_FundAssetsGet, tref0)
    pool.close()
    pool.join()
    
    obj_t.use()