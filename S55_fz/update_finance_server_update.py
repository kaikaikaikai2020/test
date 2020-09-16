
# coding: utf-8
"""
按照会计期间分段下载
"""

import uqer
from uqer import DataAPI
client = uqer.Client(token='34e1248d676e3552680ef30cef925928c5147dba193bcb54ef70ddc4bd67daaa')
import os
#1获取所有可转债日度数据
#获取symbol的list
#import zipfile
import pandas as pd
#import time
#import datetime
#import numpy as np 
from multiprocessing.dummy import Pool as ThreadPool
import multiprocessing
num_core = min(multiprocessing.cpu_count()*10,99)

datadir='dataset_uqer'
if not os.path.exists(datadir):
    os.makedirs(datadir)

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
def get_finance_daybyday(inputdata):
    t0,tt = inputdata
    def get_FdmtISGet():
        fn_d1= 'FdmtISGet_%s' % tt
        info = '合并利润表'                    
        x=DataAPI.FdmtISGet(ticker=z1,secID=u"",reportType=u"",endDate=tt,beginDate=t0,publishDateEnd=u"",publishDateBegin=u"",
                  endDateRep="",beginDateRep="",beginYear="",endYear="",fiscalPeriod="",field=u"",pandas="1")
        
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn_d1))  
        
    #2 资产重组
    #x=DataAPI.EquRestructuringGet(secID=u"",ticker=u"000040",beginDate=u"20141231",endDate=u"",field=u"",pandas="1")
    def get_EquRestructuringGet():
        fn_d1= 'EquRestructuringGet_%s' % tt
        fn2_d1 = fn_d1
        info = '资产重组表'
        
        f_str = [u'secID', u'ticker', u'secShortName', u'exchangeCD', u'publishDate',
           u'iniPublishDate', u'finPublishDate', u'program', u'isSucceed',
           u'restructuringType', u'underlyingType', u'underlyingVal',
           u'expenseVal', u'isRelevance', u'isMajorRes', u'payType',
           u'institNameB', u'relationShipB', u'institNameS', u'relationShipS',
           u'institNameSub', u'relationShipSub', u'institNameDeb',
           u'relationShipDeb', u'institNameCred', u'relationShipCred']
        x=DataAPI.EquRestructuringGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,field=f_str,pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
        
    #3 合并资产负债表 (Point in time) 
    #AR	float	应收账款
    #TCA	float	流动资产合计
    #TAssets	float	资产总计
    #NotesReceiv	float	应收票据
    #othReceiv	float	其他应收款
    #othCA	float	其他流动资产
    #TCL	float	流动负债合计
    #DataAPI.FdmtBSGet(ticker=u"688001",secID=u"",reportType=u"",endDate=u"",beginDate=u"",publishDateEnd=u"",
    #publishDateBegin=u"",endDateRep="",beginDateRep="",beginYear="",endYear="",fiscalPeriod="",field=u"",pandas="1")
    def get_FdmtBSGet():
        fn_d1= 'FdmtBSGet_%s' % tt
        fn2_d1 = fn_d1
        info = '合并资产负债表'
        x=DataAPI.FdmtBSGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,publishDateBegin=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    # 4主营业务构成（基础数据）
    #grossMargin	float	毛利率
    #DataAPI.FdmtMainOperNGet(partyID="",secID=u"",ticker=u"688001",beginDate=u"20181231",endDate=u"",field=u"",pandas="1")
    def get_FdmtMainOperNGet():
        fn_d1= 'FdmtMainOperNGet_%s' % tt
        fn2_d1 = fn_d1
        info = '主营业务构成'
        x=DataAPI.FdmtMainOperNGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    #业绩快报 数据太少，一直没有用
    #DataAPI.FdmtEeGet(ticker=u"600000",secID=u"",reportType=u"",endDate=u"",beginDate=u"",publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")
    def get_FdmtEeGet_S26():
        fn_d1= 'FdmtEeGet_S26_%s' % tt
        fn2_d1 = fn_d1
        info = '业绩快报'
        x=DataAPI.FdmtEeGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    #DataAPI.FdmtDerPitGet(secID="",ticker=u"688002",beginDate="",endDate="",beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")
    #5 财务衍生数据 (Point in time)
    #nrProfitLoss 非经常性损益 , 直接取公告披露值
    def get_FdmtDerPitGet():
        fn_d1= 'FdmtDerPitGet_%s' % tt
        fn2_d1 = fn_d1
        info = '财务衍生数据 (Point in time)'
        #x=DataAPI.FdmtEeGet(secID=u"",ticker=z1,beginDate=sub_t0,endDate=sub_tt,field=u"",pandas="1")
        x=DataAPI.FdmtDerPitGet(secID="",ticker=z1,beginDate=t0,endDate=tt,beginYear=u"",endYear=u"",
                                reportType=u"",publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    #6 财务指标—营运能力 (Point in time)
    #[通联数据] - DataAPI.FdmtIndiTrnovrPitGet
    def get_FdmtIndiTrnovrPitGet():
        fn_d1= 'FdmtIndiTrnovrPitGet_%s' % tt
        fn2_d1 = fn_d1
        info = '财务指标-运营能力'
        x=DataAPI.FdmtIndiTrnovrPitGet(ticker=z1,secID="",endDate=tt,beginDate=t0,
                                       beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",
                                       publishDateBegin=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))
    #S19扩展
    """
    #7 单季度财务指标 DataAPI.FdmtIndiQGet(ticker=u"688002",secID="",endDate="",beginDate="",beginYear=u"",endYear=u"",reportType=u"",field=u"",pandas="1") #数据库yq_FdmtIndiQGet
    def get_FdmtIndiQGet():
        fn_d1= 'FdmtIndiQGet_%s' % tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = '财务指标-单季度财务指标'
        if fn2_d1 not in list_files():
            x=DataAPI.FdmtIndiQGet(ticker=z1,secID="",endDate="",beginDate=t0,
                                   beginYear=u"",endYear=u"",reportType=u"",field=u"",pandas="1")
            save_data_adair(fn_d1,x)
            print('%s已经更新到%s' % (info,fn2_d1))  
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            
    """
    #7 财务指标—每股 (Point in time)
    #DataAPI.FdmtIndiPSPitGet(ticker=u"688002",secID="",endDate="",beginDate="",beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")
    def get_FdmtIndiPSPitGet():
        fn_d1= 'FdmtIndiPSPitGet_%s' % tt
        fn2_d1 = fn_d1
        info = '财务指标-每股'
        x=DataAPI.FdmtIndiPSPitGet(ticker=z1,secID="",endDate=tt,beginDate=t0,
                                       beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",
                                       publishDateBegin=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    #8 合并现金流量表 DataAPI.FdmtCFGet(ticker=u"688001",secID=u"",reportType=u"",endDate=u"",beginDate=u"",
    # publishDateEnd=u"",publishDateBegin=u"",endDateRep="",beginDateRep="",beginYear="",endYear="",fiscalPeriod="",field=u"",pandas="1")
    def get_FdmtCFGet():
        fn_d1= 'FdmtCFGet_%s' % tt
        fn2_d1 = fn_d1
        info = '合并现金流量表'
        x=DataAPI.FdmtCFGet(ticker=z1,secID="",endDate=tt,beginDate=t0,
                                       beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",
                                       publishDateBegin=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
    #9 财务指标—盈利能力 (Point in time)
    # DataAPI.FdmtIndiRtnPitGet(ticker=u"688002",secID="",endDate="",beginDate="",
    #  beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")
    def get_FdmtIndiRtnPitGet():
        fn_d1= 'FdmtIndiRtnPitGet_%s' % tt
        fn2_d1 = fn_d1
        info = '财务指标—盈利能力'
        x=DataAPI.FdmtIndiRtnPitGet(ticker=z1,secID="",endDate=tt,beginDate=t0,
                                       beginYear=u"",endYear=u"",reportType=u"",publishDateEnd=u"",
                                       publishDateBegin=u"",field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    #10 合并利润表TTM
    def FdmtISTTMPITGet_adair():
        fn_d1= 'FdmtISTTMPITGet_%s' % tt
        fn2_d1 = fn_d1
        info = '合并利润表TTM'
        x=DataAPI.FdmtISTTMPITGet(ticker=z1,secID=u"",endDate=tt,beginDate=t0,publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")        
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))      
    
    #11 合并现金流量表（TTM Point in time）
    def FdmtCFTTMPITGet_adair():
        fn_d1= 'FdmtCFTTMPITGet_%s' % tt
        fn2_d1 = fn_d1
        info = '合并现金流量表（TTM Point in time）'
        x=DataAPI.FdmtCFTTMPITGet(ticker=z1,secID=u"",endDate=tt,beginDate=t0,publishDateEnd=u"",publishDateBegin=u"",field=u"",pandas="1")        
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
    
    #12 合并利润表（单季度 Point in time）    
    #DataAPI.FdmtISQPITGet(ticker=u"688002",secID="",endDate="",beginDate="",beginYear=u"",endYear=u"",reportType=u"",publishDateEnd="",publishDateBegin="",isNew="",isCalc="",field=u"",pandas="1")    
    def FdmtISQPITGet_adair():
        fn_d1= 'FdmtISQPITGet_%s' % tt
        fn2_d1 = fn_d1
        info = '合并利润表TTM'
        x=DataAPI.FdmtISQPITGet(ticker=z1,secID="",endDate=tt,beginDate=t0,beginYear=u"",endYear=u"",reportType=u"",
                                publishDateEnd=u"",publishDateBegin=u"",isNew="",isCalc="",field=u"",pandas="1")       
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))   
    
    #14 业绩预告 S49-p1
    def get_FdmtEfGet_S49():
        fn_d1= 'FdmtEfGet_S49_%s' % tt
        fn2_d1 = fn_d1
        info = '业绩快报'
        x=DataAPI.FdmtEfGet(secID=u"",ticker=z1,publishDateBegin=u"",endDate=tt,beginDate=t0,field=u"",pandas="1")
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1))  
        
    #16 S53更新
    def get_FdmtISQGet():
        fn_d1= 'FdmtISQGetS53_%s' % tt
        fn2_d1 =  fn_d1
        info = '合并利润表（单季度，根据所有会计期末最新披露数据计算）'
        x=DataAPI.FdmtISQGet(ticker=u"",secID=u"",endDate=tt,beginDate=t0,beginYear=u"",endYear=u"",reportType=u"",field=u"",pandas="1")       
        save_data_adair(fn_d1,x)
        print('%s已经更新到%s' % (info,fn2_d1)) 
    #1合并利润表
    get_FdmtISGet()
    #2资产重组表
    get_EquRestructuringGet()
    #3合并资产负债表
    get_FdmtBSGet()
    #4主营业务构成
    get_FdmtMainOperNGet()
    #5财务衍生数据
    get_FdmtDerPitGet()
    #6财务指标 营运能力
    get_FdmtIndiTrnovrPitGet()
    #7 财务衍生数据
    get_FdmtIndiPSPitGet()
    #8 合并现金流量表
    get_FdmtCFGet()
    #9 财务指标—盈利能力 (Point in time)
    get_FdmtIndiRtnPitGet()
    #10 合并利润表TTM
    FdmtISTTMPITGet_adair()
    #11 合并现金流量表（TTM Point in time）
    FdmtCFTTMPITGet_adair()
    #12 合并利润表（单季度 Point in time）    
    FdmtISQPITGet_adair()
    #13 业绩快报
    get_FdmtEeGet_S26()
    #14 业绩预告
    get_FdmtEfGet_S49()
    #15基金持仓明细
    #get_FundHoldingsGet()
    #16 合并利润表（单季度，根据所有会计期末最新披露数据计算）
    get_FdmtISQGet()

#最多按照周取
#15基金持仓明细
def get_FundHoldingsGet(inputdata):
    t0,tt=inputdata
    fn_d2 = 'FundHoldingsGet_S51%s' % tt
    secID = DataAPI.FundGet(secID=u"",ticker=u"",etfLof=u"",listStatusCd=u"",category=['E','H','B','SB','M','O'],idxID=u"",idxTicker=u"",operationMode=u"",beginDate=u"",endDate=u"",status="",field='secID',pandas="1")
    secID=secID.secID.unique().tolist()
    x=DataAPI.FundHoldingsGet(secID=secID,ticker=u"",reportDate=u"",beginDate=t0,endDate=tt,secType="",
                              holdingTicker="",holdingSecID="",field=u"",pandas="1")
    save_data_adair(fn_d2,x)
    print('基金持仓明细%s' % fn_d2)

#按照年
t0_1 = ['%d0101' % i for i in range(2000,2021)]
tt_1 = ['%d1231' % i for i in range(2000,2021)]
pool = ThreadPool(processes=num_core)
temp = pool.map(get_finance_daybyday, zip(t0_1,tt_1))
pool.close()
pool.join() 
#按照周
tref=pd.date_range('20000101','20200916').astype(str).tolist()
tref = [i.replace('-','') for i in tref]
T = len(tref)
r=7
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
pool = ThreadPool(processes=num_core)
temp = pool.map(get_FundHoldingsGet, zip(t0_1,tt_1))
pool.close()
pool.join()     