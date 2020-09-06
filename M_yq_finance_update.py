# -*- coding: utf-8 -*-
"""
Created on Mon Mar 23 14:37:02 2020
合并利润表TTM
@author: adair2019
"""

#import zipfile
import json
import os
from sqlalchemy import create_engine
import pandas as pd
import pymysql
import time

t_max=time.strftime("%Y-%m-%d", time.localtime())

with open('para.json','r',encoding='utf-8') as f:
    para = json.load(f)
    
pn = para['yuqerdata_dir']
user_name = para['mysql_para']['user_name']
pass_wd = para['mysql_para']['pass_wd']
port = para['mysql_para']['port']

db_name1 = 'yuqerdata'
tn_name = 'factor_yuqer'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+mysqlconnector://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name1)
engine = create_engine(eng_str)

db_name3 = 'gtadata'
eng_str='mysql+mysqlconnector://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name3)
engine3 = create_engine(eng_str)

#tt_str0 = '2019-01-01'

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

def do_sql_order(order_str,db_name):
    db = pymysql.connect("localhost",user_name,pass_wd,db_name)
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
sql_str = 'delete from %s where %s >="%s"'

_,fns_csv = get_file_name(pn,'.csv')
_,fns_csv1 = get_file_name(pn,'.txt')
for i in fns_csv1:
    fns_csv.append(i)

fns_data = []
for i in range(20):
    fns_data.append([])

for sub_fn in fns_csv:
    if 'EquRestructuringGet' in sub_fn:
        fns_data[0] = os.path.join(pn,sub_fn)
    elif 'FdmtISGet' in sub_fn:
        fns_data[1] = os.path.join(pn,sub_fn)
    elif 'FdmtBSGet' in sub_fn:
        fns_data[2] = os.path.join(pn,sub_fn)
    elif 'FdmtMainOperNGet' in sub_fn:
        fns_data[3] = os.path.join(pn,sub_fn)
    elif 'FdmtEeGet' in sub_fn:
        fns_data[4] = os.path.join(pn,sub_fn)
    elif 'MktStockFactorsOneDayGet' in sub_fn and 'MktStockFactorsOneDayGet_add' not in sub_fn:
        fns_data[5] = os.path.join(pn,sub_fn)
    elif 'FdmtDerPitGet' in sub_fn:
        fns_data[6] = os.path.join(pn,sub_fn)
    elif 'MktStockFactorsOneDayGet_add' in sub_fn:
        fns_data[7] = os.path.join(pn,sub_fn)
    elif 'FdmtIndiTrnovrPitGet' in sub_fn:
        fns_data[8] = os.path.join(pn,sub_fn)
    elif 'FAR_Finidx' in sub_fn:
        fns_data[9] = os.path.join(pn,sub_fn)
    elif 'FdmtIndiPSPitGet' in sub_fn:
        fns_data[10] = os.path.join(pn,sub_fn)
    elif 'FdmtCFGet' in sub_fn:
        fns_data[11] = os.path.join(pn,sub_fn)
    elif 'FdmtIndiRtnPitGet' in sub_fn:
        fns_data[12] = os.path.join(pn,sub_fn)
    elif 'FdmtISTTMPITGet' in sub_fn:
        fns_data[13] = os.path.join(pn,sub_fn)
    elif 'FdmtCFTTMPITGet' in sub_fn:
        fns_data[14] = os.path.join(pn,sub_fn)
    elif 'FdmtISQPITGet' in sub_fn:
        fns_data[15].append(os.path.join(pn,sub_fn))
    elif 'FdmtEfGet_S49' in sub_fn:
        fns_data[16] = os.path.join(pn,sub_fn)
    elif 'FundHoldingsGet_S51' in sub_fn:
        fns_data[17].append(os.path.join(pn,sub_fn))
            
          
#1 EquRestructuringGet 重组数据
data_id = 0
info = '重组数据'
if len(fns_data[data_id])>0:
    sub_fn =fns_data[data_id]
    x1 = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                     dtype={'ticker':str})    
    if len(x1)>0:
        table_name = 'EquRestructuringGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        y=x1[['secID','ticker','secShortName','exchangeCD','publishDate',
              'iniPublishDate','finPublishDate','program','isSucceed','restructuringType',
              'underlyingType','underlyingVal','expenseVal','isRelevance','isMajorRes','payType']]
        
        y.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(sub_fn)
#
data_id = 1    
info = '合并利润表'
if len(fns_data[data_id])>0:
    sub_fn =fns_data[data_id]
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'nincome'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#
data_id=2
info = '合并资产负债表'
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,engine='python',encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'yq_FdmtBSGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
    
data_id=3
info = '主营业务构成'
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'yq_FdmtMainOperNGet_update'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
# 业绩快报 S49 净利润断层方法添加
data_id=4
info = '业绩快报'
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'yq_FdmtEeGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
    
data_id = 6  
info = '财务衍生数据'  
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtDerPitGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#
data_id = 8  
info = '财务指标-运营能力'  
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtIndiTrnovrPitGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#
data_id = 9    
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],sep='\t',header=0,engine='python',encoding='utf-16')
    x1['Stkcd'] = x1['Stkcd'].apply(add_0)
    table_name = 'FAR_Finidx'
    sql_str1 = 'select Annodt from %s order by Annodt desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engine3)
    info = '财务指标-运营能力'
    if not t.empty:
        tt_str = str(t.Annodt[0])
    else:
        tt_str = '1990-01-01'
    do_sql_order(sql_str % (table_name,'Annodt',tt_str),db_name3)
    x2 = x1.loc[x1.Annodt>=tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engine3,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.Annodt.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[data_id]) 
#
data_id = 10  
info = '财务指标-每股'  
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,engine='python',encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtIndiPSPitGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#    
data_id = 11 
info = '合并现金流量表 (Point in time)'  
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtCFGetAll'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#
data_id = 12   
info = '财务指标—盈利能力'
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,engine='python',encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtIndiRtnPitGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#13合并利润表TTM FdmtISTTMPITGet
data_id = 13 
info = '合并利润表TTM'  
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,engine='python',encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtISTTMPITGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#14 FdmtCFTTMPITGet  合并现金流量表（TTM Point in time）
data_id = 14 
info = '合并现金流量表TTM'  
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,engine='python',encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'yq_FdmtCFTTMPITGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])
#15 FdmtISQPITGet
#合并利润表（单季度 Point in time）
#转换思路，删除读取数据的最小日期，然后保留最新的数据即可
data_id = 15   
info = '合并利润表（单季度 Point in time）'
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x1 = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        table_name = 'yq_FdmtISQPITGet'
        if len(x1)>0:
            t0 = x1.publishDate.astype(str).min()
            t2 = x1.publishDate.astype(str).max()
        
            sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
            do_sql_order(sql_str,db_name1)
            x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
            print('%s:%s' % (info,t2))
        os.remove(sub_fn) 

# 业绩预告 S49 净利润断层方法添加
data_id=16
info = '业绩预告'
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",
                     dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'yq_FdmtEfGet'
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    os.remove(fns_data[data_id])   
    
#FundHoldingsGet_S51
sub_id = 17
if len(fns_data[sub_id])>0:
    info = '基金持仓明细'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str,'holdingTicker':str})
        tn = 'FundHoldingsGet_S51'
        if len(x)>0:
            t0 = x.reportDate.astype(str).min()
            t2 = x.reportDate.astype(str).max()        
            sql_str = 'delete from %s where reportDate>="%s"' % (tn,t0)
            do_sql_order(sql_str,db_name1)            
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('%s已经更新至%s' % (info,t2))
        os.remove(sub_fn) 