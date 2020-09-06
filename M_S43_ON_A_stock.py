# coding: utf-8
#指数成分股计算，然后加权
#双底策略
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
#import statsmodels.api as sm
#import math
from yq_tools import chg_factor as chs_factor #载入日线数据
#from yq_tools import get_IdxCons as IdxConsGet #载入成分股数据
from yq_tools import get_index_tradeDate as MktIdxdGet #载入指数数据
from yq_tools import get_symbol_A
from yq_tools import create_table_update
from datetime import datetime

from sqlalchemy import create_engine
import json
#must be set before using
with open('para.json','r',encoding='utf-8') as f:
    para = json.load(f)
    
pn = para['yuqerdata_dir']

user_name = para['mysql_para']['user_name']
pass_wd = para['mysql_para']['pass_wd']
port = para['mysql_para']['port']
##股票选取
db_name37 = 'S37'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name37)
engine37 = create_engine(eng_str)


def get_points(n, index_down, index_up, s_ori ,back_w = 1):
    #print('s_ori',s_ori)
    qsdu_e = index_up[n]
    point_b, point_d = index_down[n - 3 :n - 1]
    point_a, point_c = index_up[n - 3 :n - 1]
    point_a, point_c = s_ori.loc[point_a -back_w - 1 : point_a + back_w].argmax(), s_ori.loc[point_c -back_w - 1: point_c + back_w].argmax() 
    point_b, point_d = s_ori.loc[point_b -back_w - 1: point_b + back_w].argmin(), s_ori.loc[point_d -back_w - 1: point_d + back_w].argmin()
    qsdu_e = s_ori.loc[qsdu_e - back_w - 1: qsdu_e + back_w].argmax()
    #pre_a = index_down[n - 4]
    return point_a, point_b, point_c, point_d, qsdu_e


#加上前期30%的这个条件，找不到信号
def is_bottom(a, b, c, d, e, s_ori, s_high, s_vol):
    ## 前期30% 涨幅
    ## 给定一个时间，在时间内与最低点差30%即可
    #pre_day = a - 200
    #r_pre = s_ori[a] / s_ori[pre_day: a].min() - 1
    #cond1 = r_pre > 0.3  ## bug
    ## a点高于c点 第一个高点大于第二个高点
    cond2 = s_high[a] > s_high[c]
    ## d低于b点 第一个低点大于第二个低点
    cond3 = s_ori[b] > s_ori[d]
    ## ad之间的限制  下降50%以内
    cond5 = s_ori[a] / s_ori[d] - 1 < 0.5
    ## 判断是否出现突破
    ## 其中e点为伪e 第三个高点大于第二个高点
    cond4 = s_ori[e] > s_ori[c]
    if cond2 and cond3 and cond4 and cond5:
        ## 判断e点
        ## 最高点
        e_cond1 = s_high.loc[d:e] > s_high[c]
        e_supply = np.arange(d, e+1)[e_cond1.values]
        # 判断成交量
        # 成交量判断无效
        for i in e_supply:
            if s_vol[i] > s_vol.loc[c:i].mean()*1.2:
                e = i
                return [a, b, c, d], e
                break

def get_stock_signal(df , window = 5, is_plot = True):
    ### 数据获取
    s_ori = df['closePrice'] * df['accumAdjFactor']
    s_high = df['highestPrice'] * df['accumAdjFactor']
    s_vol = df['turnoverVol']
    ## 去噪过程
    trend = s_ori.rolling(window).mean()
    back_w = int(window / 2.0)
    # trend.plot()
    ## 获取去噪之后的高低点
    index_down = signal.find_peaks(-trend)[0]
    index_up = signal.find_peaks(trend)[0]
    index_down = index_down[index_down > index_up[0]]
    ## 获取信号
    e_list = []
    lenth_w = []
    for n in range(5, index_up.shape[0]):
        a,b,c,d,qsdu_e = get_points(n, index_down, index_up, s_ori, back_w)
        if is_bottom(a, b, c, d, qsdu_e, s_ori, s_high, s_vol):
            [a, b ,c, d] , e = is_bottom(a, b, c, d, qsdu_e, s_ori, s_high, s_vol)
            e_list.append(e)
            lenth_w.append(e - a)
    if is_plot:
        s_ori.plot()
        plt.plot(e_list, s_ori[e_list], 'r*')
    return np.array(lenth_w), np.array(e_list)


# In[ ]:

## 统计盈利
def stat_ratio(e_list, df, n):
    return df.loc[e_list + n]['closePrice'].values / df.loc[e_list + 1]['openPrice'].values - 1
## 统计到df
def stock_df(df, elist, lenth_w, n_list = [5, 10, 15, 30]):
    df_1 = df.loc[e_list][['tradeDate', 'ticker']]
    ratio_list = [stat_ratio(e_list, df, n) for n in [5, 10, 15, 30]]
    df_new = pd.DataFrame(ratio_list + [lenth_w], index = ['r_5', 'r_10', 'r_15','r_30', 'lenth']).T
    df_1.index = df_new.index
    return pd.concat([df_1, df_new], axis = 1)

def back_test(df, e_list, hold_days = 5, is_plot = True):
    e_signal = np.hstack([e_list + i for i in range(1, hold_days + 1)])
    e_signal = np.unique(e_signal)
    e_signal = e_signal[e_signal < df.shape[0]]
    e_signal.sort()
    v = np.zeros(df.shape[0])
    v[e_signal] = 1
    
    if is_plot:
        r = ((v * df['chgPct']) + 1).cumprod()
        r.plot()
        (df['chgPct'] + 1).cumprod().plot()
        plt.show()

    return (v * df['chgPct']) + 1

def back_test_more(df, e_list, hold_days = [5, 7, 10 ,15, 20, 30, 35, 60]):
    df_back = pd.DataFrame([back_test(df, e_list, day, is_plot= False) for day in hold_days], index= ['r_%s'%i for i in hold_days]).T
    df_back['tradeDate'] = df['tradeDate']
    df_back['ticker'] = df['ticker']
    return df_back

time_start = datetime.now()
#index_code = '000001'
# ## 策略修改时间段
begin = '20101001'
end = datetime.strftime(datetime.now(),'%Y-%m-%d')
hs_300_pool = get_symbol_A()
## 以沪深300为例
flag = 0
all_dfs = []
back_dfs = []
T_symbols = len(hs_300_pool)
for i,ticker in enumerate(hs_300_pool):
    df = chs_factor(ticker= ticker ,begin = begin ,end = end)
    if len(df)==0:
        continue
    if df.shape[0]<240*2:
        continue
    lenth_w, e_list = get_stock_signal(df , window = 3, is_plot = False)
    all_dfs.append(stock_df(df, e_list, lenth_w))
    flag += 1
    print('S43 A stock update %d-%d' % (i,T_symbols))
    df_back = back_test_more(df, e_list)
    back_dfs.append(df_back)

back_df = pd.concat(back_dfs)
var_name = ['tradeDate', 'ticker','r_5', 'r_7', 'r_10', 'r_15', 'r_20', 'r_30', 'r_35', 'r_60']
var_type = []
for i in var_name:
    var_type.append('float')
var_type[0] = 'date'
var_type[1] = 'varchar(8)'
key_str = 'tradeDate,ticker'
tn = 'S43_Astock'
create_table_update('S37',tn,var_name,var_type,key_str,4)
t0 = pd.read_sql('select tradeDate from %s order by tradeDate desc limit 1' % tn,engine37)
t0 = t0.tradeDate[0]
back_df=back_df[back_df.tradeDate>t0]
if len(back_df)>0:
    back_df.to_sql(tn,engine37,if_exists='append',index=False,chunksize=3000)
    
time_end = datetime.now()
print('Time used %s' % (time_end-time_start))