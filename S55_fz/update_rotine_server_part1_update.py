# coding: utf-8
#import toolkits
#toolkits.delete_files(list_files())
#不并行版本
"""
历史数据爬取
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
num_core = min(multiprocessing.cpu_count()*10,10)
client = uqer.Client(token='34e1248d676e3552680ef30cef925928c5147dba193bcb54ef70ddc4bd67daaa')
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

z1,z=get_symbol_adair()

def get_tradingdate_adair(tt):
    x=DataAPI.TradeCalGet(exchangeCD=u"XSHG",beginDate=u"20000101",endDate=tt,field=u"calendarDate,isOpen",pandas="1")
    t=x.calendarDate[x.isOpen==1].values
    return t

            
def get_databy_day(inputData):
    t0,tt = inputData
    sub_clock = time_use_tool()
    #t0_f2 = datetime.datetime.strptime(t0, '%Y%m%d').strftime('%Y-%m-%d')
    #tt = t0
    #t0_0 = t0_f2
    def compress_all_zip_data(fn='ad_test.zip'):
        fns = get_file_list()
        z=zipfile.ZipFile(fn,'w',zipfile.ZIP_DEFLATED)
        for fn1_d1 in fns:
            z.write(fn1_d1)
        z.close()
        #toolkits.delete_files(fns)
    
    def get_ticker_data():
        #x.loc[x.tradeDate>='2019-12-01']
        #2 股票日行情
        #股票日行情 半年
        fn_d2 = 'tickerday_data%s' % tt
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2= fn1_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            x=DataAPI.MktEqudGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0,endDate=tt,isOpen=1,field=u"",pandas="1") 
            x.drop(['secID','secShortName','exchangeCD','vwap','isOpen'],axis=1, inplace=True)

            save_data_adair(fn_d2,x,'MktEqudGet')
            print('正股日数据已经更新到%s' % fn2_d2) 
        else:
            print('%s已经存在，正股日数据已经更新，未执行' % fn2_d2)  

    #ST标记
    def update_st_data():   
        fn_d2 = 'st_data%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.SecSTGet(beginDate=t0,endDate=tt,secID=u"",ticker=z1,field=['ticker','tradeDate','STflg'],pandas="1")
            save_data_adair(fn_d2,x,'SecSTGet')
            print('st交易日数据已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)    

    #后复权月度行情
    def get_month_data():    
        fn_d2 = 'MktEqumAdjAfGet%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.MktEqumAdjAfGet(secID=u"",ticker=z1,monthEndDate=u"",beginDate=t0,
                                      endDate=tt,isOpen=u"",field=u"",pandas="1")
            save_data_adair(fn_d2,x,'MktEqumAdjAfGet')
            print('后复权月度行情已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)   

    def MktEqudAdjAfGet():
        fn_d2 = 'MktEqudAdjAfGet_data%s' % tt
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2= fn1_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            t= get_tradingdate_adair(tt)
            #t0_f1 = t0
            #tt_f1 = tt
            t0_f1 = '%s-%s-%s' % (t0[0:4],t0[4:6],t0[6:])
            tt_f1 = '%s-%s-%s' % (tt[0:4],tt[4:6],tt[6:])
            t=t[t>=t0_f1]
            t=t[t<=tt_f1]
            sub_x=DataAPI.MktEqudAdjAfGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0_f1,endDate=tt_f1,
                                          isOpen=1,field=u"",pandas="1") 
            
            save_data_adair(fn_d2,sub_x,'MktEqudAdjAfGet')
            print('后复权因子数据已经更新到%s' % fn2_d2) 
        else:
            #return None
            print('%s已经存在，后复权因子数据已经更新，未执行' % fn2_d2) 

    #DataAPI.IdxCloseWeightGet(secID=u"",ticker=u"000300",beginDate=u"20151101",endDate=u"20151130",field=u"",pandas="1")  指数成分股数据
    #指数月度行情
    def MktIdxmGet_adair():
        fn_d2 = 'MktIdxmGet%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x=DataAPI.MktIdxmGet(beginDate=t0,endDate=tt,indexID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktIdxmGet')
    
    #S13
    #基金日行情
    def MktFunddget_adair():   
        info='基金日行情'
        fn_d2 = 'MktFunddget_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x=DataAPI.MktFunddGet(secID=u"",ticker=u"",tradeDate=u"",beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFunddget_adair')
        print('%s已经更新到%s' % (info,fn_d2))  
    #x=DataAPI.MktMFutdGet(mainCon=u"",contractMark=u"",contractObject=u"",tradeDate=u"20191231",startDate=u"",endDate=u"",field=u"",pandas="1")
    #期货主力、连续合约日行情 
    def MktMFutdGet_adair():
        info='期货主力、连续合约日行情'
        fn_d2 = 'MktMFutdGet_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x=DataAPI.MktMFutdGet(mainCon=u"",contractMark=u"",contractObject=u"",tradeDate=u"",startDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktMFutdGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))  
    #期货期货会员成交量排名 x = DataAPI.MktFutMTRGet(beginDate=sub_tref[0],endDate=sub_tref[-1],secID=u"",ticker=u"",field=u"",pandas="1")
    def MktFutMTRGet_adair():
        info='期货期货会员成交量排名'
        fn_d2 = 'MktFutMTRGet_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x= DataAPI.MktFutMTRGet(beginDate=t0,endDate=tt,secID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutMTRGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))  

    #期货期货会员空头持仓排名 x = DataAPI.MktFutMSRGet(beginDate=sub_tref[0],endDate=sub_tref[-1],secID=u"",ticker=u"",field=u"",pandas="1")
    def MktFutMSRGet_adair():
        info='期货期货会员空头持仓排名'
        fn_d2 = 'MktFutMSRGet_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x= DataAPI.MktFutMSRGet(beginDate=t0,endDate=tt,secID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutMSRGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))  

    #期货期货会员多头持仓排名 x = DataAPI.MktFutMLRGet(beginDate=sub_tref[0],endDate=sub_tref[-1],secID=u"",ticker=u"",field=u"",pandas="1")
    def MktFutMLRGet_adair():
        info='期货期货会员空头持仓排名'
        fn_d2 = 'MktFutMLRGet_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x= DataAPI.MktFutMLRGet(beginDate=t0,endDate=tt,secID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutMLRGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))
    
    #期货仓单日报
    def MktFutWRdGet_adair():
        info='期货仓单日报'
        fn_d2 = 'MktFutWRdGet_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x= DataAPI.MktFutWRdGet(beginDate=t0,endDate=tt,contractObject=u"",exchangeCD=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutWRdGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))    
    #可转债市场表现
    def MktConsBondPerfGet_adair():    
        fn_d1= 'MktConsBondPerfGet_adair%s' % tt
        fn2_d1 = '%s.csv' % fn_d1
        if fn2_d1 not in list_files():
            z1,z=get_symbol_adair()
            x=DataAPI.MktConsBondPerfGet(beginDate=t0,endDate=tt,secID=u"",tickerBond=u"",tickerEqu=z1,field=u"",pandas="1")
            x.drop(["reviseItem","triggerItem","triggerCondItem"],axis=1,inplace=True)
            save_data_adair(fn_d1,x,'MktConsBondPerfGet_adair')
            print('可转债日数据已经更新到%s' % fn2_d1)    
        else:
            print('%s已经存在，可转债日数据已经更新，未执行' % fn2_d1) 
    #
    #指数估值
    def MktIdxdEvalGet_adair():
        info='指数估值'
        fn_d2 = 'MktIdxdEvalGet_adair%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x= DataAPI.MktIdxdEvalGet(secID=u"",ticker=u"000922",beginDate=t0,endDate=tt,PEType=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktIdxdEvalGet_adair')
        print('%s已经更新到%s' % (info,fn_d2)) 

    #S31
    #ETF基金申赎清单成分券信息
    def FundETFConsGet_adair():
        fn='FundETFConsGet_adair %s' % tt
        fn_d2=fn
        if '%s.csv' % fn_d2 in list_files():
            return
        x=DataAPI.FundETFConsGet(secID=u"",ticker=['510050','510300','510500'],beginDate=t0,endDate=tt,field=u"",pandas="1")
        
        save_data_adair(fn,x,'FundETFConsGet_adair')

    #后复权周度行情
    def get_ticker_week_data():    
        fn_d2 = 'MktEquwAdjAfGet%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.MktEquwAdjAfGet(secID=u"",ticker=z1,weekEndDate=u"",beginDate=t0,
                                      endDate=tt,isOpen=u"",field=u"",pandas="1")
            save_data_adair(fn_d2,x,'get_ticker_week_data')
            print('后复权周度行情已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)     

    #指数周度行情
    def get_index_week_data():    
        fn_d2 = 'MktIdxwGet_adair%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.MktIdxwGet(beginDate=t0,endDate=tt,indexID=u"",ticker=u"",field=u"",pandas="1")
            save_data_adair(fn_d2,x,'get_index_week_data')
            print('后复权周度行情已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)  

    #S46 贴吧数据 
    def get_SocialDataGubaGet():
        fn_d2 = 'SocialDataGubaGet_data%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x=DataAPI.SocialDataGubaGet(ticker=u"",beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'get_SocialDataGubaGet')
        print('贴吧数据已更新%s' % fn_d2)

    #CME期货日行情
    def get_MktCmeFutdGet():
        fn_d2 = 'MktCmeFutdGet_S50%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        field = """ticker,tradeDate,deliYear,deliMonth,contractObject,preSettlePrice,preOpenInt,openPrice,highestPrice,highestPriceSide,lowestPrice,lowestPriceSide,closePrice,closePriceSide,settlePrice,chg,turnoverVol"""
        x=DataAPI.MktCmeFutdGet(ticker=u"",tradeDate=u"",beginDate=t0,endDate=tt,contractObject=u"",field=field,pandas="1")
        #x=DataAPI.FundHoldingsGet(secID=secID,ticker=u"",reportDate=u"",beginDate=t0,endDate=tt,secType="",holdingTicker="",holdingSecID="",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'get_MktCmeFutdGet')
        print('CME期货日行情%s' % fn_d2)
        
    # S53 上市公司特殊状态
    def EquInstSstateGet_adair():
        fn_d2='EquInstSstateGet%s' % tt
        if '%s.csv' % fn_d2 in list_files():
            return
        x=DataAPI.EquInstSstateGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'EquInstSstateGet_adair')
    #S53 每日行情填充数据
    def get_MktEqudGet0S53():
        #x.loc[x.tradeDate>='2019-12-01']
        #2 股票日行情
        #股票日行情 半年
        key_str = '正股 filling 日数据'
        fn_d2 = 'MktEqudGet0S53_%s' % tt
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2= fn1_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            x=DataAPI.MktEqudGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0,endDate=tt,isOpen=0,field=u"",pandas="1") 
            x.drop(['secID','secShortName','exchangeCD','vwap','isOpen'],axis=1, inplace=True)

            save_data_adair(fn_d2,x,'get_MktEqudGet0S53')
            print('%s已经更新到%s' % (key_str,fn2_d2)) 
        else:
            print('%s已经存在，%s已经更新，未执行' % (fn2_d2,key_str)) 

    #获取后复权填充数据
    def MktEqudAdjAfGetF0S53():    
        key_str0 = 'MktEqudAdjAfGetF0S53'
        key_str1 ='后复权因子填充数据'
        fn_d2 = '%s_%s' % (key_str0,tt)
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2= fn1_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            #t= get_tradingdate_adair(tt)
            x=DataAPI.MktEqudAdjAfGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0,endDate=tt,
                                          isOpen=0,field=u"",pandas="1") 
            save_data_adair(fn_d2,x,'MktEqudAdjAfGetF0S53')
            #return x
            print('%s已经更新到%s' % (key_str1,fn2_d2)) 
        else:
            #return None
            print('%s已经存在，%s已经更新，未执行' % (fn2_d2,key_str1)) 
    #1-3
    get_ticker_data()
    #4
    update_st_data()
    #5
    get_month_data()
    #6
    #get_symbol_basic_info()    
    #8获取后复权因子
    MktEqudAdjAfGet()    
    #10
    MktIdxmGet_adair()   
    #15 获取数据立方替代因子
    #get_S19_factors_datacub()
    #16 基金日行情 ETF
    MktFunddget_adair()
    #17 期货主力、连续合约日行情 
    MktMFutdGet_adair()
    #18 期货会员成交量排名
    MktFutMTRGet_adair()
    #19 期货期货会员空头持仓排名
    MktFutMSRGet_adair()
    #20 期货期货会员多头持仓排名
    MktFutMLRGet_adair()
    #22期货仓单日报
    MktFutWRdGet_adair()
    #23可转债市场表现
    MktConsBondPerfGet_adair()
    #24指数估值
    MktIdxdEvalGet_adair()
    #25ETF基金申赎清单成分券信息
    FundETFConsGet_adair()
    #27指数周行情
    get_ticker_week_data()
    #28 指数周度行情
    get_index_week_data()
    #30
    #get_TradeCalGet()
    #31 贴吧数据
    get_SocialDataGubaGet()
    #33 基金基本信息
    #36 CME期货日行情
    get_MktCmeFutdGet()
    #38 每日行情填充数据
    get_MktEqudGet0S53()
    #39 后复权填充数据
    MktEqudAdjAfGetF0S53()
    sub_clock.use('complete %s' % t0)
#一次计算10给交易日（2个星期的数据）

#get_databy_day(['20200910','20200917'])
t_f = '2020-09-13'
tref = get_tradingdate_adair(t_f)
#tref = tref[:3]
tref = [i.replace('-','') for i in tref]
T = len(tref)
r=10
t0_1=[]
tt_1=[]
i=0
while i <T-1:
    j=i+r-1
    if j>T-1:
        j=T-1
    t0_1.append(tref[i])
    tt_1.append(tref[j])
    i=i+r

for i in zip(t0_1,tt_1):
    get_databy_day(i)