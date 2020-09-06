# -*- coding: utf-8 -*-
"""
Created on Mon Apr 27 20:13:13 2020
结果最后需要写入数据库，便于matlab控制并行、统计曲线参数、可视化
改进的TD框架
单个指数运行时间需要1-2分钟，计算速度太慢
如何才能加快速度？
@author: Asus
@update adair
"""


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
import json
from datetime import date,datetime
import pymysql
import warnings
import sys

warnings.filterwarnings('ignore')

#must be set before using
with open('para.json','r',encoding='utf-8') as f:
    para = json.load(f)
    
pn = para['yuqerdata_dir']

user_name = para['mysql_para']['user_name']
pass_wd = para['mysql_para']['pass_wd']
port = para['mysql_para']['port']

db_name1 = 'yuqerdata'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name1)
engine = create_engine(eng_str)

db_name42 = 'S42'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name42)
engine42 = create_engine(eng_str)

db_name_us = 'us_stock'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name_us)
engine_us = create_engine(eng_str)

sql_str_select_data1 = '''select %s from yq_dayprice where symbol="%s" and tradeDate>="%s"
    and tradeDate<="%s" order by tradeDate'''
sql_str_select_data2 = '''select %s from MktEqudAdjAfGet where ticker="%s" and tradeDate>="%s"
    and tradeDate<="%s" order by tradeDate''' 
## 数据的起始与终止时间
def get_index_tradeDate(index,begin,end):
    sql_str_index = '''select * from yq_index where symbol = "%s" and tradeDate>="%s" and tradeDate<="%s" order by tradeDate'''
    sql_str_index = sql_str_index % (index,begin,end)
    hs300_index = pd.read_sql(sql_str_index,engine)
    hs300_index = hs300_index.sort_values('tradeDate')
    return hs300_index
def get_cf_future_tradeDate(index,begin='2000-01-01',end='2033-01-01'):
    sql_str_index = '''select contractObject as symbol,tradeDate,openPrice as openIndex,highestPrice as highestIndex,
    lowestPrice as lowestIndex,closePrice  as closeIndex,turnoverVol from yq_MktMFutdGet 
    where contractObject = "%s" and mainCon = 1 and tradeDate>="%s" and 
    tradeDate<="%s" order by tradeDate'''
    sql_str_index = sql_str_index % (index,begin,end)
    hs300_index = pd.read_sql(sql_str_index,engine)
    hs300_index = hs300_index.sort_values('tradeDate')
    return hs300_index

def get_a_stock_tradeDate(index,begin='2000-01-01',end='2033-01-01'):
    #每日数据
    sql_str_index = '''select symbol,tradeDate,openPrice as openIndex,highestPrice as highestIndex,
    lowestPrice as lowestIndex,closePrice  as closeIndex from yq_dayprice
    where symbol = "%s"  and tradeDate>="%s" and 
    tradeDate<="%s" order by tradeDate'''
    sql_str_index = sql_str_index % (index,begin,end)
    hs300_index = pd.read_sql(sql_str_index,engine)
    hs300_index = hs300_index.sort_values('tradeDate')
    
    #后复权系数 MktEqudAdjAfGet
    sql_str_fq = """select tradeDate,accumAdjFactor from MktEqudAdjAfGet where 
    ticker = "%s" order by tradeDate"""
    sql_str_fq = sql_str_fq % index
    y = pd.read_sql(sql_str_fq,engine)
    y=pd.merge(hs300_index,y,on=['tradeDate'])
    y['openIndex'] = y['openIndex']*y['accumAdjFactor']
    y['highestIndex'] = y['highestIndex']*y['accumAdjFactor']
    y['lowestIndex'] = y['lowestIndex']*y['accumAdjFactor']
    y['closeIndex'] = y['closeIndex']*y['accumAdjFactor']
    return y

def get_exchange_tradeDate(index,begin='2000-01-01',end='2033-01-01'):
    #每日数据
    sql_str_index = '''select symbol,tradingdate as tradeDate,openPrice as openIndex,highestPrice as highestIndex,
    lowestPrice as lowestIndex,closePrice  as closeIndex from exchange_dayly
    where symbol = "%s"  and tradingdate>="%s" and 
    tradingdate<="%s" order by tradingdate'''
    sql_str_index = sql_str_index % (index,begin,end)
    hs300_index = pd.read_sql(sql_str_index,engine42)
    hs300_index = hs300_index.sort_values('tradeDate')    
    return hs300_index
#dowjones data
def get_dowjones_tradeDate(index,begin='2000-01-01',end='2033-01-01'):
    #每日数据
    sql_str_index = '''select symbol,tradeDate,openPrice as openIndex,highestPrice as highestIndex,
    lowestPrice as lowestIndex,closePrice  as closeIndex from dowjones_dayly
    where symbol = "%s"  and tradeDate>="%s" and 
    tradeDate<="%s" order by tradeDate'''
    sql_str_index = sql_str_index % (index,begin,end)
    hs300_index = pd.read_sql(sql_str_index,engine42)
    hs300_index = hs300_index.sort_values('tradeDate')    
    return hs300_index

#美股后复权数据
def get_american_stock_tradeDate(index,begin='2000-01-01',end='2033-01-01'):
    #每日数据
    sql_str_index = '''select symbol,tradingdate as tradeDate,openprice_adj as openIndex,highprice_adj as highestIndex,
    lowprice_adj as lowestIndex,closeprice_adj  as closeIndex from us_stock_daytick
    where symbol = "%s"  and tradingdate>="%s" and 
    tradingdate<="%s" order by tradingdate'''
    sql_str_index = sql_str_index % (index,begin,end)
    hs300_index = pd.read_sql(sql_str_index,engine_us)
    return hs300_index
#获取成分股
def get_IdxCons(intoDate,ticker='000300'):
    #nearst 时间
    sql_str1 = '''select symbol from yuqerdata.IdxCloseWeightGet where ticker = "%s"
            and tradingdate = (select tradingdate from yuqerdata.IdxCloseWeightGet where 
        ticker="%s" and tradingdate<="%s"  order by tradingdate desc limit 1)''' %(ticker,
        ticker,intoDate)
    x = pd.read_sql(sql_str1,engine)
    x = x['symbol'].values   
    return x

#日线数据
def chs_factor(ticker = '000005',begin = None ,end = None , 
               field = [u'symbol',  u'tradeDate', u'openPrice',
                        u'highestPrice', u'lowestPrice', u'closePrice', u'turnoverVol',
                        u'turnoverValue',u'dealAmount', u'chgPct',
                        'turnoverRate',u'marketValue',u'accumAdjFactor']):
    sql_str1 = sql_str_select_data1 % (','.join(field),ticker,begin,end)
    dataday = pd.read_sql(sql_str1,engine)
    dataday = dataday.applymap(lambda x: np.nan if x == 0 else x)
    dataday.rename(columns={'symbol':'ticker'},inplace=True)
    ## 对数据补全
    return dataday.fillna(method = 'ffill')


## 得交易日历
def get_calender_range(begin, end):
    sql_str = """select tradeDate from yuqerdata.yq_index where symbol = "000001" 
    and tradeDate >="%s" and tradeDate <="%s" order by tradeDate""" % (begin, end)
    x=pd.read_sql(sql_str,engine)
    x=x['tradeDate'].values
    #b=[i.strftime('%Y-%m-%d') for i in x]
    return x

#获取所有交易日历
def get_calender():
    sql_str = '''select tradeDate from yuqerdata.yq_index where symbol = "000001" order by tradeDate'''
    x=pd.read_sql(sql_str,engine)
    x=x['tradeDate'].values
    #b=[i.strftime('%Y-%m-%d') for i in x]
    return x
#获取月度日历    
def get_month_calender(begin = '2000-01-01'):
    sql_str = '''select endDate from yuqerdata.yq_index_month where symbol = "000001" and endDate>="%s" order by endDate''' % (begin)
    x=pd.read_sql(sql_str,engine)
    x=x['endDate'].values
    #b=[i.strftime('%Y-%m-%d') for i in x]
    return x
#经典TD幅度膨胀指标计算
def cal_tdrei(df,k,m,p):
    df = df.copy()
    df = df.sort_values('tradeDate')
    df['h_k'] = df['highestIndex'].shift(1).rolling(k).max()
    df['l_k'] = df['lowestIndex'].shift(1).rolling(k).min()
    df['h_m'] = df['highestIndex'].shift(1).rolling(m).max()
    df['l_m'] = df['lowestIndex'].shift(1).rolling(m).min()
    df['h_p'] = df['highestIndex'].shift(1).rolling(p).max()
    df['l_p'] = df['lowestIndex'].shift(1).rolling(p).min()
    
    def cal_X(hi,hk,li,lk,lm,hm):
        if hi>=lm and li<=hm:
            X = (hi - hk) + (li - lk)
        else:
            X = 0
        return X    
    df['X'] = df.apply(lambda x: cal_X(x['highestIndex'],x['h_k'],x['lowestIndex'],x['l_k'],x['l_m'],x['h_m']),axis=1)
    #df['x_rollingsum'] = pd.rolling_sum(df['X'], p+1) 
    df['x_rollingsum'] = df['X'].rolling(p+1).sum() 
    df['TDREI'] = (df['x_rollingsum'] / (df['h_p'] - df['l_p'])) * 100
    return df

#计算截至当前日期指标连续超过阈值或连续低于负的阈值的天数
def s_num(s):
    if s[0] ==0:
        s1 = [0]
    else:
        s1 = [1]
    for i in range(1, len(s)):
        if s[i]==0:
            s1.append(0)
        elif s[i] == s[i-1]:
            s1.append(s1[i-1]+1)
        else:
            s1.append(1)
    return s1

#计算截至当前日期连续上涨的天数
def rise_num(s1,s2):
    r_num = []
    for i in range(len(s1)):
        if s1[i] > 1:
            r_num.append(sum(s2[(i-s1[i]+1):(i+1)]))
        else:
            r_num.append(np.nan)
    return r_num    

#标记下单的日期
def get_order_day(s):
    r=[True]
    for i in range(1,len(s)):
        if s[i]==s[i-1]:
            r.append(False)
        else:
            r.append(True)
    if s[-1]==0  or s[-1]==s[-2]:
        r[-1] = True
    return r 

#经典TD膨胀度指标的交易策略
def classic_tdrei(df, k=6, m=2, theta=40):
    df['theta'] = df['TDREI'].apply(lambda x: 1 if x>=theta else -1 if x<-theta else 0)
    df['con_num'] = s_num(df['theta'].tolist())
    df['rise_down'] = df['CHGPct'].apply(lambda x: 0 if x<0 else 1)
    df['rise_num']  = rise_num(df['con_num'].tolist(),df['rise_down'].tolist())    
    df['down_num'] = df['con_num'] - df['rise_num']

    df['h_k'] = df['highestIndex'].rolling(k).max()
    df['l_k'] = df['lowestIndex'].rolling(k).min()
    df['h_k1'] = df['highestIndex'].shift(1).rolling(k).max()
    df['l_k1'] = df['lowestIndex'].shift(1).rolling(k).min()
    
    df['nxt_can'] = df.apply(lambda x: 1 if x['openIndex']>=x['l_k1'] and x['closeIndex']<=x['openIndex'] and x['lowestIndex']<=x['l_k1'] and x['theta']==1 else -1 if x['openIndex']<=x['h_k1'] and x['closeIndex']>=x['openIndex'] and x['highestIndex']>=x['h_k1'] and x['theta']==-1 else 0,axis=1)
    df['pre_can'] = df.apply(lambda x: 1 if x['con_num']>=2 and x['rise_num']>=1 and x['theta']==1 else -1 if x['con_num']>=2 and x['down_num']>=1 and x['theta']==-1 else 0,axis=1)
    df['pre_can'] = df['pre_can'].shift(1)    
    df['order'] = df.apply(lambda x: -1 if x['pre_can']==1 and x['nxt_can']==1 else 1 if x['pre_can']==-1 and x['nxt_can']==-1 else 0,axis=1 )    
    df1 = df[df['order'].isin([-1,1])]
    df1 = df1.append(df.iloc[-1,:])
    df1 = df1.drop_duplicates()    
    df1['order_day'] = get_order_day(df1['order'].tolist())    
    df2 = df1[df1['order_day']==True][['symbol','tradeDate','closeIndex','order']]        
    return df2    

#计算策略的表现情况
def eva_strategy(df,cost=0.001, strategy_type='ls'):
    df = df.copy()
    df = df.sort_values('tradeDate')
    df['rtn'] = df['closeIndex'].pct_change()
    df['order1'] = df['order'].shift(1)
    df['rtn1'] = df['order1'] * df['rtn']    
    df['rtn1'] = df['rtn1'].fillna(0)
    if strategy_type=='lo':
        df = df[df['order1']==1]       
    if len(df) ==0:
        return pd.Series([])
    #不是每天交易，为什么每天都要减去手续费？是日内交易吗？
    df['rtn1'] = df['rtn1'] - cost    
    df['net_value'] = (df['rtn1'] + 1).cumprod()    
    df['tradeDate'] = pd.to_datetime(df['tradeDate'])
    df['tradeDate1'] = df['tradeDate'].shift(1)
    df['day_range'] =  (df['tradeDate'] - df['tradeDate1']).dt.days    
    x1 = df['day_range'].mean()
    x2 =len(df['day_range']) * 2
    x3 =df['net_value'].values[-1] / df['net_value'].values[0] -1
    all_days = (df['tradeDate'].values[-1] - df['tradeDate'].values[0]).astype('timedelta64[D]') / np.timedelta64(1, 'D')
    x4 = (df['net_value'].values[-1] / df['net_value'].values[0])**(250/all_days) -1 
    x5 =df['rtn1'].mean()
    x6 =sum(df['rtn1']>0) / float(len(df['rtn1']))
    x7 =df[df['rtn1']>=0]['rtn1'].mean()
    x8 = df[df['rtn1']<0]['rtn1'].mean()
    x9 =abs(df[df['rtn1']>=0]['rtn1'].mean() / df[df['rtn1']<0]['rtn1'].mean())
    x10 =len(df[df['rtn1']>=0]) * 2
    x11 =len(df[df['rtn1']<0]) * 2
    x12 =df[df['rtn1']>=0]['rtn1'].max()
    x13 =df[df['rtn1']<0]['rtn1'].min()
    index_name = ["平均交易周期","交易次数", "累积收益率" ,"年化收益率", 
                            "单次平均收益率" ,"判断正确率" ,"平均盈利率", "平均亏损率", 
                            "盈亏比", "正确次数" ,"错误次数", "单次最大盈利" ,"单次最大亏损"]
    return pd.Series([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13],
                     index=index_name),df

# 改进的TD膨胀度交易策略
def Modify_TD(df,theta):
    df = df.copy()
    df['order'] = df['TDREI'].apply(lambda x: 1 if x>=theta else -1 if x<=-theta else 0)
    df1 = df[df['order'].isin([-1,1])]
    df1 = df1.append(df.iloc[-1,:])
    df1 = df1.drop_duplicates()
    df1['order_day'] = get_order_day(df1['order'].tolist())
    df1 = df1[df1['order_day']==True][['symbol','tradeDate','closeIndex','order','TDREI']]
    return df1

def plot_net_value(d1,d2,index_df,split_date='2013-01-01',strategy_type='ls',begin_date='2005-01-01',end_date='2010-01-01',cost=0.001):
    d1['rtn'] = d1['closeIndex'].pct_change()
    d1['order1'] = d1['order'].shift(1)
    d1['rtn1'] = d1['order1'] * d1['rtn']
    d1['rtn1'] = d1['rtn1'].fillna(0)
    if strategy_type=='lo':
        d1 = d1[d1['order1']==1]   
    d1['rtn1'] = d1['rtn1'] - cost
    d1['net_value'] = (d1['rtn1'] + 1).cumprod()
    d2['rtn'] = d2['closeIndex'].pct_change()
    d2['order1'] = d2['order'].shift(1)
    d2['rtn1'] = d2['order1'] * d2['rtn']
    d2['rtn1'] = d2['rtn1'].fillna(0)
    if strategy_type=='lo':
        d2 = d2[d2['order1']==1]   
    d2['rtn1'] = d2['rtn1'] - cost
    d2['net_value'] = (d2['rtn1'] + 1).cumprod()
    d2['net_value1'] = d2['net_value'] * d1['net_value'].values[-1]
    d1['net_value1'] = d1['net_value']
    d = d1.append(d2)
    d.set_index('tradeDate',inplace=True)
    #date_range = get_calender_range(begin_date, end_date)
    #d = d.reindex(date_range)
    d=d.reindex(index_df['tradeDate'].values)
    d['net_value1'] = d['net_value1'].fillna(method='pad')
    #print(d.shape)
    #print(index_df.shape)
    #d.to_csv('temp1.csv')
    #index_df.to_csv('temp2.csv')
    d['closeIndex1'] = index_df[index_df['tradeDate'].isin(d.index)]['closeIndex'].values
    d.index = pd.to_datetime(d.index )
    p1 =  d[d.index<=pd.to_datetime(split_date)]
    p2 =  d[d.index>pd.to_datetime(split_date)] 
    """
    fig = plt.figure(figsize=(18, 9))
    ax1 = fig.add_subplot(111)
    ax1.plot(p1.index, p1['net_value1'],color='b')
    ax1.set_ylabel('Net Value')
    ax1.set_title("Net Value Curve and Stock Index")
    ax1.plot(p2.index, p2['net_value1'],color='r')
    ax2 = ax1.twinx()  # this is the important function
    ax2.plot(d.index, d['closeIndex1'], 'g')
    ax2.set_ylabel('Stock Index')
    ax2.set_xlabel('DATE')
    blue_line = mlines.Line2D([], [], color='b', label="net value curve in sample")
    red_line = mlines.Line2D([], [], color='r', label="net value curve out sample")
    green_line = mlines.Line2D([], [], color='g', label="Stock Index")
    plt.legend(handles=[blue_line, red_line,green_line], loc='upper left', fontsize=10)
    plt.show()
    """
    p1=p1['net_value1']
    p1.dropna(inplace=True)
    p1 = p1.to_frame()
    p1['chg'] = p1['net_value1'].pct_change()
    p1.fillna(value=0,inplace=True)
    
    p2=p2['net_value1']
    p2.dropna(inplace=True)
    p2 = p2.to_frame()
    p2['chg'] = p2['net_value1'].pct_change()
    p2.fillna(value=0,inplace=True)
    return p1,p2,d

#获取最优参数
def get_td_para_grid(train_data,strategy_type,cost=0.001):
    m_list,k_list ,p_list = [range(1,6)] * 3
    theta_list = range(100,200,25)
    r1 = -100
    for k in k_list:
        for m in m_list:
            for p in p_list:
                for theta in theta_list:                
                    df1 = cal_tdrei(train_data,k=k,m=m,p=p)
                    df1 = df1.dropna()
                    d1 =  Modify_TD(df1,theta)                   
                    s1,_ = eva_strategy(d1,cost=cost, strategy_type=strategy_type)                       
                    if s1['判断正确率'] > r1:
                        r1 = s1['判断正确率']   
                        target_k1 = k
                        target_m1 = m
                        target_p1 = p
                        target_theta1 = theta
                        d1['k'] = target_k1
                        d1['p'] = target_p1
                        d1['m'] = target_m1
                        d1['theta'] = target_theta1
                        d1['type'] = 'train'
                        d1['opt_type']='判断正确率'
                        train_target_perf1 = s1
                        target_train1 = d1.copy()

    return target_k1,target_m1,target_p1,target_theta1,train_target_perf1,target_train1

def ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost=0.001):
    train_data =  hs300_index[hs300_index['tradeDate']<=split_date]
    test_data = hs300_index[hs300_index['tradeDate']> split_date]    
    
    if run_mod == 'm':
        target_k1,target_m1,target_p1,target_theta1,train_target_perf1,target_train1 = get_td_para_grid(train_data,strategy_type,cost)
    else:
        target_k1,target_m1,target_p1,target_theta1 = [1,5,3,175]
        df1 = cal_tdrei(train_data,k=target_k1,m=target_m1,p=target_p1)
        df1 = df1.dropna()
        d1 =  Modify_TD(df1,target_theta1)                   
        s1,_ = eva_strategy(d1,cost=cost, strategy_type=strategy_type)   
        train_target_perf1 = s1
        target_train1 = d1.copy()
    
    #策略执行
    target_test1 = cal_tdrei(test_data,k=target_k1,m=target_m1,p=target_p1)
    target_test1 = target_test1.dropna()
    target_test1 =  Modify_TD(target_test1,target_theta1)
    target_test1['k'] = target_k1
    target_test1['p']=  target_p1
    target_test1['m']= target_m1
    target_test1['theta'] = target_theta1
    target_test1['type'] = 'test'
    target_test1['opt_type']='判断正确率'
    #策略评估
    test_target_perf1,y_c = eva_strategy(target_test1,cost=cost, strategy_type=strategy_type) 
    perf_df = pd.DataFrame([train_target_perf1,test_target_perf1]).T
    perf_df.columns= ['Train(判断正确率)','Test(判断正确率)']
    
    p1,p2,d1 = plot_net_value(target_train1,target_test1,hs300_index,split_date=split_date.strftime('%Y-%m-%d'),
                   strategy_type=strategy_type,begin_date=begin,end_date=end,cost=cost)
    return p1,p2

def create_table(db_name,tn_name,var_name,var_type,key_str):
    #连接本地数据库
    db = pymysql.connect("localhost",user_name,pass_wd,db_name)

    #创建游标
    cursor = db.cursor()

    #创建
    var_info=''
    for id,sub_var in enumerate(var_name):
        var_info=var_info + sub_var + ' ' + var_type[id] + ','
    var_info = var_info[:-1]    
    sql = 'create table  `%s`(%s,primary key(%s))' % (tn_name,var_info,key_str)
    
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

#S42改进TD模型 多空
def TD_S42_ls(index,run_mod='m',method_sel='index_test_S42'):
    print(method_sel)
    begin = '20050101'
    end = "20300101"
    split_date = date(2013,1,1)
    strategy_type = 'ls'  #'ls' 'lo' 
    if method_sel == 'index':
        tn ='S42_index'
        hs300_index = get_index_tradeDate(index,begin,end)
        cost = 0.5/10000
    elif method_sel == 'exchange':
        tn ='S42_exchange'
        cost = 0.5/10000
        hs300_index = get_exchange_tradeDate(index,begin,end)
    print ("%s begin ......"%index)
    m,_ = hs300_index.shape
    #print(m)
    if m > 245*10:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        #begin = date(end.year-10,1,1)
        split_date = date(begin.year+5,1,1) 
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        p1,p2 = ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost=cost)
        #plt.figure(figsize=(18, 9))
        #plt.plot((p2.chg+1).cumprod())
        p1['g_num'] = 0
        p2['g_num'] = 1
        p3 = p1.append(p2)
        p3['symbol'] = index
        p3.reset_index(inplace=True)
        p3['c_m'] = run_mod
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []


        
def index_test_S42(index,run_mod='m',method_sel='index_test_S42'):
    print(method_sel)
    tn ='S42_index'
    begin = '20050101'
    end = "20300101"
    split_date = date(2013,1,1)
    strategy_type = 'ls'  #'ls' 'lo'
    print ("%s begin ......"%index)
    hs300_index = get_index_tradeDate(index,begin,end)
    m,_ = hs300_index.shape
    #print(m)
    if m > 245*10:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        #begin = date(end.year-10,1,1)
        split_date = date(begin.year+5,1,1) 
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        p1,p2 = ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost=5/100000)
        #plt.figure(figsize=(18, 9))
        #plt.plot((p2.chg+1).cumprod())
        p1['g_num'] = 0
        p2['g_num'] = 1
        p3 = p1.append(p2)
        p3['symbol'] = index
        p3.reset_index(inplace=True)
        p3['c_m'] = run_mod
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []

def cf_future_test_S42(index,run_mod='m',method_sel = 'cf_future_test_S42'):
    print(method_sel)
    tn ='S42_cf_future'
    cost = 5/100000
    begin = '20050101'
    end = "20300101"
    split_date = date(2013,1,1)
    strategy_type = 'ls'  #'ls' 'lo'
    print ("%s begin ......"%index)
    hs300_index = get_cf_future_tradeDate(index,begin,end)
    m,_ = hs300_index.shape
    #print(m)
    if m > 245*6:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        #begin = date(end.year-10,1,1)
        split_date = date(begin.year+3,1,1) 
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        p1,p2 = ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost)
        #plt.figure(figsize=(18, 9))
        #plt.plot((p2.chg+1).cumprod())
        p1['g_num'] = 0
        p2['g_num'] = 1
        p3 = p1.append(p2)
        p3['symbol'] = index
        p3.reset_index(inplace=True)
        p3['c_m'] = run_mod
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []

#后复权数据
def a_stock_test_S42(index,run_mod='m',method_sel ='a_stock_test_S42'):
    print(method_sel)
    tn ='S42_a_stock'
    cost = 1.5/1000
    begin = '20050101'
    end = "20300101"
    split_date = date(2013,1,1)
    strategy_type = 'lo'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    print ("%s begin ......"%index)
    hs300_index = get_a_stock_tradeDate(index,begin,end)
    m,_ = hs300_index.shape
    print(m)
    if m > 245*10:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        #begin = date(end.year-10,1,1)
        split_date = date(begin.year+5,1,1) 
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        p1,p2 = ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost)
        plt.figure(figsize=(18, 9))
        plt.plot((p2.chg+1).cumprod())
        p1['g_num'] = 0
        p2['g_num'] = 1
        p3 = p1.append(p2)
        p3['symbol'] = index
        p3.reset_index(inplace=True)
        p3['c_m'] = run_mod
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []

#后复权数据 a股多空计算
def a_stock_test_S42_ef(index,run_mod='m',method_sel='a_stock_test_S42_ef'):
    print(method_sel)
    tn ='S42_a_stock_ef'
    cost = 1.5/1000
    begin = '20050101'
    end = "20300101"
    split_date = date(2013,1,1)
    strategy_type = 'ls'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    print ("%s begin ......"%index)
    hs300_index = get_a_stock_tradeDate(index,begin,end)
    m,_ = hs300_index.shape
    print(m)
    if m > 245*10:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        #begin = date(end.year-10,1,1)
        split_date = date(begin.year+5,1,1) 
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        p1,p2 = ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost)
        plt.figure(figsize=(18, 9))
        plt.plot((p2.chg+1).cumprod())
        p1['g_num'] = 0
        p2['g_num'] = 1
        p3 = p1.append(p2)
        p3['symbol'] = index
        p3.reset_index(inplace=True)
        p3['c_m'] = run_mod
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []

#经典框架
#美股按照老框架运行
def S42_classic_ls(index,run_mod='f',method_sel='american_stock_S42_classic'):
    print(method_sel)
    begin = '20050101'
    end = "20300101"
        
    if method_sel=='american_stock_classic':
        tn ='S42_american_stock_classic'
        cost = 0.5/10000
        hs300_index = get_american_stock_tradeDate(index,begin,end)
        strategy_type = 'ls'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    elif method_sel == 'exchange_classic':
        tn ='S42_exchange'
        cost = 0.5/10000        
        hs300_index = get_exchange_tradeDate(index,begin,end)
        strategy_type = 'ls'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    elif method_sel == 'dowjones_classic':
        tn ='S42_dowjones'
        cost = 0.5/10000        
        hs300_index = get_dowjones_tradeDate(index,begin,end)
        strategy_type = 'ls'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    elif method_sel == 'dowjones_classic_lo':
        tn ='S42_dowjones_lo'
        cost = 0.5/10000        
        hs300_index = get_dowjones_tradeDate(index,begin,end)
        strategy_type = 'lo'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    
    
    print ("%s begin ......"%index)
    
    m,_ = hs300_index.shape
    print(m)
    if m > 245*5:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        hs300_index.index = hs300_index['tradeDate'].values
        #print(hs300_index)
        hs300_tdrei = cal_tdrei(hs300_index,6,2,5)
        hs300_tdrei = hs300_tdrei.dropna()
        hs300_tdrei['CHGPct'] = hs300_tdrei['closeIndex'].pct_change()
        hs300_tdrei['CHGPct'].fillna(0,inplace=True)
        hs300_tdrei = hs300_tdrei[["symbol","tradeDate","TDREI","openIndex",'highestIndex','closeIndex','lowestIndex','CHGPct']]
        
        hs300_tdrei_strategy_df =classic_tdrei(hs300_tdrei)
        hs300_tdrei_ls_perf_df,p2 = eva_strategy(hs300_tdrei_strategy_df,cost=cost, strategy_type=strategy_type)
        hs300_tdrei_ls_perf_df.to_frame().rename(columns={0:'value'})
        
        p2=p2.reindex(hs300_tdrei['tradeDate'].values)
        p2['net_value1'] = p2['net_value'].fillna(method='pad')
        p2['chg'] = p2['net_value1'].pct_change()
        p2.fillna(value=0,inplace=True)
        p2['net_value1'] = (p2['chg']+1).cumprod()
        plt.plot(p2['net_value1'])
        #plt.figure(figsize=(18, 9))
        #plt.plot((p2.chg+1).cumprod())
        p2['g_num'] = 1
        p3 = p2
        p3['symbol'] = index
        p3['c_m'] = run_mod
        p3['tradeDate']= p3.index
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        if len(p3)>0:
            #p3['tradeDate'] = p3['tradeDate'].astype(str)
            p3['tradeDate'] = pd.to_datetime(p3['tradeDate'])
            p3.index=range(len(p3))
            p3=p3[['tradeDate', 'net_value1', 'chg', 'g_num', 'symbol', 'c_m']]
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []    
    
#美股按照老框架运行
def american_stock_S42_classic(index,run_mod='f',method_sel='american_stock_S42_classic'):
    print(method_sel)
    tn ='S42_american_stock_classic'
    cost = 0.5/10000
    begin = '20050101'
    end = "20300101"
    strategy_type = 'ls'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    print ("%s begin ......"%index)
    hs300_index = get_american_stock_tradeDate(index,begin,end)
    m,_ = hs300_index.shape
    print(m)
    if m > 245*5:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        hs300_index.index = hs300_index['tradeDate'].values
        #print(hs300_index)
        hs300_tdrei = cal_tdrei(hs300_index,6,2,5)
        hs300_tdrei = hs300_tdrei.dropna()
        hs300_tdrei['CHGPct'] = hs300_tdrei['closeIndex'].pct_change()
        hs300_tdrei['CHGPct'].fillna(0,inplace=True)
        hs300_tdrei = hs300_tdrei[["symbol","tradeDate","TDREI","openIndex",'highestIndex','closeIndex','lowestIndex','CHGPct']]
        
        hs300_tdrei_strategy_df =classic_tdrei(hs300_tdrei)
        hs300_tdrei_ls_perf_df,p2 = eva_strategy(hs300_tdrei_strategy_df,cost=cost, strategy_type=strategy_type)
        hs300_tdrei_ls_perf_df.to_frame().rename(columns={0:'value'})
        
        p2=p2.reindex(hs300_tdrei['tradeDate'].values)
        p2['net_value1'] = p2['net_value'].fillna(method='pad')
        p2['chg'] = p2['net_value1'].pct_change()
        p2.fillna(value=0,inplace=True)
        p2['net_value1'] = (p2['chg']+1).cumprod()
        plt.plot(p2['net_value1'])
        #plt.figure(figsize=(18, 9))
        #plt.plot((p2.chg+1).cumprod())
        p2['g_num'] = 1
        p3 = p2
        p3['symbol'] = index
        p3['c_m'] = run_mod
        p3['tradeDate']= p3.index
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        if len(p3)>0:
            #p3['tradeDate'] = p3['tradeDate'].astype(str)
            p3['tradeDate'] = pd.to_datetime(p3['tradeDate'])
            p3.index=range(len(p3))
            p3=p3[['tradeDate', 'net_value1', 'chg', 'g_num', 'symbol', 'c_m']]
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []        
#美股按照新框架运行暂时未修改
def american_stock_S42(index,run_mod='f',method_sel='american_stock_S42'):
    print(method_sel)
    tn ='S42_american_stock'
    cost = 0.5/10000
    begin = '20050101'
    end = "20300101"
    split_date = date(2013,1,1)
    strategy_type = 'ls'  #'ls' 'lo' #ls 多空模式 lo只 多模式
    print ("%s begin ......"%index)
    hs300_index = get_american_stock_tradeDate(index,begin,end)
    m,_ = hs300_index.shape
    print(m)
    if m > 245*10:
        begin = hs300_index.tradeDate.min()
        end = hs300_index.tradeDate.max()
        #begin = date(end.year-10,1,1)
        split_date = date(begin.year+5,1,1) 
        hs300_index = hs300_index[hs300_index.tradeDate>=begin]
        begin = begin.strftime('%Y-%m-%d')
        end = end.strftime('%Y-%m-%d')    
        
        p1,p2 = ef_test_S42(hs300_index,split_date,strategy_type,run_mod,begin,end,cost)
        #plt.figure(figsize=(18, 9))
        #plt.plot((p2.chg+1).cumprod())
        p1['g_num'] = 0
        p2['g_num'] = 1
        p3 = p1.append(p2)
        p3['symbol'] = index
        p3.reset_index(inplace=True)
        p3['c_m'] = run_mod
        #write to table  
        sub_sql_str = 'select tradeDate from %s where symbol = "%s" and c_m = "%s" order by tradeDate desc limit 1'
        t0 = pd.read_sql(sub_sql_str % (tn,index,run_mod),engine42)
        if len(t0)>0:
            t0=t0.tradeDate[0]
        else:
            t0=date(2000,1,1)
        p3 = p3[p3.tradeDate>t0]    
        p3.to_sql(tn,engine42,if_exists='append',index=False,chunksize=3000)
        return p3
    else:
        return []
    
#matlab 带入时候，记得不要加符号
#ex M_TD_update1 000001 f
if __name__ == '__main__':    
    if len(sys.argv)>1:
        index = sys.argv[1]
        if len(sys.argv) >= 3:
            run_mod = sys.argv[2]
        else:
            run_mod = 'f'
        if len(sys.argv) >= 4:
            method_sel = sys.argv[3]
        else:
            method_sel = 'index'
    else:
        index = 'hpq'
        run_mod = 'f'
        method_sel = 'dowjones_classic'
    print('%s-%s' % (index,run_mod))    
    t_start = datetime.now()
    
    if method_sel=='index':
        #指数
        p3 = index_test_S42(index,run_mod)
    elif method_sel == 'cf_future':
        #期货
        p3 = cf_future_test_S42(index,run_mod)    
    elif method_sel == 'a_stock':
        #股票
        p3 = a_stock_test_S42(index,run_mod)        
    elif method_sel == 'american_stock':
        #美股
        p3 = american_stock_S42(index,run_mod)
    elif method_sel == 'american_stock_classic':
        #美股经典框架
        p3 = american_stock_S42_classic(index,run_mod)
    elif method_sel =='a_stock_test_S42_ef':
        #a股多空
        p3 = a_stock_test_S42_ef(index,run_mod)   
    elif method_sel =='exchange_classic':
        #外汇 经典TD
        p3 = S42_classic_ls(index,run_mod,method_sel)   
    elif method_sel =='exchange':
        #外汇 优化参数结果
        p3 = TD_S42_ls(index,run_mod,method_sel)   
    elif method_sel =='dowjones_classic':
        p3 = S42_classic_ls(index,run_mod,method_sel)
    elif method_sel =='dowjones_classic_lo':
        p3 = S42_classic_ls(index,run_mod,method_sel)
    t_end = datetime.now()
    print(t_end-t_start)