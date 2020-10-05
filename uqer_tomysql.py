# -*- coding: utf-8 -*-
"""
Created on Mon Jan 27 16:46:57 2020
update20200323
增加了S26需要的10因子数据

update 20200327
S19 国泰安三因子数据
S19 优矿数据立方数据
有一个需要pandas 0.22.0
运行时pandas版本为0.24.2

#S19添加 
基金日行情   ETF
期货主力、连续合约日行情  更新

期货主力合约
S5添加
期货会员成交量排名
期货期货会员空头持仓排名
期货期货会员多头持仓排名
22期货合约信息
S14
仓单数据
S28 增加tdx分钟数据接口
akshare data
S39 
周后复权股票数据
周指数数据
@author: adair002
S49
申万行业回填（含科创板）
547行
服务器版本
akshare 升级后，fix bug
requests 2.22  up to 2.23.0
akshare czce爬取数据中间逗号影响结果，修正 20200911
"""

import os
from sqlalchemy import create_engine
import pandas as pd
import pymysql
import time

z_check = True
tt = time.strftime("%Y%m%d", time.localtime())

#must be set before using
server_sel = False
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

def get_ini_data(tn,var_name,db=engine):
    sql_str = 'select %s from %s order by %s desc limit 1' % (var_name,tn,var_name)
    t0 = pd.read_sql(sql_str,db)
    return t0[var_name].astype(str).values[0]
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

def get_tradingdate(t1,t2):
    sql_str = '''select tradeDate from yq_index
                where tradeDate >= '%s' and tradeDate<='%s' 
                and symbol = '000001' order by tradeDate '''
    sql_str = sql_str % (t1,t2)
    t = pd.read_sql(sql_str,engine)
    return t.tradeDate.to_list()

#将获取的dict数据转化为pandas数据
def com_dict_data(x,tradingdate):
    key_values = list(x.keys())
    i = 1
    for sub_key_value in key_values:
        y=x[sub_key_value]
        col_name = y.columns.tolist()
        col_name.insert(0,'codename')
        col_name.insert(0,'tradingdate')
        y.reindex(columns=col_name)
        y['tradingdate']=tradingdate
        y['codename']=sub_key_value
        y.rename(columns={'long_open_interest':'long_openIntr','long_open_interest_chg':'long_openIntr_chg',
                          'short_open_interest':'short_openIntr','short_open_interest_chg':'short_openIntr_chg'},inplace=True)
        if i == 1:
            Y = y;
            i=i+1
        else:
            Y=pd.concat([Y,y])
    return Y
        
def rm_spec_sym_adair(x):
    def rm_douhao(x):
        if isinstance(x,str):
            return x.replace(',','')
        else:
            return x
    for sub_col in x.columns:
        x[sub_col] = x[sub_col].apply(lambda x:rm_douhao(x))
    return x

def ak_null_set(x):
    if x == '-':
        return '0'
    else:
        return x

def ak_str2float(x,col_str):
    if  isinstance(x[col_str].values[0],str):                
        y = pd.DataFrame(x[col_str].str.replace(',', ''))
        y[col_str] = y[col_str].apply(lambda x:ak_null_set(x)).astype(float)
    else:
        y = x[col_str]
    return y
    #x["涨跌幅"] = pd.DataFrame(round(x['涨跌幅'].str.replace('%', '').astype(float) / 100, 6))
sql_str_deldata = 'delete from %s where %s >="%s"'
#数据立方因子
yq_dc_factor1 =  ['DividendPS']
#,'FY12P' is be deleted due to missing data
yq_dc_factor2 =  ['DAREC','DAREV','DASREV','EBITDA','EPIBS','ForwardPE',
                  'GREC','GREV','GSREV']

for i,j in enumerate(yq_dc_factor1):
    yq_dc_factor1[i]=j+'.csv'

for i,j in enumerate(yq_dc_factor2):
    yq_dc_factor2[i]=j+'.csv'
           
_,fns_csv = get_file_name(pn,'.csv')
_,fns_csv1 = get_file_name(pn,'.txt')
for i in fns_csv1:
    fns_csv.append(i)
    
fns_data = [];
for i in range(200):
    fns_data.append([])

for sub_fn in fns_csv:
    if 'EquGet' in sub_fn:
        fns_data[0] = os.path.join(pn,sub_fn)
    elif 'indicator_data' in sub_fn:
        fns_data[1].append(os.path.join(pn,sub_fn))
    elif 'tickerday_data' in sub_fn:
        fns_data[2].append(os.path.join(pn,sub_fn))
    elif 'tradingdate' in sub_fn:
        fns_data[3] = os.path.join(pn,sub_fn)
    elif 'MktEqumAdjAfGet' in sub_fn:
        fns_data[4].append(os.path.join(pn,sub_fn))
    elif 'EquIndustryGet' in sub_fn:
        fns_data[5] = os.path.join(pn,sub_fn)
    elif 'st_data' in sub_fn:
        fns_data[6].append(os.path.join(pn,sub_fn))
    elif 'IdxCloseWeightGet' in sub_fn:
        fns_data[7].append(os.path.join(pn,sub_fn))
    elif 'yuqer_cal' in sub_fn:
        fns_data[8].append(os.path.join(pn,sub_fn))
    elif 'MktEqudAdjAfGet_data' in sub_fn:
        fns_data[9].append(os.path.join(pn,sub_fn))
    elif 'MktIdxmGet' in sub_fn:
        fns_data[10].append(os.path.join(pn,sub_fn))
    elif 'MktStockFactorsOneDayGet_S26' in sub_fn and 'MktStockFactorsOneDayGet_add' not in sub_fn:
        fns_data[11] = os.path.join(pn,sub_fn)
    elif 'MktStockFactorsOneDayGet_add_S26' in sub_fn:
        fns_data[12] = os.path.join(pn,sub_fn)
    elif 'STK_MKT_ThrfacDay.txt'.lower() == sub_fn.lower():
        fns_data[13] = os.path.join(pn,sub_fn)
    elif sub_fn in yq_dc_factor1:
        fns_data[14].append(os.path.join(pn,sub_fn))
    elif sub_fn in yq_dc_factor2:
        fns_data[15].append(os.path.join(pn,sub_fn))
    elif 'get_S19_factors_added' in sub_fn:
        fns_data[16] = os.path.join(pn,sub_fn)
    elif 'MktFunddget_adair' in sub_fn:
        fns_data[17].append( os.path.join(pn,sub_fn))
    elif 'MktMFutdGet_adair' in sub_fn:
        fns_data[18].append( os.path.join(pn,sub_fn))
    elif 'MktFutMTRGet' in sub_fn:
        fns_data[19].append(os.path.join(pn,sub_fn))
    elif 'MktFutMSRGet' in sub_fn:
        fns_data[20].append( os.path.join(pn,sub_fn))
    elif 'MktFutMLRGet' in sub_fn:
        fns_data[21].append(os.path.join(pn,sub_fn))
    elif 'FutuGet' in sub_fn:
        fns_data[22]=os.path.join(pn,sub_fn)  
    elif 'MktFutWRdGet' in sub_fn:
        fns_data[23].append(os.path.join(pn,sub_fn))
    elif 'MktConsBondPerfGet_adair' in sub_fn:
        fns_data[24].append( os.path.join(pn,sub_fn))
    elif 'MktIdxdEvalGet_adair' in sub_fn:
        fns_data[25].append(os.path.join(pn,sub_fn))  
    elif 'FundETFConsGet' in sub_fn:
        fns_data[26].append(os.path.join(pn,sub_fn))
    elif 'FundETFPRListGet' in sub_fn:
        fns_data[27].append(os.path.join(pn,sub_fn))
    elif 'MktEquwAdjAfGet' in sub_fn:
        fns_data[28].append(os.path.join(pn,sub_fn))
    elif 'MktIdxwGet_adair' in sub_fn:
        fns_data[29].append(os.path.join(pn,sub_fn))
    elif 'SecIDGet' in sub_fn:
        fns_data[30].append(os.path.join(pn,sub_fn))
    elif 'SecHaltGet' in sub_fn:
        fns_data[31].append(os.path.join(pn,sub_fn))
    elif 'SecSTGet' in sub_fn:
        fns_data[32].append(os.path.join(pn,sub_fn))
    elif 'MktStockFactorsOneDayGet_re' in sub_fn:
        fns_data[33].append(os.path.join(pn,sub_fn))
    elif 'SocialDataGubaGet_data' in sub_fn:
        fns_data[34].append(os.path.join(pn,sub_fn))
    elif 'MdSwBackGet_data' in sub_fn:   #申万行业回填（含科创板）
        fns_data[35].append(os.path.join(pn,sub_fn))
    elif 'FundGet_S51' in sub_fn:
        fns_data[36].append(os.path.join(pn,sub_fn))
    elif 'yq_FundAssetsGet_S51' in sub_fn:
        fns_data[37].append(os.path.join(pn,sub_fn))
    elif 'FundNavGet_S51' in sub_fn:
        fns_data[38].append(os.path.join(pn,sub_fn))
    elif 'MktStockFactorsOneDayProGet' in sub_fn:
        fns_data[39].append(os.path.join(pn,sub_fn))
    elif 'MktCmeFutdGet_S50' in sub_fn:
        fns_data[40].append(os.path.join(pn,sub_fn))
    elif 'MktIborGet_adair' in sub_fn:
        fns_data[41].append(os.path.join(pn,sub_fn))
    elif 'EcoDataProGet_S53' in sub_fn:
        fns_data[42].append(os.path.join(pn,sub_fn))
    elif 'EquInstSstateGet' in sub_fn:
        fns_data[43].append(os.path.join(pn,sub_fn))
    elif 'MktEqudGet0S53' in sub_fn:
        fns_data[44].append(os.path.join(pn,sub_fn))
    elif 'MktEqudAdjAfGetF0S53' in sub_fn:
        fns_data[45].append(os.path.join(pn,sub_fn))
    elif 'MktEqudAdjAfGetF1S53' in sub_fn:
        fns_data[46].append(os.path.join(pn,sub_fn))
    elif 'MktEquFlowGetS56' in sub_fn:
        fns_data[47].append(os.path.join(pn,sub_fn))
    elif 'HKshszHoldGetS56' in sub_fn:
        fns_data[48].append(os.path.join(pn,sub_fn))
    elif 'FstDetailGetS56' in sub_fn:
        fns_data[49].append(os.path.join(pn,sub_fn))
    elif 'ResConSecIncomeGetS18' in sub_fn:
        fns_data[50].append(os.path.join(pn,sub_fn))
    elif 'ResConInduSwGet18' in sub_fn:
        fns_data[51].append(os.path.join(pn,sub_fn))
    elif 'ResConSecDataGet18' in sub_fn:
        fns_data[52].append(os.path.join(pn,sub_fn))
    elif 'ResConSecDerivativeGet18' in sub_fn:
        fns_data[53].append(os.path.join(pn,sub_fn))
    elif 'ResConTarpriScoreGet18' in sub_fn:
        fns_data[54].append(os.path.join(pn,sub_fn))
    elif 'NewsSentiIndexGetS55FZ' in sub_fn:
        fns_data[55].append(os.path.join(pn,sub_fn))
    elif 'NewsHeatIndexNewGetS55FZ' in sub_fn:
        fns_data[56].append(os.path.join(pn,sub_fn))
    if 'EquRestructuringGet' in sub_fn:
        fns_data[57].append(os.path.join(pn,sub_fn))
    elif 'FdmtISGet' in sub_fn:
        fns_data[58].append(os.path.join(pn,sub_fn))
    elif 'FdmtBSGet' in sub_fn:
        fns_data[59].append( os.path.join(pn,sub_fn))
    elif 'FdmtMainOperNGet' in sub_fn:
        fns_data[60].append(os.path.join(pn,sub_fn))
    elif 'FdmtEeGet' in sub_fn:
        fns_data[61].append(os.path.join(pn,sub_fn))
    #elif 'MktStockFactorsOneDayGet' in sub_fn and 'MktStockFactorsOneDayGet_add' not in sub_fn:
    #    fns_data[5].append(os.path.join(pn,sub_fn))
    elif 'FdmtDerPitGet' in sub_fn:
        fns_data[62].append( os.path.join(pn,sub_fn))
    elif 'FdmtIndiTrnovrPitGet' in sub_fn:
        fns_data[63].append(os.path.join(pn,sub_fn))
    elif 'FdmtIndiPSPitGet' in sub_fn:
        fns_data[64].append( os.path.join(pn,sub_fn))
    elif 'FdmtCFGet' in sub_fn:
        fns_data[65].append(os.path.join(pn,sub_fn))
    elif 'FdmtIndiRtnPitGet' in sub_fn:
        fns_data[66].append(os.path.join(pn,sub_fn))
    elif 'FdmtISTTMPITGet' in sub_fn:
        fns_data[67].append(os.path.join(pn,sub_fn))
    elif 'FdmtCFTTMPITGet' in sub_fn:
        fns_data[68].append(os.path.join(pn,sub_fn))
    elif 'FdmtISQPITGet' in sub_fn:
        fns_data[69].append(os.path.join(pn,sub_fn))
    elif 'FdmtEfGet_S49' in sub_fn:
        fns_data[70].append(os.path.join(pn,sub_fn))
    elif 'FundHoldingsGet_S51' in sub_fn:
        fns_data[71].append(os.path.join(pn,sub_fn))
    elif 'FdmtISQGetS53' in sub_fn:
        fns_data[72].append(os.path.join(pn,sub_fn))


data_id = 0
#1  股票基本数据已更新
if len(fns_data[data_id])>0:
    tn = 'equget'
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},encoding='utf-8')
    x = x[['ticker','exchangeCD','ListSectorCD','ListSector','secShortName',
           'listStatusCD','listDate','delistDate','equTypeCD','equType','partyID',
           'totalShares','nonrestFloatShares','nonrestfloatA','endDate','TShEquity']]
    do_sql_order('truncate table %s' % (tn),db_name1)
    x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
    print('股票基本数据已更新')
    os.remove(fns_data[data_id])


def get_inidata(tn,key_str='tradeDate'):
    sql_str = 'select %s from %s order by %s desc limit 1'
    t = pd.read_sql(sql_str % (key_str,tn,key_str),engine)
    if len(t)>0:
        t = t[t.columns[0]].astype(str).values[0]
    else:
         t = '1990-01-01'
    return t
    
#2 index
data_id = 1
if len(fns_data[data_id])>0:
    
    tn = 'yq_index'
    key_str = 'tradedate'
    tt_str = get_inidata(tn,key_str)
    
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'ticker':str}))
    x=pd.concat(x)
    if len(x)>0:
        x2 = x.loc[x.tradeDate>tt_str]
        if not x2.empty:
            x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('每日指数数据更新至%s' % x2.tradeDate.max())
        else:
            print('每日指数数据已经是最新的%s，无需更新' % tt_str) 
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
           
#3 day price
data_id=2
if len(fns_data[data_id])>0:    
    tn1 = 'yq_dayprice'
    tt_str = get_inidata(tn1)
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每日股票数据更新至%s' % tt_str)
            else:
                print('每日股数据已经是最新的%s，无需更新' % tt_str)
            os.remove(sub_fn)
        except:
            print(sub_fn)

#4 tradingdate
data_id = 3
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],engine='python')
    tn1 = 'yq_tradingdate_future'
    tt_str = '1990-01-01'
    x2 = x
    if not x2.empty:
        do_sql_order('truncate table %s' % (tn1),db_name1)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)   #每次都重新更新
        print('交易日数据更新至%s' % x2.tradingdate.max())
    else:
        print('交易日数据已经是最新的%s，无需更新' % tt_str)
    os.remove(fns_data[data_id])
        


#5 mongth data  后复权
data_id = 4
if len(fns_data[data_id])>0:
    
    tn1 = 'MktEqumAdjAfGet'.lower()
    tt_str = get_inidata(tn1,'enddate')
        
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})    
            x2 = x.loc[x.endDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每月股票后复权数据更新至%s' % tt_str)        
            else:
                print('每月股后复权数据已经是最新的%s，无需更新' % tt_str)
            os.remove(sub_fn)
        except:
            print(sub_fn)

#6 行业数据
data_id = 5
if len(fns_data[data_id])>0:
    tn = 'yq_industry_sw'
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    do_sql_order('truncate table %s' % (tn),db_name1)
    x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
    print('行业数据已更新')
    os.remove(fns_data[data_id])

#7 st
data_id = 6
if len(fns_data[data_id])>0:
    
    tn1 = 'st_info'
    tt_str = get_inidata(tn1)
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.drop_duplicates(subset=['ticker','tradeDate'], keep='first', inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('st数据更新至%s' % x2.tradeDate.max())
            else:
                print('st数据已经是最新的%s，无需更新' % tt_str)
            os.remove(sub_fn)
        except:
            print(sub_fn)
    
#8 指数成分股数据
data_id = 7
if len(fns_data[data_id])>0:
    tn1 = 'IdxCloseWeightGet'.lower()
    tt_str = get_inidata(tn1,'tradingdate')
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str,'consTickerSymbol':str})
            if len(x.index)==0:
                os.remove(sub_fn)
                continue
            x.rename(columns={'effDate':'tradingdate','consTickerSymbol':'symbol'},inplace=True)
            x2 = x.loc[x.tradingdate>tt_str]
            if not x2.empty:
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s指数成分股数据更新至%s' % (x.ticker[0],x2.tradingdate.max()))
            else:
                print('%s指数成分股数据已经是最新的%s，无需更新' % (x.ticker[0],tt_str)) 
            os.remove(sub_fn)
        except:
            print(sub_fn)
            
#9 补充交易日数据  SSS1
data_id = 8
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn)            
            if len(x.index)==0:
                os.remove(sub_fn)
                continue        
            tn1 = 'yuqer_cal'
            x2 = x
            if not x2.empty:
                do_sql_order('truncate table %s' % (tn1),db_name1)
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                #为了保持原来table的格式不变
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('交易日数据更新至%s' % (x2.calendarDate.max()))
            else:
                print('交易日数据已经是最新的%s，无需更新' % (tt_str)) 
            os.remove(sub_fn)
        except:
            print(sub_fn)
#10 后复权数据
data_id = 9
if len(fns_data[data_id])>0:
    tn1 = 'yq_MktEqudAdjAfGet'.lower()
    tt_str = get_inidata(tn1)
    
    tn2 = 'MktEqudAdjAfGet'.lower()
    tt_str2 = get_inidata(tn2)  
    
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})        
            if len(x.index)==0:
                os.remove(sub_fn)
                continue
            #tt_str = '1990-01-01'
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('后复权数据1更新至%s' % (x2.tradeDate.max()))
            else:
                print('后复权数据1已经是最新的%s，无需更新' % (tt_str)) 
            # data2    
            #tt_str = '1990-01-01'
            x2 = x.loc[x.tradeDate>tt_str2]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2[['ticker','tradeDate','accumAdjFactor']].to_sql(tn2,engine,if_exists='append',index=False,chunksize=3000)
                print('后复权数据2更新至%s' % (x2.tradeDate.max()))
            else:
                print('后复权数据2已经是最新的%s，无需更新' % (tt_str2))
            os.remove(sub_fn)
        except:
            print(sub_fn)
#11 指数月度数据mongth data
data_id = 10
if len(fns_data[data_id])>0:
    
    tn1 = 'yq_index_month'  
    tt_str = get_inidata(tn1,'enddate')
    
    for sub_fn in fns_data[data_id]:  
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            x.rename(columns={'ticker':'symbol'},inplace=True)
            x2 = x.loc[x.endDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('指数每月数据更新至%s' % x2.endDate.max())
            else:
                print('指数每月数据已经是最新的%s，无需更新' % tt_str)
            os.remove(sub_fn)
        except:
            print(sub_fn)

#基金日行情          
data_id=17
if len(fns_data[data_id])>0:
    
    table_name = 'MktFunddGet'.lower()
    tt_str = get_inidata(table_name)
    for sub_fn in fns_data[data_id]:
        try:
            x1 = pd.read_csv(sub_fn,dtype={'ticker':str},index_col=False)        
            info = '基金日行情'
            x2 = x1.loc[x1.tradeDate>tt_str]
            if not x2.empty:    
                x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                print('%s:%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn) 
        except:
            print(sub_fn)

#期货主力、连续合约日行情    
data_id=18
if len(fns_data[data_id])>0:
    table_name = 'yq_MktMFutdGet'.lower()
    tt_str = get_inidata(table_name)
    info = '期货主力、连续合约日行情'    
    for sub_fn in fns_data[data_id]:
        try:
            x1 = pd.read_csv(sub_fn,index_col=False,dtype={'ticker':str})
            x2 = x1.loc[x1.tradeDate>tt_str]
            if not x2.empty:    
                x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                print('%s:%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn) 
        except:
            print(sub_fn)
    
#19 期货会员成交量排名
data_id=19
if len(fns_data[data_id])>0:
    tn1 = 'yq_MktFutMTRGet'.lower()
    tt_str = get_inidata(tn1)
    info='期货会员成交量排名'
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})    
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn)
        except:
            print(sub_fn)
#20 期货会员空头持仓排名
data_id=20
if len(fns_data[data_id])>0:
    tn1 = 'yq_MktFutMSRGet'.lower()
    tt_str = get_inidata(tn1)
    info='期货会员空头持仓排名'    
    for sub_fn in fns_data[data_id]:    
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})    
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn)
        except:
            print(sub_fn)
#21 期货会员多头持仓排名    
data_id=21
if len(fns_data[data_id])>0:
    tn1 = 'yq_MktFutMLRGet'.lower()
    tt_str = get_inidata(tn1)
    info='期货会员多头持仓排名'
    for sub_fn in fns_data[data_id]: 
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})        
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn)
        except:
            print(sub_fn)

data_id = 22
#22 期货合约信息
if len(fns_data[data_id])>0:
    tn = 'yq_FutuGet'.lower()
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    do_sql_order('truncate table %s' % (tn),db_name1)
    x.to_sql(tn,engine,if_exists='replace',index=False,chunksize=3000)
    print('期货合约信息')
    os.remove(fns_data[data_id])

#期货仓单日报   
data_id=23
if len(fns_data[data_id])>0:
    tn1 = 'yq_MktFutWRdGet'.lower()
    tt_str = get_inidata(tn1)
    info='期货仓单日报'    
    for sub_fn in fns_data[data_id]: 
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})        
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                x2 = x2[['tradeDate', 'contractObject', 'exchangeCD', 'unit', 'warehouse',
               'preWrVOL', 'wrVOL', 'chg']]
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn)
        except:
            print(sub_fn)
    
#可转债市场
data_id=24
if len(fns_data[data_id])>0:
    table_name = 'ConvertibleBond_dayprice'.lower()
    tt_str = get_inidata(table_name)
    for sub_fn in fns_data[data_id]:
        try:        
            x1 = pd.read_csv(sub_fn,dtype={'tickerEqu':str})
            x2 = x1.loc[x1.tradeDate>tt_str]
            if not x2.empty:        
                x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                print('可转债数据更新至%s' % x2.tradeDate.max())
            else:
                print('可转债数据已经是最新的%s，无需更新' % tt_str)
            os.remove(sub_fn)
        except:
            print(sub_fn)
    
#指数估值信息   
data_id=25
if len(fns_data[data_id])>0:
    tn1 = 'yq_MktIdxdEvalGet'.lower()
    tt_str = get_inidata(tn1)
    info='指数估值信息'
    for sub_fn in fns_data[data_id]:
        try:        
            x = pd.read_csv(sub_fn,dtype={'ticker':str})        
            x2 = x.loc[x.tradeDate>tt_str]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn)
        except:
            print(sub_fn)

#ETF基金申赎清单成分券信息
sub_id = 26    
if len(fns_data[sub_id])>0:
    table_name = 'yq_FundETFConsGet'.lower()
    tt_str = get_inidata(table_name)
    info = 'ETF基金申赎清单成分券信息'
    for sub_fn in fns_data[sub_id]:
        try:
            x1 = pd.read_csv(sub_fn,header=0)        
            x2 = x1.loc[x1.tradeDate>tt_str]
            if not x2.empty:    
                x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                print('%s:%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,tt_str))
            os.remove(sub_fn) 
        except:
            print(sub_fn)

#ETF基金申赎清单基本信息
sub_id = 27    
data_check = True
if len(fns_data[sub_id])>0:
    table_name = 'yq_FundETFPRListGet'.lower()
    tt_str = get_inidata(table_name)
    for sub_fn in fns_data[sub_id]:
        try:
            x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})
            if data_check:            
                x2 = x1.loc[x1.tradeDate>tt_str]
                if not x2.empty:    
                    x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                    print('%s:%s' % (info,x2.tradeDate.max()))
                else:
                    print('%s已经是最新的%s，无需更新' % (info,tt_str))
            else:
                x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)  
                print('comlete: %s' % (sub_fn))
            os.remove(sub_fn)
        except:
            print(sub_fn)
#股票周行情
sub_id = 28
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn1 = 'yq_MktEquwAdjAfGet'.lower()
            if not x.empty:
                tt_str = x.endDate.min()    
                if z_check:
                    do_sql_order('delete from %s where endDate>="%s"' % (tn1,tt_str),db_name1)            
                x.rename(columns={'return':'weekreturn'},inplace=True)
                x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每周股票后复权数据更新至%s' % x.endDate.max())
            os.remove(sub_fn)
        except:
            print(sub_fn)
#指数周行情
sub_id = 29
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]: 
        try:
            tn1 = 'yq_MktIdxwGet'.lower()    
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)>0:            
                tt_str = x.endDate.min() 
                if z_check:
                    do_sql_order('delete from %s where endDate>="%s"' % (tn1,tt_str),db_name1)
                x.rename(columns={'return':'weekreturn'},inplace=True)
                x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每周指数后复权数据更新至%s' % x.endDate.max())
            os.remove(sub_fn)
        except:
            print(sub_fn)
#30 证券编码及基本上市信息 SecIDGet  
sub_id = 30
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'yq_SecIDGet'.lower()
            do_sql_order('truncate table %s' % (tn),db_name1)
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('证券编码及基本上市信息')
            os.remove(sub_fn) 
        except:
            print(sub_fn)

#31 停复牌数据库 SecHaltGet
sub_id = 31
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'yq_SecHaltGet'.lower()
            do_sql_order('truncate table %s' % (tn),db_name1)
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('停复牌数据库')
            os.remove(sub_fn) 
        except:
            print(sub_fn)

"""
"""
#32 ST标记 SecSTGet
####SSS1 需要检查
sub_id = 32
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'yq_SecSTGet'.lower()
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('ST标记')
            os.remove(sub_fn) 
        except:
            print(sub_fn)


#每日因子数据
sub_id = 33    
data_check = True
table_name = 'yq_MktStockFactorsOneDayGet'.lower()
#tt_str = get_inidata(table_name)
info = '每日因子更新'
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})     
            if len(x1)>0:           
                if data_check:
                    sub_t = x1.tradeDate.astype(str).unique()
                    for sub_sub_t in sub_t:
                        sql_temp = 'delete from %s where tradeDate = "%s"'
                        if z_check:
                            do_sql_order(sql_temp % (table_name,sub_sub_t),db_name1)
                    if not x1.empty:    
                        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                        print('%s:%s' % (info,x1.tradeDate.max()))
                    else:
                        print('%s已经是最新的%s，无需更新' % (info,tt_str))
                else:
                    x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)  
                    print('comlete: %s' % (sub_fn))
            os.remove(sub_fn) 
        except:
            print(sub_fn)

#信息数据
sub_id = 34    
data_check = True
if len(fns_data[sub_id])>0:
    table_name = 'yq_SocialDataGubaGet'.lower()
    tt_str = get_inidata(table_name,'statisticsDate')
    for sub_fn in fns_data[sub_id]:
        try:
            x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})
            if data_check:
                info = '贴吧信息数据'
                x2 = x1.loc[x1.statisticsDate>tt_str]
                if not x2.empty:    
                    x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                    print('%s:%s' % (info,x2.statisticsDate.max()))
                else:
                    print('%s已经是最新的%s，无需更新' % (info,tt_str))
            else:
                x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)  
                print('comlete: %s' % (sub_fn))
            os.remove(sub_fn)
        except:
            print(sub_fn)
#SSS1
#申万行业回填（含科创板）
sub_id = 35
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'yq_MdSwBackGet'.lower()
            do_sql_order('truncate table %s' % (tn),db_name1)
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('申万行业回填（含科创板）')
            os.remove(sub_fn)     
        except:
            print(sub_fn)

#SSS1        
#36
sub_id = 36
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'FundGet_S51'.lower()
            if len(x)>0:
                do_sql_order('truncate table %s' % (tn),db_name1)
                x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
                print('基金基本信息已经更新')
            os.remove(sub_fn) 
        except:
            print(sub_fn)

sub_id = 37
#'yq_FundAssetsGet_S51' in sub_fn:
if len(fns_data[sub_id])>0:
    info = '基金资产配置'
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'yq_FundAssetsGet_S51'.lower()
            if len(x)>0:
                x.drop_duplicates(subset=['ticker','reportDate','updateTime'], 
                                            keep='first', inplace=True)
                t0 = x.updateTime.astype(str).min()
                t2 = x.updateTime.astype(str).max()        
                sql_str = 'delete from %s where updateTime>="%s"' % (tn,t0)
                if z_check:
                    do_sql_order(sql_str,db_name1)            
                x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
                print('%s已经更新至%s' % (info,t2))
            os.remove(sub_fn) 
        except:
            print(sub_fn)
#FundNavGet_S51
sub_id = 38
if len(fns_data[sub_id])>0:
    info = '基金历史净值(货币型,短期理财债券型除外)'
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'FundNavGet_S51'.lower()
            if len(x)>0:
                t0 = x.endDate.astype(str).min()
                t2 = x.endDate.astype(str).max()        
                sql_str = 'delete from %s where endDate>="%s"' % (tn,t0)
                if z_check:
                    do_sql_order(sql_str,db_name1)            
                x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
                print('%s已经更新至%s' % (info,t2))
            os.remove(sub_fn)  
        except:
            print(sub_fn)
#每日专业因子数据
sub_id = 39    
data_check = True
table_name = 'yq_MktStockFactorsOneDayProGet'.lower()
info = '每日专业因子数据'
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        try:
            x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})     
            if len(x1)>0:           
                if data_check and z_check:
                    sub_t = x1.tradeDate.astype(str).unique()
                    for sub_sub_t in sub_t:
                        sql_temp = 'delete from %s where tradeDate = "%s"'
                        do_sql_order(sql_temp % (table_name,sub_sub_t),db_name1)
                    if not x1.empty:    
                        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
                        print('%s:%s' % (info,x1.tradeDate.max()))
                    else:
                        print('%s已经是最新的%s，无需更新' % (info,tt_str))
                else:
                    x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)  
                    print('comlete: %s' % (sub_fn))
            os.remove(sub_fn) 
        except:
            print(sub_fn)
        
        
sub_id = 40
if len(fns_data[sub_id])>0:
    info = 'CME期货日行情'
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str,'holdingTicker':str})
            tn = 'MktCmeFutdGet_S50'.lower()
            if len(x)>0:
                t0 = x.tradeDate.astype(str).min()
                t2 = x.tradeDate.astype(str).max()
                if z_check:
                    sql_str = 'delete from %s where tradeDate>="%s"' % (tn,t0)
                    do_sql_order(sql_str,db_name1)    
                x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
                print('%s已经更新至%s' % (info,t2))
            os.remove(sub_fn) 
        except:
            print(sub_fn)

sub_id = 41
# 'MktIborGet_adair' 银行间同业拆借利率
if len(fns_data[sub_id])>0:
    info = '银行间同业拆借利率'
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str,'holdingTicker':str})
            tn = 'MktIborGet_S53'.lower()
            if len(x)>0:
                t0 = x.tradeDate.astype(str).min()
                t2 = x.tradeDate.astype(str).max() 
                if z_check:
                    sql_str = 'delete from %s where tradeDate>="%s"' % (tn,t0)
                    do_sql_order(sql_str,db_name1)    
                x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
                print('%s已经更新至%s' % (info,t2))
            os.remove(sub_fn)
        except:
            print(sub_fn)

sub_id = 42
# EcoDataProGet 信用利差
if len(fns_data[sub_id])>0:
    info = '信用利差'
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'indicID':str})
            tn = 'EcoDataProGet_S53'.lower()
            if len(x)>0:
                indicID = x.indicID.unique()
                for sub_indicID in indicID:
                    t0 = x[x.indicID==sub_indicID].periodDate.astype(str).min()
                    t2 = x[x.indicID==sub_indicID].periodDate.astype(str).max()    
                    if z_check:
                        sql_str = 'delete from %s where indicID="%s" and periodDate>="%s"' % (tn,sub_indicID,t0)
                        do_sql_order(sql_str,db_name1)    
                    x[x.indicID==sub_indicID].to_sql(tn,engine,if_exists='append',
                                     index=False,chunksize=3000)
                    print('%s %s 已经更新至%s' % (info,sub_indicID,t2))
            os.remove(sub_fn) 
        except:
            print(sub_fn)

sub_id = 43
# 上市公司特殊状态变化
if len(fns_data[sub_id])>0:
    info = '上市公司特殊状态变化'
    for sub_fn in fns_data[sub_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            tn = 'EquInstSstateGet_S53'.lower()
            if len(x)>0:
                t0 = x.effDate.astype(str).min()
                t2 = x.effDate.astype(str).max()   
                if z_check:
                    sql_str = 'delete from %s where effDate>="%s"' % (tn,t0)
                    do_sql_order(sql_str,db_name1)    
                #x.fillna(-1,inplace=True)
                x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
                print('%s已经更新至%s' % (info,t2))
            os.remove(sub_fn)   
        except:
            print(sub_fn)

#每日 填充 行情
data_id=44
if len(fns_data[data_id])>0:
    tn1 = 'MktEqudGet0S53'.lower()
    t0 = get_inidata(tn1)        
    
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)==0:
                continue
            
            x2 = x.loc[x.tradeDate>str(t0)]
            if not x2.empty:
                x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每日 填充 行情数据更新至%s' % x2.tradeDate.max())
            else:
                print('每日 填充 行情数据已经是最新的%s，无需更新' % t0)
            os.remove(sub_fn)
        except:
            print(sub_fn)

#每日后复权 填充行情
data_id=45
if len(fns_data[data_id])>0:
    tn1 = 'MktEqudAdjAfGetF0S53'.lower()
    t0 = get_inidata(tn1) 
    
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)==0:
                continue
            x2 = x.loc[x.tradeDate>str(t0)]
            if not x2.empty:
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每日后复权 填充行情更新至%s' % x2.tradeDate.max())
            else:
                print('每日后复权 填充行情已经是最新的%s，无需更新' % t0)
            os.remove(sub_fn)
        except:
            print(sub_fn)

data_id=46
if len(fns_data[data_id])>0:
    tn1 = 'MktEqudAdjAfGetF1S53'.lower()
    t0 = get_inidata(tn1)
    
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)==0:
                continue
            x2 = x.loc[x.tradeDate>str(t0)]
            if not x2.empty:
                #x2.rename(columns={'ticker':'symbol'},inplace=True)
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('每日后复权 重下数据20200824 更新至%s' % x2.tradeDate.max())
            else:
                print('每日后复权 重下数据20200824 已经是最新的%s，无需更新' % t0)
            os.remove(sub_fn)
        except:
            print(sub_fn)

data_id=47
info = '个股日资金流向'
if len(fns_data[data_id])>0:
    tn1 = 'MktEquFlowGetS56'.lower()
    t0 = get_inidata(tn1)
    
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)==0:
                continue
            x2 = x.loc[x.tradeDate>str(t0)]
            if not x2.empty:
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s 更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s 已经是最新的%s，无需更新' % (info,t0))
            os.remove(sub_fn)
        except:
            print(sub_fn)

data_id=48
info = '沪深港通持股记录'
if len(fns_data[data_id])>0:
    tn1 = 'HKshszHoldGetS56'.lower()
    t0 = get_inidata(tn1,'endDate')
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str,'ticketCode':str})
            if len(x)==0:
                continue
            x2 = x.loc[x.endDate>str(t0)]
            if not x2.empty:
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s 更新至%s' % (info,x2.endDate.max()))
            else:
                print('%s 已经是最新的%s，无需更新' % (info,t0))
            os.remove(sub_fn)
        except:
            print(sub_fn)

data_id = 49
info = '沪深融资融券每日交易明细信息'
if len(fns_data[data_id])>0:
    tn1 = 'FstDetailGetS56'.lower()
    t0 = get_inidata(tn1)
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)==0:
                continue
            x2 = x.loc[x.tradeDate>str(t0)]
            if not x2.empty:
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s 更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s 已经是最新的%s，无需更新' % (info,t0))
            os.remove(sub_fn)
        except:
            print(sub_fn)
            
data_id=50
info ='获取一致预期个股营业收入表'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'secCode':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'ResConSecIncomeGetS18'.lower()
        t0=x.repForeTime.min()
        tt=x.repForeTime.max()
        sql_str1 = 'delete from %s where repForeTime>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)        


data_id=51
info ='一致预期数据表(申万行业)'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'secCode':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'ResConInduSwGet18'.lower()
        t0=x.repForeTime.min()
        tt=x.repForeTime.max()
        sql_str1 = 'delete from %s where repForeTime>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)   

#ResConSecDataGet18        
data_id=52
info ='获取一致预期个股数据表'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'secCode':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'ResConSecDataGet18'.lower()
        t0=x.repForeTime.min()
        tt=x.repForeTime.max()
        sql_str1 = 'delete from %s where repForeTime>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn) 

#ResConSecDerivativeGet18
data_id=53
info ='个股一致预期衍生数据表'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'secCode':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'ResConSecDerivativeGet18'.lower()
        t0=x.repForeTime.min()
        tt=x.repForeTime.max()
        sql_str1 = 'delete from %s where repForeTime>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn) 
#ResConTarpriScoreGet18
data_id=54
info ='获取一致预期目标价与评级表'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'secCode':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'ResConTarpriScoreGet18'.lower()
        t0=x.repForeTime.min()
        tt=x.repForeTime.max()
        sql_str1 = 'delete from %s where repForeTime>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn) 
#NewsSentiIndexGetS55FZ
data_id=55
info ='获取一致预期目标价与评级表'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'ticker':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'NewsSentiIndexGetS55FZ'.lower()
        t0=x.newsEffectiveDate.min()
        tt=x.newsEffectiveDate.max()
        sql_str1 = 'delete from %s where newsEffectiveDate>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn) 
        
data_id=56
info ='新闻热度指数（新版，不包括当天'
if len(fns_data[data_id])>0:
    x=[]
    for sub_fn in fns_data[data_id]:
        x.append(pd.read_csv(sub_fn,dtype={'ticker':str}))
    x=pd.concat(x)
    if len(x)>0:
        tn1 = 'NewsHeatIndexNewGetS55FZ'.lower()
        t0=x.newsEffectiveDate.min()
        tt=x.newsEffectiveDate.max()
        sql_str1 = 'delete from %s where newsEffectiveDate>="%s"' % (tn1,t0)
        do_sql_order(sql_str1,db_name1)
        x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s 更新至%s' % (info,tt))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
        
#1 EquRestructuringGet 重组数据
data_id = 57
info = '重组数据'
if len(fns_data[data_id])>0:
    x1 = []
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})  
        x1.append(x)
    x1 = pd.concat(x1)
    
    if len(x1)>0:
        table_name = 'EquRestructuringGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        y=x1[['secID','ticker','secShortName','exchangeCD','publishDate',
              'iniPublishDate','finPublishDate','program','isSucceed','restructuringType',
              'underlyingType','underlyingVal','expenseVal','isRelevance','isMajorRes','payType']]
        
        y.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#
data_id = 58    
info = '合并利润表'
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    if len(x1)>0:
        table_name = 'nincome'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#
data_id=59
info = '合并资产负债表'
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    #x1 = pd.read_csv(fns_data[data_id],header=0,engine='python',encoding = "utf-8",
    #                 dtype={'ticker':str})
    if len(x1)>0:
        table_name = 'yq_FdmtBSGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
    
data_id=60
info = '主营业务构成'
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    if len(x1)>0:
        table_name = 'yq_FdmtMainOperNGet_update'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
# 业绩快报 S49 净利润断层方法添加
data_id=61
info = '业绩快报'
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    if len(x1)>0:
        table_name = 'yq_FdmtEeGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
    
data_id = 62  
info = '财务衍生数据'  
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtDerPitGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#
data_id = 63  
info = '财务指标-运营能力'  
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
                 
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtIndiTrnovrPitGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
'''
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
'''    
data_id = 64 
info = '财务指标-每股'  
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtIndiPSPitGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#    
data_id = 65
info = '合并现金流量表 (Point in time)'  
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtCFGetAll'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#
data_id =66  
info = '财务指标—盈利能力'
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtIndiRtnPitGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#13合并利润表TTM FdmtISTTMPITGet
data_id = 67
info = '合并利润表TTM'  
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    if len(x1)>0:
        x1.rename(columns={'ticker':'symbol'},inplace=True)
        table_name = 'yq_FdmtISTTMPITGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#14 FdmtCFTTMPITGet  合并现金流量表（TTM Point in time）
data_id = 68
info = '合并现金流量表TTM'  
if len(fns_data[data_id])>0:
    x1 =[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    if len(x1)>0:
        table_name = 'yq_FdmtCFTTMPITGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)
#15 FdmtISQPITGet
#合并利润表（单季度 Point in time）
#转换思路，删除读取数据的最小日期，然后保留最新的数据即可
data_id = 69   
info = '合并利润表（单季度 Point in time）'
if len(fns_data[data_id])>0:
    x1=[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    table_name = 'yq_FdmtISQPITGet'.lower()
    if len(x1)>0:
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
    
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn) 

# 业绩预告 S49 净利润断层方法添加
data_id=70
info = '业绩预告'
if len(fns_data[data_id])>0:
    x1=[]
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,encoding = "utf-8",
                         dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    if len(x1)>0:
        table_name = 'yq_FdmtEfGet'.lower()
        t0 = x1.publishDate.astype(str).min()
        t2 = x1.publishDate.astype(str).max()
        sql_str = 'delete from %s where publishDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)   
    
#FundHoldingsGet_S51
data_id = 71
if len(fns_data[data_id])>0:
    info = '基金持仓明细'
    x=[]
    for sub_fn in fns_data[data_id]:
        x1 = pd.read_csv(sub_fn,dtype={'ticker':str,'holdingTicker':str})
        tn = 'FundHoldingsGet_S51'.lower()
        x.append(x1)
    x = pd.concat(x)
    
    if len(x)>0:
        t0 = x.reportDate.astype(str).min()
        t2 = x.reportDate.astype(str).max()        
        sql_str = 'delete from %s where reportDate>="%s"' % (tn,t0)
        do_sql_order(sql_str,db_name1)            
        x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
        print('%s已经更新至%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn)  
        
data_id = 72
info = '合并利润表（单季度，根据所有会计期末最新披露数据计算）'
if len(fns_data[data_id])>0:
    x1=[]    
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})
        x1.append(x)
    x1=pd.concat(x1)
    
    table_name = 'FdmtISQGetS53'.lower()
    if len(x1)>0:
        t0 = x1.endDate.astype(str).min()
        t2 = x1.endDate.astype(str).max()
    
        sql_str = 'delete from %s where endDate>="%s"' % (table_name,t0)
        do_sql_order(sql_str,db_name1)
        x1.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,t2))
    for sub_fn in fns_data[data_id]:
        os.remove(sub_fn) 

if not server_sel:
    # update S26辅助因子1
    tn1 = 'yq_MktStockFactorsOneDayGet_S26'
    tn2 = 'yq_MktStockFactorsOneDayGet'
    t0=get_ini_data(tn1,'tradeDate',eg26)
    tt = get_ini_data(tn2,'tradeDate')
    key_str = ','.join(['ticker', 'tradeDate', 'HBETA', 'RSTR24', 'MLEV', 'FEARNG', 'EGRO',
           'VOL20', 'VOL60', 'VOL240', 'Volatility', 'LCAP'])
    if tt>t0:
        sql_tmp = 'delete from %s where tradeDate = "%s"' % (tn1,t0)
        do_sql_order(sql_tmp,db26)
        sql_tmp = """INSERT INTO %s SELECT %s from 
        yuqerdata.%s where  tradeDate>='%s'""";
        sql_tmp = sql_tmp % (tn1,key_str,tn2,t0)
        do_sql_order(sql_tmp,db26)
    
    
    tn1= 'yq_MktStockFactorsOneDayGet_add_S26'   
    t0=get_ini_data(tn1,'tradeDate',eg26)
    key_str = ','.join(['ticker', 'tradeDate', 'GrossIncomeRatio',
     'OperCashInToCurrentLiability', 'InventoryTRate'])
    if tt>t0:
        sql_tmp = 'delete from %s where tradeDate = "%s"' % (tn1,t0)
        do_sql_order(sql_tmp,db26)
        sql_tmp = """INSERT INTO %s SELECT %s from 
        yuqerdata.%s where  tradeDate>='%s'""";
        sql_tmp = sql_tmp % (tn1,key_str,tn2,t0)
        do_sql_order(sql_tmp,db26)
        
    
    #专业因子替换1  
    tn2 = 'yq_MktStockFactorsOneDayProGet'
    for tn1 in ['DividendPS']:
        t0=get_ini_data(tn1,'tradingdate',eg_cub1)
        tt = get_ini_data(tn2,'tradeDate')
        key_str1 = ','.join(['symbol', 'tradingdate', 'f_val'])
        key_str2 = ','.join(['ticker as symbol','tradeDate as tradingdate','%s as f_val' % tn1])
        if tt>t0:
            sql_tmp = 'delete from %s where tradingdate = "%s"' % (tn1,t0)
            do_sql_order(sql_tmp,db_cub1)
            sql_tmp = """INSERT INTO %s(%s) SELECT %s from 
            yuqerdata.%s where  tradeDate>='%s'""";
            sql_tmp = sql_tmp % (tn1,key_str1,key_str2,tn2,t0)
            do_sql_order(sql_tmp,db_cub1)
            
    # 专业因子替换2
    #tn2 = 'yq_MktStockFactorsOneDayProGet'
    for tn1 in ['DAREC','DAREV','DASREV','EBITDA','EPIBS','ForwardPE',
                      'GREC','GREV','GSREV']:
        print('update S19 factor from pro %s' % tn1)
        t0=get_ini_data(tn1,'tradingdate',eg_fac)
        #tt = get_ini_data(tn2,'tradeDate')
        key_str1 = ','.join(['symbol', 'tradingdate', 'f_val'])
        key_str2 = ','.join(['ticker as symbol','tradeDate as tradingdate','%s as f_val' % tn1])
        if tt>t0:
            sql_tmp = 'delete from %s where tradingdate = "%s"' % (tn1,t0)
            do_sql_order(sql_tmp,db_fac)
            sql_tmp = """INSERT INTO %s(%s) SELECT %s from 
            yuqerdata.%s where  tradeDate>='%s'""";
            sql_tmp = sql_tmp % (tn1,key_str1,key_str2,tn2,t0)
            do_sql_order(sql_tmp,db_fac)
    
    tn1=' yq_s19factors'
    t0=get_ini_data(tn1,'tradeDate',engine)
    key_str = ','.join(['ticker', 'tradeDate', 'PS', 'PCF', 'NetProfitGrowRate',
         'GrossIncomeRatio', 'EquityToAsset', 'BLEV', 'CashToCurrentLiability',
         'CurrentRatio', 'Skewness'])
    if tt>t0:
        print('update S19 factor data2 from pro %s' % tn1)
        sql_tmp = 'delete from %s where tradeDate = "%s"' % (tn1,t0)
        do_sql_order(sql_tmp,db_name1)
        sql_tmp = """INSERT INTO %s(%s) SELECT %s from 
        yuqerdata.%s where  tradeDate>='%s'""";
        sql_tmp = sql_tmp % (tn1,key_str,key_str,tn2,t0)
        do_sql_order(sql_tmp,db_name1)
    
#每日后复权 填充行情
data_id=73
info = '港股日行情'
if len(fns_data[data_id])>0:
    tn1 = 'MktHKEqudGetS54'.lower()
    t0 = get_inidata(tn1) 
    #t0='1990-01-01'
    for sub_fn in fns_data[data_id]:
        try:
            x = pd.read_csv(sub_fn,dtype={'ticker':str})
            if len(x)==0:
                continue
            x2 = x.loc[x.tradeDate>str(t0)]
            if not x2.empty:
                x2.sort_values(by='updateTime',inplace=True)
                x2.drop_duplicates(subset=['tradeDate','secID'],inplace=True,keep='last')
                x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
                print('%s更新至%s' % (info,x2.tradeDate.max()))
            else:
                print('%s已经是最新的%s，无需更新' % (info,t0))
            os.remove(sub_fn)
        except:
            print(sub_fn)