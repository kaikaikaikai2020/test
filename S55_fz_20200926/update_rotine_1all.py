
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
#from multiprocessing.dummy import Pool as ThreadPool
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
def get_daybyday(inputdata):
    t0,tt=inputdata
    #S53 宏观数据    
    def EcoDataProGet_update(t0,tt):
        fn_d2 = 'EcoDataProGet_S53_%s' % t0
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        x=DataAPI.EcoDataProGet(indicID=['1020000004', '1030000011', '1040000050', '1040000702',
               '1070000007', '1070000009', '1090001390', '1090001558'], beginDate=t0, endDate=tt, field=u"")
        save_data_adair(fn_d2,x)
        print('S53宏观数据已经更新 %s' % tt) 
        
    #股票基本信息
    def get_symbol_basic_info(t0,tt):     
        fn_d2 = 'EquGet%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 not in list_files():
            x = DataAPI.EquGet(secID=u"",ticker=u"",equTypeCD=u"A",listStatusCD=u"",
                       exchangeCD="",ListSectorCD=u"",field=u"",pandas="1")   
            save_data_adair(fn_d2,x,'EquGet')
            print('股票基本信息已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，股票基本信息已经更新，未执行' % fn2_d2) 
            
    # S53 上市公司特殊状态
    def EquInstSstateGet_adair(t0,tt):
        fn_d2 = 'EquInstSstateGet%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        
        x=DataAPI.EquInstSstateGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x)
        print('已经更新到%s' % (fn_d2))
        
    #S51 基金基本信息
    def get_FundGet(t0,tt):
        fn_d2 = 'FundGet_S51%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        
        fields = ['secID', 'ticker', 'secShortName', 'tradeAbbrName', 'category',
               'operationMode', 'indexFund', 'etfLof', 'isQdii', 'isFof', 'isGuarFund',
               'guarPeriod', 'guarRatio', 'exchangeCd', 'listStatusCd', 'managerName',
               'status', 'establishDate', 'listDate', 'delistDate', 'expireDate',
               'managementCompany', 'managementFullName', 'custodian',
               'custodianFullName',  'perfBenchmark',
               'circulationShares', 'isClass', 'idxID', 'idxTicker', 'idxShortName',
               'managementShortName', 'custodianShortName']
        t=['E','H','B','SB','M','O']
        y = DataAPI.FundGet(secID=u"",ticker=u"",etfLof=u"",listStatusCd=u"",
                            category=t,idxID=u"",idxTicker=u"",operationMode=u"",beginDate=u"",endDate=u"",status="",field=fields,pandas="1")
        save_data_adair(fn_d2,y)
        print('已经更新到%s' % (fn_d2))
        
    ##ETF基金申赎清单基本信息
    def FundETFPRListGet_adair(t0,tt):
        fn_d2 = 'FundETFPRListGet_adair%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        
        x = pd.DataFrame()
        for sub_code in ['510050','510300','510500']:
            sub_x=DataAPI.FundETFPRListGet(secID=u"",ticker=sub_code,beginDate=t0,endDate=tt,field=u"",pandas="1")
            x = x.append(sub_x)
        save_data_adair(fn_d2,x)
        print('已经更新到%s' % (fn_d2))
        
    #期货合约信息 
    def FutuGet_adair(t0,tt):
        info = '期货合约信息'
        fn_d2 = 'FutuGet_adair%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        x=DataAPI.FutuGet(secID=u"",ticker=u"",exchangeCD=u"",contractStatus="",contractObject=u"",field=u"",pandas="1")
        x.drop(['deliGrade','deliPriceMethod','settPriceMethod'],axis=1,inplace=True)
        save_data_adair(fn_d2,x)
        print('%s已经更新到%s' % (info,fn_d2))
        
    #申万获取行业
    def get_industry_data_adair(t0,tt):    
        fn_d2 = 'EquIndustryGet%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 not in list_files():
            x =DataAPI.EquIndustryGet(secID=u"",ticker=u"",
                                  industryVersionCD=u"010303",industry=u"",industryID=u"",industryID1=u"",industryID2=u"",
                                  industryID3=u"",intoDate=u"",equTypeID=u"",field=u"",pandas="1")  
            save_data_adair(fn_d2,x)
            print('申万获取行业信息已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，申万获取行业信息已经更新，未执行' % fn2_d2) 
    #S49 申万行业回填（含科创板）    
    def get_MdSwBackGet(t0,tt):
        fn_d2 = 'MdSwBackGet_data%s' % tt
        fn2_d2=  '%s.csv' % fn_d2
        if fn2_d2 in list_files():
            return
        x=DataAPI.MdSwBackGet(secID=u"",ticker=u"",intoDate=u"",outDate=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x)
        print('申万行业回填（含科创板）%s' % fn_d2)
        
    EcoDataProGet_update(t0,tt)
    get_symbol_basic_info(t0,tt)
    EquInstSstateGet_adair(t0,tt)
    get_FundGet(t0,tt)
    FundETFPRListGet_adair(t0,tt)
    FutuGet_adair(t0,tt)
    get_industry_data_adair(t0,tt)
    get_MdSwBackGet(t0,tt)
    

get_daybyday(['20000101','20200926'])
