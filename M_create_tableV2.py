# -*- coding: utf-8 -*-
"""
Created on Sun Jun 14 15:38:07 2020

@author: adair2019
"""

import json
import os
from sqlalchemy import create_engine
import pandas as pd
import pymysql
import time
import datetime


tt = time.strftime("%Y%m%d", time.localtime())

#must be set before using
if os.path.exists('localMark.py'):
    server_sel = False
else:
    server_sel = True
if server_sel:
    from yq_toolsSFZ import pn,user_name,pass_wd,port,host,db_name1
else:
    from yq_toolsS45 import pn,user_name,pass_wd,port,host,db_name1
    db26 = 'S26'
    #eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
    eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db26)
    eg26 = create_engine(eng_str)
    
    db_cub1 = 'yuqer_cubdata'
    eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_cub1)
    eg_cub1 = create_engine(eng_str)
    
    db_fac = 'factors_com'
    eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_fac)
    eg_fac = create_engine(eng_str)
    
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@%s:%d/%s?charset=utf8' % (user_name,pass_wd,host,port,db_name1)
engine = create_engine(eng_str)


def get_file_name(file_dir,file_type):
    L=[]
    L_s = []   
    for root, dirs, files in os.walk(file_dir):  
        for file in files:  
            if os.path.splitext(file)[1] == file_type:  
                L.append(os.path.join(root, file))  
                L_s.append(file)
    return L,L_s

def add_0(x):
    if isinstance(x,int):
        x= '%0.6d' % x
    else:
        x=x.rjust(6,'0')
    return x

#added on 2020/3/28 S19
def remove_datacube_attr(x):
    x=x[0:6]
    return x

def read_yuqer_datacube_data(fn):
    x = pd.read_csv(fn,index_col=0)
    x = x.stack().reset_index()
    x.rename(columns={x.columns[0]:'tradingdate',x.columns[1]:'symbol',x.columns[2]:'f_val'},inplace=True)
    x['symbol'] = x['symbol'].apply(remove_datacube_attr)
    _,sub_fn = os.path.split(fn)
    info = sub_fn.split('.')
    info=info[0]
    return x,info

def create_table(db_name,tn_name,var_name,var_type,key_str):
    #check 
    x=pd.read_sql('show databases',engine)
    x= x.Database.tolist()
    x1=[]
    for sub_x in x:
        x1.append(sub_x.lower())
    if not db_name.lower() in x1:
        do_sql_order('create database %s;' % db_name,db_name1)
    #连接本地数据库
    db = pymysql.connect(host,user_name,pass_wd,db_name)
    #创建游标
    cursor = db.cursor()
    #创建
    var_info=''
    for id,sub_var in enumerate(var_name):
        var_info=var_info + sub_var + ' ' + var_type[id] + ','
    var_info = var_info[:-1]    
    if len(key_str)>0:
        sql = 'create table  `%s`(%s,primary key(%s))' % (tn_name,var_info,key_str)    
    else:
        sql = 'create table  `%s`(%s)' % (tn_name,var_info)  

    try:
        # 执行SQL语句
        cursor.execute(sql)
        print("创建数据库成功")
    except Exception as e:
        print("创建数据库失败：case%s"%e)
    finally:
        #关闭游标连接
        cursor.close()
        # 关闭数据库连接
        db.close()
        
def do_sql_order(order_str,db_name):
    db = pymysql.connect(host,user_name,pass_wd,db_name)
    #创建游标
    cursor = db.cursor()
    try:
        # 执行SQL语句
        cursor.execute(order_str)
        print("执行mysql命令成功")
    except Exception as e:
        print("执行mysql命令失败：case%s"%e)
    finally:
        #关闭游标连接
        cursor.close()
        # 关闭数据库连接
        db.close()
       

var_info = ['secID', 'partyID', 'ticker', 'secShortName', 'exchangeCD', 'endDate',
       'tRevenue', 'revenue', 'intIncome', 'premEarned', 'commisIncome',
       'TCogs', 'COGS', 'intExp', 'commisExp', 'premRefund', 'NCompensPayout',
       'reserInsurContr', 'policyDivPayt', 'reinsurExp', 'bizTaxSurchg',
       'sellExp', 'adminExp', 'finanExp', 'assetsImpairLoss', 'fValueChgGain',
       'investIncome', 'AJInvestIncome', 'forexGain', 'assetsDispGain',
       'othGain', 'operateProfit', 'NoperateIncome', 'NoperateExp',
       'NCADisploss', 'TProfit', 'incomeTax', 'NIncome', 'goingConcernNI',
       'quitConcernNI', 'NIncomeAttrP', 'minorityGain', 'othComprIncome',
       'TComprIncome', 'comprIncAttrP', 'comprIncAttrMS']
var_type = []
for i in var_info:
    var_type.append('float')
var_type[:6] = ['varchar(15)','int','varchar(8)','varchar(10)','varchar(6)','date']
create_table(db_name1,'FdmtISQGetS53'.lower(),var_info,var_type,[])


var_info = ['secCode', 'repForeTime', 'foreYear', 'conIncomeType', 'conIncome']
var_type = ['varchar(10)','date','int','int','float']
create_table(db_name1,'ResConSecIncomeGetS18'.lower(),var_info,var_type,'secCode,repForeTime,conIncomeType')

#S56添加
var_info = ['secID', 'ticker', 'secShortName', 'secShortNameEn', 'exchangeCD',
       'tradeDate', 'moneyInflow', 'moneyOutflow', 'netMoneyInflow',
       'netInflowRate', 'netInflowOpen', 'netInflowClose', 'updateTime']
var_type = []
for i in var_info:
    if i in ['secID','secShortName']:
        var_type.append('varchar(20)')
    elif i in ['ticker', 'exchangeCD']:
        var_type.append('varchar(10)')
    elif i in ['secShortNameEn']:
        var_type.append('text')
    elif i in ['tradeDate']:
        var_type.append('date')
    elif i in ['updateTime']:
        var_type.append('datetime')
    else:
        var_type.append('float')
create_table(db_name1,'MktEquFlowGetS56'.lower(),var_info,var_type,[]) 

var_info = ['tradeCD', 'endDate', 'secID', 'ticker', 'ticketCode', 'partyName',
       'partyVol', 'partyPct', 'updateTime']
var_type = []
for i in var_info:
    if i in ['secID']:
        var_type.append('varchar(20)')
    elif i in ['partyName']:
        var_type.append('text')
    elif i in ['ticker', 'ticketCode']:
        var_type.append('varchar(10)')
    elif i in ['tradeCD']:
        var_type.append('int')
    elif i in ['endDate']:
        var_type.append('date')
    elif i in ['updateTime']:
        var_type.append('datetime')
    elif i in ['partyVol']:
        var_type.append('double')
    else:
        var_type.append('float')
create_table(db_name1,'HKshszHoldGetS56'.lower(),var_info,var_type,[])    

var_info = ['tradeDate', 'secID', 'ticker', 'assetClass', 'exchangeCD',
       'secShortName', 'currencyCD', 'finVal', 'finBuyVal', 'finRefundVal',
       'secVol', 'secSellVol', 'secRefundVol', 'secVal', 'tradeVal',
       'updateTime']
var_type = []
for i in var_info:
    if i in ['secID']:
        var_type.append('varchar(20)')
    elif i in ['secShortName']:
        var_type.append('varchar(40)')
    elif i in ['ticker']:
        var_type.append('varchar(10)')
    elif i in ['assetClass','exchangeCD','currencyCD']:
        var_type.append('varchar(6)')
    elif i in ['tradeDate']:
        var_type.append('date')
    elif i in ['updateTime']:
        var_type.append('datetime')
    else:
        var_type.append('double')
create_table(db_name1,'FstDetailGetS56'.lower(),var_info,var_type,[])


var_info = ['secID', 'ticker', 'exchangeCD', 'secShortName', 'tradeDate',
       'preClosePrice', 'actPreClosePrice', 'openPrice', 'highestPrice',
       'lowestPrice', 'closePrice', 'turnoverVol', 'turnoverValue', 'SMA10',
       'SMA20', 'SMA50', 'SMA250', 'chg', 'chgPct', 'marketValue',
       'negMarketValue', 'PE', 'PE1', 'PB', 'updateTime']
var_type = []
for i in var_info:
    if i in ['secID']:
        var_type.append('varchar(20)')
    elif i in ['ticker']:
        var_type.append('varchar(12)')
    elif i in ['exchangeCD']:
        var_type.append('varchar(6)')
    elif i in ['secShortName']:
        var_type.append('varchar(20)')
    elif i in ['tradeDate']:
        var_type.append('date')
    elif i in ['updateTime']:
        var_type.append('datetime')
    else:
        var_type.append('float')
create_table(db_name1,'MktHKEqudGetS54'.lower(),var_info,var_type,'ticker,tradeDate')
    
    
var_info=['ticker', 'exchangeCD', 'tradeDate', 'openPrice', 'highestPrice',
       'lowestPrice', 'closePrice', 'turnoverVol']
var_type = []
for i in var_info:
    if i in ['ticker']:
        var_type.append('varchar(20)')
    elif i in ['exchangeCD']:
        var_type.append('varchar(10)')
    elif i in ['tradeDate']:
        var_type.append('date')
    else:
        var_type.append('float')
create_table(db_name1,'MktUsequdGetS54'.lower(),var_info,var_type,'ticker,tradeDate')