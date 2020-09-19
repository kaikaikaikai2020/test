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


akshare 升级后，fix bug
requests 2.22  up to 2.23.0
akshare czce爬取数据中间逗号影响结果，修正 20200911
"""

import json
import os
from sqlalchemy import create_engine
import pandas as pd
import pymysql
import time
import akshare as ak
import datetime
#from pytdx.params import TDXParams
#标准接口  
from pytdx.hq import TdxHq_API 
#扩展行情接口
from pytdx.exhq import TdxExHq_API
from TDX_allfuture_mindata_update import update_future_minute_data

api_exhq = TdxExHq_API(auto_retry=True)
api_hg = TdxHq_API()

tt = time.strftime("%Y%m%d", time.localtime())

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

db_name3 = 'S26'
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name3)
engineS26 = create_engine(eng_str)

db_name_gta_web = 'gta_web'
eng_str='mysql+mysqlconnector://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name_gta_web)
engine_gtaweb = create_engine(eng_str)
#engine = create_engine('mysql+pymysql://root:liudehua@localhost:3306/yuqerdata?charset=utf8')
#engineS26 = create_engine('mysql+pymysql://root:liudehua@localhost:3306/S26?charset=utf8')
db_name_yq_datacub1 = 'yuqer_cubdata'
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name_yq_datacub1)
engine_yq_datacub1 = create_engine(eng_str)

db_name_S19factors = 'factors_com'
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name_S19factors)
engine_yq_S19factors = create_engine(eng_str)

db_name_tdx = 'pytdx_data'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name_tdx)
engine_tdx = create_engine(eng_str)

db_name_akshare = 'aksharedata'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name_akshare)
engine_akshare = create_engine(eng_str)

eng_str='mysql+pymysql://%s:%s@localhost:%d/futuredata?charset=utf8' % (user_name,pass_wd,port)
engine_futuredata = create_engine(eng_str)

db_nameS50 = 'S50'
#eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_name)
eng_str='mysql+pymysql://%s:%s@localhost:%d/%s?charset=utf8' % (user_name,pass_wd,port,db_nameS50)
engineS50 = create_engine(eng_str)


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
    db = pymysql.connect("localhost",user_name,pass_wd,db_name)
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

def get_tradingdate(t1,t2):
    sql_str = '''select tradeDate from yuqerdata.yq_index
                where tradeDate >= '%s' and tradeDate<='%s' 
                and symbol = '000001' order by tradeDate '''
    sql_str = sql_str % (t1,t2)
    t = pd.read_sql(sql_str,engine)
    return t.tradeDate.to_list()
#股指期货主力连续分钟数据  期货分钟数据可以下载很长时间的
def write_ICFT_min():
    t0=pd.read_sql('select tradingdate from pytdx_data.ic_tdx_min order by tradingdate desc limit 1',engine_tdx)  
    if len(t0)>0:
        t0 =t0.tradingdate[0].strftime('%Y-%m-%d')
    else:
        t0 = '2016-12-18'
              
    t = get_tradingdate(t0,tt)
    t = t[1:]
    if len(t)>0:
        I_code_pool = ['IF','IC','IH']
        T = len(t)
        with api_exhq.connect('106.14.95.149', 7727):
            for i,sub_t in enumerate(t):
                sub_t1 = int(sub_t.strftime('%Y%m%d'))
                sub_t2 = sub_t.strftime('%Y-%m-%d')
                for sub_tn in I_code_pool:
                    fn_bond = '%s_tdx_min' % sub_tn
                    sub_tn = '%sL8' % sub_tn
                    data = api_exhq.to_df(api_exhq.get_history_minute_time_data(47, sub_tn, sub_t1))
                    data.rename(columns={'hour':'t_hour','minute':'t_minute'},inplace=True)
                    data['tradingdate'] = sub_t2
                    data.to_sql(fn_bond,engine_tdx,if_exists='append',index=False,chunksize=3000)
                    print('%s %d-%d' % (sub_t2,i,T))
    else:
        print('股指期货分钟数据已经是最新')
def write_index_min():
    #指数数据更新
    index_code_pool = ['000300','000905','000016']
    index_name_pool = ['300','500','50']    
    for i,tn in enumerate(index_code_pool):
        fn_bond = 'tdx_min_%s' % index_name_pool[i]
        t0=pd.read_sql('select tradingdate from pytdx_data.%s order by tradingdate desc limit 1' % fn_bond,engine_tdx)  
        #print(t0)
        if len(t0)>0:
            t0 =t0.tradingdate[0].strftime('%Y-%m-%d %H:%M')
        else:
            t0 = '2016-12-18'
            
        with api_hg.connect('119.147.212.81', 7709):
            #指数分钟 最近96个交易日的数据
            ind=0
            max_num = 800
            data = [1]
            while len(data)>0:
                data = api_hg.to_df(api_hg.get_index_bars(8,1, tn, ind, max_num))
                ind = ind + 800
                if len(data)>0:
                    data = data[data.datetime> t0]
                    if len(data)>0:
                        data.rename(columns={'datetime':'tradingdate','year':'t_year',
                                             'month':'t_month','day':'t_day','hour':'t_hour',
                                             'minute':'t_minute'},inplace=True)
                        #data.to_csv('Test.csv')
                        data.to_sql(fn_bond,engine_tdx,if_exists='append',index=False,chunksize=3000)
                print('指数分钟数据%d' % ind)
#查询分笔成交 data = api.to_df(api.get_history_transaction_data(47, "IFL8", 20161230,start=0))            
def write_tdx_fenbicj():
    I_code_pool = ['IF','IC','IH']
    t0_fenbi = pd.read_sql('select date(tradingdate) from pytdx_data.tdx_fenbi_if order by tradingdate desc limit 1',engine_tdx)  
    if len(t0_fenbi)>0:
        t0_fenbi =t0_fenbi['date(tradingdate)'][0].strftime('%Y-%m-%d %H:%M')
    else:
        t0_fenbi = '2016-11-01'
    t = get_tradingdate(t0_fenbi,tt)
    t = t[1:]
    T = len(t)
    max_num2 = 1800
    with api_exhq.connect('106.14.95.149', 7727):
        for i,sub_t in enumerate(t):
            sub_t1 = int(sub_t.strftime('%Y%m%d'))
            sub_t2 = sub_t.strftime('%Y-%m-%d')
            for sub_tn in I_code_pool:
                fn_bond = 'tdx_fenbi_%s' % sub_tn
                sub_tn = '%sL8' % sub_tn
                data = [1]
                ind=0
                while len(data)>0:
                    data = api_exhq.to_df(api_exhq.get_history_transaction_data(47, sub_tn, sub_t1,start=ind))
                    ind = ind + max_num2
                    if len(data)>0:
                        data.rename(columns={'date':'tradingdate','hour':'t_hour','minute':'t_minute'},inplace=True)
                        data.to_sql(fn_bond,engine_tdx,if_exists='append',index=False,chunksize=3000)
                print('分笔成交数据：%s %d-%d' % (sub_t2,i,T))
def write_ETF_min():
    #指数数据更新
    index_code_pool = ['510050','510300','510500']
    for i,tn in enumerate(index_code_pool):
        fn_bond = 'tdx_min_ETF_%s' % tn
        t0=pd.read_sql('select tradingdate from pytdx_data.tdx_min_ETF_%s order by tradingdate desc limit 1' % tn,engine_tdx)  
        if len(t0)>0:
            t0 =t0.tradingdate[0].strftime('%Y-%m-%d %H:%M')
        else:
            t0 = '2016-12-18'
        
        with api_hg.connect('119.147.212.81', 7709):
            ind=0
            max_num = 800
            data = [1]
            while len(data)>0:
                data = api_hg.to_df(api_hg.get_security_bars(8,1, tn, ind, max_num))
                ind = ind + 800
                if len(data)>0:
                    data = data[data.datetime> t0]
                    if len(data)>0:
                        data.rename(columns={'datetime':'tradingdate','year':'t_year',
                                             'month':'t_month','day':'t_day','hour':'t_hour',
                                             'minute':'t_minute'},inplace=True)
                        data.to_sql(fn_bond,engine_tdx,if_exists='append',index=False,chunksize=3000)
                print('ETF min data update %d' % ind)
#akshare data
def update_bond_china_yield():
    fn_bond = 'bond_china_yield'
    t0 = pd.read_sql('select tradingdate from %s order by tradingdate desc limit 1' % 
                     fn_bond,engine_akshare)
    t0 = t0.tradingdate[0]+datetime.timedelta(days=1)
    t0 = t0.strftime('%Y-%m-%d')
    tt=time.strftime("%Y-%m-%d", time.localtime())
    x = ak.bond_china_yield(start_date=t0, end_date=tt)
    x.rename(columns={'曲线名称':'symbol','日期':'tradingdate','3月':'3m', '6月':'6m',
                          '1年':'1y', '3年':'3y', '5年':'5y', '7年':'7y', 
                          '10年':'10y', '30年':'30y'},inplace=True)
    x.to_sql(fn_bond,engine_akshare,if_exists='append',index=False,chunksize=3000)
    print('akshare 国债收益数据已更新')
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

def update_akshare_futuredata(table_name1,data_name):
    f_str1 = ['%s:%s 仓位数据已更新',
          '%s:%s 仓位数据为空',
          '%s:%s 价格数据未更新（休息日请忽略，否者核查数据下载步骤）',
         '%s仓位数据库时间为：%s']
    process_recorder = []
    #calendar = fushare.cons.get_calendar()
    #update 使用yuqer的交易日日历
    sql_str1 = 'select tradeDate from yuqerdata.yq_index  where symbol = "000001" order by tradeDate'
    tref = pd.read_sql(sql_str1,eng_str)
    t0=datetime.datetime.strftime(tref.tradeDate.values[0],'%Y-%m-%d')
    tt=datetime.datetime.strftime(tref.tradeDate.values[-1],'%Y-%m-%d')
    
    calendar = pd.date_range(start=t0, end=tt)
    calendar = calendar.date
    #下午四点以后再更新当日数据
    if datetime.datetime.now().hour>16:
        t_end = datetime.date.today()
    else:
        t_end = (datetime.datetime.now()-datetime.timedelta(days=1)).date()
    
    sql_t_begin = 'select tradingdate from %s order by tradingdate desc limit 1' %(table_name1);
    t_begin = pd.read_sql_query(sql_t_begin, engine_futuredata)
    
    tref_undo_data = calendar[(calendar>t_begin.tradingdate[0]) & (calendar<=t_end)]        
    process_recorder.append(f_str1[-1] % (data_name,t_begin.tradingdate[0]))
    for t in tref_undo_data:
        t2 = t.strftime('%Y-%m-%d')
        if table_name1=='dce_data':
            x = ak.get_dce_rank_table(t2)
        elif table_name1=='shfe_data':
            x = ak.get_shfe_rank_table(t2)
        elif table_name1=='czce_data':
            x = ak.get_czce_rank_table(t2)
        else:
            x = ak.get_cffex_rank_table(t2) 
        if x is not None:
            if x:
                y = com_dict_data(x,t2)
                if y is None:
                    print('None')
                    print(x)
                col_check = ['rank', 'vol', 'vol_chg', 'long_openIntr', 'long_openIntr_chg',
                             'short_openIntr', 'short_openIntr_chg']
                for sub_col in col_check:
                    if sub_col in y.columns:
                        y[sub_col]=ak_str2float(y,sub_col)
 
                y.to_sql(table_name1,engine_futuredata,if_exists='append',index=False)
                process_recorder.append(f_str1[0] % (t2,data_name))
            else:
                process_recorder.append(f_str1[1] % (t2,data_name))
        else:
            process_recorder.append(f_str1[1] % (t2,data_name))
    return process_recorder

def update_future_rank_table():    
    method_keywords = ['shfe','czce','cffex','dce']
    method_info=['上商所','郑商所','中商所','大商所']
    table_name1_all=[]
    for key_w in method_keywords:
        table_name1_all.append(key_w+'_data')
    
    T = range(4);
    info= []
    for e_sel in T:
        table_name1=table_name1_all[e_sel]        
        data_name=method_info[e_sel]
        print(data_name)
        try:
            sub_info=update_akshare_futuredata(table_name1,data_name)
            info=info+sub_info
        except Exception as e:
            info.append(e)
            print('%s 爬取失败!' % data_name)
        else:
            print('%s 成功爬取!' % data_name)
    for str in info:
        print(str)
    return info            

def update_us_index():
    symbol_pool = ['.NDX','.INX']
    ticker_pool = ['NDX','SPX']
    tn = 'index_sina'
    for i,symbol in enumerate(symbol_pool):
        x= ak.stock_us_daily(symbol=symbol)
        ticker = ticker_pool[i]
        if len(x)>0:
            x.reset_index(inplace=True)
            #爬取数据的字段有问题
            x.columns=['tradeDate','openIndex','highestIndex', 'lowestIndex','closeIndex','volume']
            x['ticker'] = ticker
            t0 = x.tradeDate.astype(str).min()
            t2 = x.tradeDate.astype(str).max()
            sql_temp = 'delete from %s where ticker = "%s" and tradeDate>="%s"' % (tn,ticker,t0)
            do_sql_order(sql_temp,db_nameS50)
            x.to_sql(tn,engineS50,if_exists='append',index=False,chunksize=3000)
            print('update index_sina %s %s' % (ticker,t2))
        
def rm_spec_sym_adair(x):
    def rm_douhao(x):
        if isinstance(x,str):
            return x.replace(',','')
        else:
            return x
    for sub_col in x.columns:
        x[sub_col] = x[sub_col].apply(lambda x:rm_douhao(x))
    return x

def get_currency_hist(ticker,t0=None,tt=time.strftime('%Y%m%d')):
    tn = 'currency_hist'
    ticker_f = ticker.replace('-','')
    sql_str = 'select tradeDate from %s where ticker = "%s" order by tradeDate desc limit 1'
    if t0 is None:
        t0 = pd.read_sql(sql_str % (tn,ticker_f),engine_akshare)
        if len(t0)>0:
            t0=t0.tradeDate.astype(str).values[0].replace('-','')
        else:
            t0 = '20050101'    
        
    if t0==tt:
        return [],[],[]
    else:
        x=ak.currency_hist(symbol=ticker, start_date=t0, end_date=tt)
        if isinstance(x["涨跌幅"].values[0],str):
            x["涨跌幅"] = pd.DataFrame(x['涨跌幅'].str.replace(',', ''))
            x["涨跌幅"] = pd.DataFrame(round(x['涨跌幅'].str.replace('%', '').astype(float) / 100, 6))
        x=rm_spec_sym_adair(x)
        x = x.astype(float)
        
        x.reset_index(inplace=True)
        x.rename(columns={'日期':'tradeDate','收盘':'closePrice','开盘':'openPrice',
                          '高':'highestPrice','低':'lowestPrice','涨跌幅':'CHG'},inplace=True)
        x['ticker'] = ticker_f
        return x,t0,ticker_f
def update_usforex():
    tn = 'currency_hist'
    #ticker_pool0=ak.currency_name_code()
    #ticker_pool = ticker_pool0.code.tolist()
    ticker_pool=['usd-twd','usd-krw','usd-twd','usd-cnh','usd-try','usd-zar']
    e_code = []
    for i,ticker in enumerate(ticker_pool):
        try:
            x,t0,ticker_f=get_currency_hist(ticker)
            if len(x)>0:
                do_sql_order('delete from %s where tradeDate>="%s" and ticker="%s"' % (tn,t0,ticker_f),db_name_akshare)
                x.to_sql(tn,engine_akshare,if_exists='append',index=False,chunksize=3000)
            print('%s-%s' % (i,ticker))
        except:
            print('Error %s-%s' % (i,ticker))
            e_code.append(ticker)             
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
    
"""
fns,_ = get_file_name(pn,'.zip')
_,fns_csv = get_file_name(pn,'.csv')
for sub_fn in fns:
    f = zipfile.ZipFile(sub_fn,'r')
    for file in f.namelist():
        if file not in fns_csv:
            f.extract(file,pn)
"""        
_,fns_csv = get_file_name(pn,'.csv')
_,fns_csv1 = get_file_name(pn,'.txt')
for i in fns_csv1:
    fns_csv.append(i)
    
fns_data = [];
for i in range(50):
    fns_data.append([])

for sub_fn in fns_csv:
    if 'EquGet' in sub_fn:
        fns_data[0] = os.path.join(pn,sub_fn)
    elif 'indicator_data' in sub_fn:
        fns_data[1] = os.path.join(pn,sub_fn)
    elif 'tickerday_data' in sub_fn:
        fns_data[2] = os.path.join(pn,sub_fn)
    elif 'tradingdate' in sub_fn:
        fns_data[3] = os.path.join(pn,sub_fn)
    elif 'MktEqumAdjAfGet' in sub_fn:
        fns_data[4] = os.path.join(pn,sub_fn)
    elif 'EquIndustryGet' in sub_fn:
        fns_data[5] = os.path.join(pn,sub_fn)
    elif 'st_data' in sub_fn:
        fns_data[6] = os.path.join(pn,sub_fn)
    elif 'IdxCloseWeightGet' in sub_fn:
        fns_data[7].append(os.path.join(pn,sub_fn))
    elif 'yuqer_cal' in sub_fn:
        fns_data[8].append(os.path.join(pn,sub_fn))
    elif 'MktEqudAdjAfGet_data' in sub_fn:
        fns_data[9].append(os.path.join(pn,sub_fn))
    elif 'MktIdxmGet' in sub_fn:
        fns_data[10]= os.path.join(pn,sub_fn)
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
        fns_data[17] = os.path.join(pn,sub_fn)
    elif 'MktMFutdGet_adair' in sub_fn:
        fns_data[18] = os.path.join(pn,sub_fn)
    elif 'MktFutMTRGet' in sub_fn:
        fns_data[19]=os.path.join(pn,sub_fn)
    elif 'MktFutMSRGet' in sub_fn:
        fns_data[20]= os.path.join(pn,sub_fn)
    elif 'MktFutMLRGet' in sub_fn:
        fns_data[21]=os.path.join(pn,sub_fn)  
    elif 'FutuGet' in sub_fn:
        fns_data[22]=os.path.join(pn,sub_fn)  
    elif 'MktFutWRdGet' in sub_fn:
        fns_data[23]=os.path.join(pn,sub_fn)  
    elif 'MktConsBondPerfGet_adair' in sub_fn:
        fns_data[24]=os.path.join(pn,sub_fn)  
    elif 'MktIdxdEvalGet_adair' in sub_fn:
        fns_data[25]=os.path.join(pn,sub_fn)  
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
data_id = 0
#1  股票基本数据已更新
if len(fns_data[data_id])>0:
    tn = 'equget'
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python',encoding='utf-8')
    x = x[['ticker','exchangeCD','ListSectorCD','ListSector','secShortName',
           'listStatusCD','listDate','delistDate','equTypeCD','equType','partyID',
           'totalShares','nonrestFloatShares','nonrestfloatA','endDate','TShEquity']]
    do_sql_order('truncate table %s' % (tn),'yuqerdata')
    x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
    print('股票基本数据已更新')
    os.remove(fns_data[data_id])
    
#2 index
data_id = 1
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python',encoding='utf-8')
    tn = 'yq_index'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn
    t = pd.read_sql(sql_str1,engine)
    
    if not t.empty:
        tt_str = str(t.tradedate[0])
    else:
        tt_str = '1990-01-01'  
    #tt_str = '1990-01-01'  
    x2 = x.loc[x.tradeDate>str(tt_str)]
    if not x2.empty:
        x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
        print('每日指数数据更新至%s' % x2.tradeDate.max())
    else:
        print('每日指数数据已经是最新的%s，无需更新' % tt_str) 
    os.remove(fns_data[data_id])
           
#3 day price
data_id=2
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python')
    tn1 = 'yq_dayprice'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.tradeDate>str(t.tradedate[0])]
    if not x2.empty:
        x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('每日股票数据更新至%s' % x2.tradeDate.max())
    else:
        print('每日股数据已经是最新的%s，无需更新' % str(t.tradedate[0]))
    os.remove(fns_data[data_id])
#4 tradingdate
data_id = 3
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],engine='python')
    tn1 = 'yq_tradingdate_future'
    """    
    sql_str1 = 'select tradingdate from %s order by tradingdate desc limit 1' % tn1
    try:
        t = pd.read_sql(sql_str1,engine)
    except:
        t = pd.DataFrame()            
    if not t.empty:
        tt_str = str(t.tradingdate[0])
        x2 = x.loc[x.tradingdate>tt_str]
    else:
        tt_str = '1990-01-01'
        x2 = x
    """
    tt_str = '1990-01-01'
    x2 = x
    if not x2.empty:
        do_sql_order('truncate table %s' % (tn1),'yuqerdata')
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)   #每次都重新更新
        print('交易日数据更新至%s' % x2.tradingdate.max())
    else:
        print('交易日数据已经是最新的%s，无需更新' % tt_str)
    os.remove(fns_data[data_id])
        
#5 mongth data  后复权
data_id = 4
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python')
    tn1 = 'MktEqumAdjAfGet'
    sql_str1 = 'select enddate from %s order by enddate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.endDate>str(t.enddate[0])]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('每月股票后复权数据更新至%s' % x2.endDate.max())        
    else:
        print('每月股后复权数据已经是最新的%s，无需更新' % str(t.enddate[0]))
    os.remove(fns_data[data_id])
#6 行业数据
data_id = 5
if len(fns_data[data_id])>0:
    tn = 'yq_industry_sw'
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python',encoding='utf-8')
    do_sql_order('truncate table %s' % (tn),'yuqerdata')
    x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
    print('行业数据已更新')
    os.remove(fns_data[data_id])
#7 st
data_id = 6
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python')
    tn1 = 'st_info'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.tradeDate>str(t.tradedate[0])]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.drop_duplicates(subset=['ticker','tradeDate'], keep='first', inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('st数据更新至%s' % x2.tradeDate.max())
    else:
        print('st数据已经是最新的%s，无需更新' % str(t.tradedate[0]))
    os.remove(fns_data[data_id])
    
#8 指数成分股数据
data_id = 7
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str,'consTickerSymbol':str},engine='python')
        os.remove(sub_fn)
        if len(x.index)==0:
            continue
        
        x.rename(columns={'effDate':'tradingdate','consTickerSymbol':'symbol'},inplace=True)
        tn1 = 'IdxCloseWeightGet'
        sql_str1 = 'select tradingdate from %s where ticker="%s" order by tradingdate desc limit 1' % (tn1,x.ticker[0])
        t = pd.read_sql(sql_str1,engine)
        if not t.empty:
            tt_str = str(t.tradingdate[0])
        else:
            tt_str = '1990-01-01'        
        #tt_str = '1990-01-01'
        x2 = x.loc[x.tradingdate>tt_str]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('%s指数成分股数据更新至%s' % (x.ticker[0],x2.tradingdate.max()))
        else:
            print('%s指数成分股数据已经是最新的%s，无需更新' % (x.ticker[0],tt_str)) 
            
#9 补充交易日数据
data_id = 8
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,engine='python')
        os.remove(sub_fn)
        if len(x.index)==0:
            continue        
        tn1 = 'yuqer_cal'
        #sql_str1 = 'select calendarDate from %s  order by calendarDate desc limit 1' % (tn1)
        #t = pd.read_sql(sql_str1,engine)
        #if not t.empty:
        #    tt_str = str(t.calendarDate[0])
        #else:
        #    tt_str = '1990-01-01'        
        #tt_str = '1990-01-01'
        #x2 = x.loc[x.calendarDate>tt_str]
        x2 = x
        if not x2.empty:
            do_sql_order('truncate table %s' % (tn1),'yuqerdata')
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            #为了保持原来table的格式不变
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('交易日数据更新至%s' % (x2.calendarDate.max()))
        else:
            print('交易日数据已经是最新的%s，无需更新' % (tt_str)) 
#10 后复权数据
data_id = 9
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        os.remove(sub_fn)
        if len(x.index)==0:
            continue
        
        tn1 = 'yq_MktEqudAdjAfGet'
        sql_str1 = 'select tradeDate from %s  order by tradeDate desc limit 1' % (tn1)
        t = pd.read_sql(sql_str1,engine)
        if not t.empty:
            tt_str = str(t.tradeDate[0])
        else:
            tt_str = '1990-01-01'        
        #tt_str = '1990-01-01'
        x2 = x.loc[x.tradeDate>tt_str]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('后复权数据1更新至%s' % (x2.tradeDate.max()))
        else:
            print('后复权数据1已经是最新的%s，无需更新' % (tt_str)) 

        tn2 = 'MktEqudAdjAfGet'
        sql_str1 = 'select tradeDate from %s  order by tradeDate desc limit 1' % (tn2)
        t = pd.read_sql(sql_str1,engine)
        if not t.empty:
            tt_str = str(t.tradeDate[0])
        else:
            tt_str = '1990-01-01'        
        #tt_str = '1990-01-01'
        x2 = x.loc[x.tradeDate>tt_str]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2[['ticker','tradeDate','accumAdjFactor']].to_sql(tn2,engine,if_exists='append',index=False,chunksize=3000)
            print('后复权数据2更新至%s' % (x2.tradeDate.max()))
        else:
            print('后复权数据2已经是最新的%s，无需更新' % (tt_str))     
#11 指数月度数据mongth data
data_id = 10
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    tn1 = 'yq_index_month'
    x.rename(columns={'ticker':'symbol'},inplace=True)
    sql_str1 = 'select enddate from %s order by enddate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.endDate>str(t.enddate[0])]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('指数每月数据更新至%s' % x2.endDate.max())
    else:
        print('指数每月数据已经是最新的%s，无需更新' % str(t.enddate[0]))
    os.remove(fns_data[data_id])
#S26计算中性化收益需要因子
data_id = 11    
if len(fns_data[data_id])>0:
    sub_fn = fns_data[data_id]
    x1 = pd.read_csv(sub_fn,header=0,engine='python',encoding = "utf-8",index_col=False)
    x1['ticker'] = x1['ticker'].apply(add_0)
    table_name = 'yq_MktStockFactorsOneDayGet_S26'
    sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engineS26)
    info = 'S26 10 Factors data'
    if not t.empty:
        tt_str = str(t.tradeDate[0])
    else:
        tt_str = '1990-01-01'
    x2 = x1.loc[x1.tradeDate>tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engineS26,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(sub_fn) 
    
data_id=12
if len(fns_data[data_id])>0:
    sub_id = data_id
    x1 = pd.read_csv(fns_data[sub_id],header=0,engine='python',encoding = "utf-8",index_col=False)
    x1['ticker'] = x1['ticker'].apply(add_0)
    table_name = 'yq_MktStockFactorsOneDayGet_add_S26'
    sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engineS26)
    info = 'S26 3 added Factors'
    if not t.empty:
        tt_str = str(t.tradeDate[0])
    else:
        tt_str = '1990-01-01'
    x2 = x1.loc[x1.tradeDate>tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engineS26,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[sub_id]) 

#整个历史数据下载，测试没有问题
data_id = 13    
if len(fns_data[data_id])>0:
    try:
        x1 = pd.read_csv(fns_data[data_id],sep='\t',header=0,engine='python',
                         skiprows=lambda x: x in [1, 2])
    except:
        x1 = pd.read_csv(fns_data[data_id],sep='\t',header=0, 
                         skiprows=lambda x: x in [1, 2],encoding='utf-16')
        
    table_name = 'french_factor_3'
    sql_str1 = 'select TradingDate from %s order by TradingDate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engine_gtaweb)
    info = '国泰安-Fama-French因子 三因子日度'
    if not t.empty:
        tt_str = str(t.TradingDate[0])
    else:
        tt_str = '1990-01-01'
    x2 = x1.loc[x1.TradingDate>tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engine_gtaweb,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.TradingDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[data_id])
    
#数据立方数据1 
data_id = 14
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x,tn1 = read_yuqer_datacube_data(sub_fn)
        os.remove(sub_fn)
        if len(x.index)==0:
            continue
        info = '优矿数据立方数据：%s' % tn1
        sql_str1 = 'select tradingdate from %s  order by tradingdate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine_yq_datacub1)
        if not t.empty:
            tt_str = str(t.tradingdate[0])
        else:
            tt_str = '1990-01-01'        
        #tt_str = '1990-01-01'
        x2 = x.loc[x.tradingdate>tt_str]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine_yq_datacub1,if_exists='append',index=False,chunksize=3000)
            print('%s更新至%s' % (info,x2.tradingdate.max()))
        else:
            print('%s已经是最新的%s，无需更新' % (info,tt_str))

#数据立方数据2 
data_id = 15
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x,tn1 = read_yuqer_datacube_data(sub_fn)
        os.remove(sub_fn)
        if len(x.index)==0:
            continue
        info = '优矿数据立方辅助因子数据：%s' % tn1
        sql_str1 = 'select tradingdate from %s  order by tradingdate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine_yq_S19factors)
        if not t.empty:
            tt_str = str(t.tradingdate[0])
        else:
            tt_str = '1990-01-01'        
        #tt_str = '1990-01-01'
        x2 = x.loc[x.tradingdate>tt_str]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine_yq_S19factors,if_exists='append',index=False,chunksize=3000)
            print('%s更新至%s' % (info,x2.tradingdate.max()))
        else:
            print('%s已经是最新的%s，无需更新' % (info,tt_str))
        
#财务数据，更新有滞后，最好删除前一天的数据，重新更新            
data_id=16
if len(fns_data[data_id])>0:
    sub_id = data_id
    x1 = pd.read_csv(fns_data[sub_id],header=0,engine='python',encoding = "utf-8",index_col=False)
    x1['ticker'] = x1['ticker'].apply(add_0)
    table_name = 'yq_s19factors'
    sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engine)
    info = 'S19优矿辅助因子'
    if not t.empty:
        tt_str = str(t.tradeDate[0])
    else:
        tt_str = '1990-01-01'
    do_sql_order(sql_str_deldata % (table_name,'tradeDate',tt_str),'yuqerdata')
    x2 = x1.loc[x1.tradeDate>=tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[sub_id]) 
    
#基金日行情          
data_id=17
if len(fns_data[data_id])>0:
    sub_id = data_id
    x1 = pd.read_csv(fns_data[sub_id],header=0,engine='python',encoding = "utf-8",index_col=False)
    x1['ticker'] = x1['ticker'].apply(add_0)
    table_name = 'MktFunddGet'
    sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engine)
    info = '基金日行情'
    if not t.empty:
        tt_str = str(t.tradeDate[0])
    else:
        tt_str = '1990-01-01'
    x2 = x1.loc[x1.tradeDate>tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[sub_id]) 

#期货主力、连续合约日行情    
data_id=18
if len(fns_data[data_id])>0:
    sub_id = data_id
    x1 = pd.read_csv(fns_data[sub_id],header=0,engine='python',encoding = "utf-8",index_col=False)
    #x1['ticker'] = x1['ticker'].apply(add_0)
    table_name = 'yq_MktMFutdGet'
    sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engine)
    info = '期货主力、连续合约日行情'
    if not t.empty:
        tt_str = str(t.tradeDate[0])
    else:
        tt_str = '1990-01-01'
    x2 = x1.loc[x1.tradeDate>tt_str]
    if not x2.empty:    
        x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('%s:%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[sub_id]) 
    
#19 期货会员成交量排名
data_id=19
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    tn1 = 'yq_MktFutMTRGet'
    info='期货会员成交量排名'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.tradeDate>str(t.tradedate[0])]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s更新至%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,str(t.tradedate[0])))
    os.remove(fns_data[data_id])
#20 期货会员空头持仓排名
data_id=20
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    tn1 = 'yq_MktFutMSRGet'
    info='期货会员空头持仓排名'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.tradeDate>str(t.tradedate[0])]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s更新至%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,str(t.tradedate[0])))
    os.remove(fns_data[data_id])
#21 期货会员多头持仓排名    
data_id=21
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    tn1 = 'yq_MktFutMLRGet'
    info='期货会员多头持仓排名'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.tradeDate>str(t.tradedate[0])]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s更新至%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,str(t.tradedate[0])))
    os.remove(fns_data[data_id])

data_id = 22
#22 期货合约信息
if len(fns_data[data_id])>0:
    tn = 'yq_FutuGet'.lower()
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str},engine='python',encoding='utf-8')
    #do_sql_order('truncate table %s' % (tn),'yuqerdata')
    x.to_sql(tn,engine,if_exists='replace',index=False,chunksize=3000)
    print('期货合约信息')
    os.remove(fns_data[data_id])

#期货仓单日报   
data_id=23
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    tn1 = 'yq_MktFutWRdGet'
    info='期货仓单日报'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    x2 = x.loc[x.tradeDate>str(t.tradedate[0])]
    if not x2.empty:
        x2 = x2[['tradeDate', 'contractObject', 'exchangeCD', 'unit', 'warehouse',
       'preWrVOL', 'wrVOL', 'chg']]
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s更新至%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,str(t.tradedate[0])))
    os.remove(fns_data[data_id])
    
#可转债市场
data_id=24
if len(fns_data[data_id])>0:
    x1 = pd.read_csv(fns_data[data_id],header=0,encoding = "utf-8",dtype={'tickerEqu':str})
    #x1['tickerEqu'] = x1['tickerEqu'].apply(add_0)
    table_name = 'ConvertibleBond_dayprice'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % table_name
    t = pd.read_sql(sql_str1,engine)
    x2 = x1.loc[x1.tradeDate>str(t.tradedate[0])]
    if not x2.empty:        
        x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
        print('可转债数据更新至%s' % x2.tradeDate.max())
    else:
        print('可转债数据已经是最新的%s，无需更新' % str(t.tradedate[0]))
    os.remove(fns_data[data_id])
    
#指数估值信息   
data_id=25
if len(fns_data[data_id])>0:
    x = pd.read_csv(fns_data[data_id],dtype={'ticker':str})
    tn1 = 'yq_MktIdxdEvalGet'
    info='指数估值信息'
    sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
    t = pd.read_sql(sql_str1,engine)
    if not t.empty:
        tt_str = str(t.tradedate[0])
    else:
        tt_str = '1990-01-01'
    x2 = x.loc[x.tradeDate>tt_str]
    if not x2.empty:
        #x2.rename(columns={'ticker':'symbol'},inplace=True)
        x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
        print('%s更新至%s' % (info,x2.tradeDate.max()))
    else:
        print('%s已经是最新的%s，无需更新' % (info,tt_str))
    os.remove(fns_data[data_id])

#ETF基金申赎清单成分券信息
sub_id = 26    
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x1 = pd.read_csv(sub_fn,header=0,index_col=0)
        table_name = 'yq_FundETFConsGet'
        sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
        t = pd.read_sql(sql_str1,engine)
        info = 'ETF基金申赎清单成分券信息'
        if not t.empty:
            tt_str = str(t.tradeDate[0])
        else:
            tt_str = '1990-01-01'
        x2 = x1.loc[x1.tradeDate>tt_str]
        if not x2.empty:    
            x2.to_sql(table_name,engine,if_exists='append',index=False,chunksize=3000)
            print('%s:%s' % (info,x2.tradeDate.max()))
        else:
            print('%s已经是最新的%s，无需更新' % (info,tt_str))
        os.remove(sub_fn) 

#ETF基金申赎清单基本信息
sub_id = 27    
data_check = True
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x1 = pd.read_csv(sub_fn,header=0,index_col=0)
        table_name = 'yq_FundETFPRListGet'
        
        if data_check:
            sql_str1 = 'select tradeDate from %s order by tradeDate desc limit 1' % table_name
            t = pd.read_sql(sql_str1,engine)
            info = 'ETF基金申赎清单基本信息'
            if not t.empty:
                tt_str = str(t.tradeDate[0])
            else:
                tt_str = '1990-01-01'
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
#股票周行情
sub_id = 28
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn1 = 'yq_MktEquwAdjAfGet'
        if not x.empty:
            tt_str = x.endDate.min()            
            do_sql_order('delete from %s where endDate>="%s"' % (tn1,tt_str),db_name1)
            
            x.rename(columns={'return':'weekreturn'},inplace=True)
            x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('每周股票后复权数据更新至%s' % x.endDate.max())
        os.remove(sub_fn)
#指数周行情
sub_id = 29
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:        
        tn1 = 'yq_MktIdxwGet'    
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        if len(x)>0:            
            tt_str = x.endDate.min()            
            do_sql_order('delete from %s where endDate>="%s"' % (tn1,tt_str),db_name1)
            x.rename(columns={'return':'weekreturn'},inplace=True)
            x.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('每周指数后复权数据更新至%s' % x.endDate.max())
        os.remove(sub_fn)
#30 证券编码及基本上市信息 SecIDGet  
sub_id = 30
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'yq_SecIDGet'
        do_sql_order('truncate table %s' % (tn),'yuqerdata')
        x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
        print('证券编码及基本上市信息')
        os.remove(sub_fn) 

#31 停复牌数据库 SecHaltGet
sub_id = 31
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'yq_SecHaltGet'
        do_sql_order('truncate table %s' % (tn),'yuqerdata')
        x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
        print('停复牌数据库')
        os.remove(sub_fn) 

"""
"""
#32 ST标记 SecSTGet
sub_id = 32
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'yq_SecSTGet'
        #do_sql_order('truncate table %s' % (tn),'yuqerdata')
        x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
        print('ST标记')
        os.remove(sub_fn) 

#每日因子数据
sub_id = 33    
data_check = True
table_name = 'yq_MktStockFactorsOneDayGet'
info = '每日因子更新'
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})     
        if len(x1)>0:           
            if data_check:
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
#信息数据
sub_id = 34    
data_check = True
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})
        table_name = 'yq_SocialDataGubaGet'
        
        if data_check:
            sql_str1 = 'select statisticsDate from %s order by statisticsDate desc limit 1' % table_name
            t = pd.read_sql(sql_str1,engine)
            info = '贴吧信息数据'
            if not t.empty:
                tt_str = str(t.statisticsDate[0])
            else:
                tt_str = '1990-01-01'
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
#申万行业回填（含科创板）
sub_id = 35
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'yq_MdSwBackGet'
        do_sql_order('truncate table %s' % (tn),'yuqerdata')
        x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
        print('申万行业回填（含科创板）')
        os.remove(sub_fn)     
        
#36
sub_id = 36
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'FundGet_S51'
        if len(x)>0:
            do_sql_order('truncate table %s' % (tn),'yuqerdata')
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('基金基本信息已经更新')
        os.remove(sub_fn) 
sub_id = 37
#'yq_FundAssetsGet_S51' in sub_fn:
if len(fns_data[sub_id])>0:
    info = '基金资产配置'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'yq_FundAssetsGet_S51'
        if len(x)>0:
            x.drop_duplicates(subset=['ticker','reportDate','updateTime'], 
                                        keep='first', inplace=True)
            t0 = x.updateTime.astype(str).min()
            t2 = x.updateTime.astype(str).max()        
            sql_str = 'delete from %s where updateTime>="%s"' % (tn,t0)
            do_sql_order(sql_str,db_name1)            
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('%s已经更新至%s' % (info,t2))
        os.remove(sub_fn) 
#FundNavGet_S51
sub_id = 38
if len(fns_data[sub_id])>0:
    info = '基金历史净值(货币型,短期理财债券型除外)'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'FundNavGet_S51'
        if len(x)>0:
            t0 = x.endDate.astype(str).min()
            t2 = x.endDate.astype(str).max()        
            sql_str = 'delete from %s where endDate>="%s"' % (tn,t0)
            do_sql_order(sql_str,db_name1)            
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('%s已经更新至%s' % (info,t2))
        os.remove(sub_fn)       
#每日专业因子数据
sub_id = 39    
data_check = True
table_name = 'yq_MktStockFactorsOneDayProGet'
info = '每日专业因子数据'
if len(fns_data[sub_id])>0:
    for sub_fn in fns_data[sub_id]:
        x1 = pd.read_csv(sub_fn,header=0,dtype={'ticker':str})     
        if len(x1)>0:           
            if data_check:
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
        
        
sub_id = 40
if len(fns_data[sub_id])>0:
    info = 'CME期货日行情'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str,'holdingTicker':str})
        tn = 'MktCmeFutdGet_S50'
        if len(x)>0:
            t0 = x.tradeDate.astype(str).min()
            t2 = x.tradeDate.astype(str).max()        
            sql_str = 'delete from %s where tradeDate>="%s"' % (tn,t0)
            do_sql_order(sql_str,db_name1)    
            #x.fillna(-1,inplace=True)
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('%s已经更新至%s' % (info,t2))
        os.remove(sub_fn)         

sub_id = 41
# 'MktIborGet_adair' 银行间同业拆借利率
if len(fns_data[sub_id])>0:
    info = '银行间同业拆借利率'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str,'holdingTicker':str})
        tn = 'MktIborGet_S53'
        if len(x)>0:
            t0 = x.tradeDate.astype(str).min()
            t2 = x.tradeDate.astype(str).max()        
            sql_str = 'delete from %s where tradeDate>="%s"' % (tn,t0)
            do_sql_order(sql_str,db_name1)    
            #x.fillna(-1,inplace=True)
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('%s已经更新至%s' % (info,t2))
        os.remove(sub_fn) 

sub_id = 42
# EcoDataProGet 信用利差
if len(fns_data[sub_id])>0:
    info = '信用利差'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'indicID':str})
        tn = 'EcoDataProGet_S53'
        if len(x)>0:
            indicID = x.indicID.unique()
            for sub_indicID in indicID:
                t0 = x[x.indicID==sub_indicID].periodDate.astype(str).min()
                t2 = x[x.indicID==sub_indicID].periodDate.astype(str).max()        
                sql_str = 'delete from %s where indicID="%s" and periodDate>="%s"' % (tn,sub_indicID,t0)
                do_sql_order(sql_str,db_name1)    
                #x.fillna(-1,inplace=True)
                x[x.indicID==sub_indicID].to_sql(tn,engine,if_exists='append',
                                 index=False,chunksize=3000)
                print('%s %s 已经更新至%s' % (info,sub_indicID,t2))
        os.remove(sub_fn) 

sub_id = 43
# 上市公司特殊状态变化
if len(fns_data[sub_id])>0:
    info = '上市公司特殊状态变化'
    for sub_fn in fns_data[sub_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        tn = 'EquInstSstateGet_S53'
        if len(x)>0:
            t0 = x.effDate.astype(str).min()
            t2 = x.effDate.astype(str).max()        
            sql_str = 'delete from %s where effDate>="%s"' % (tn,t0)
            do_sql_order(sql_str,db_name1)    
            #x.fillna(-1,inplace=True)
            x.to_sql(tn,engine,if_exists='append',index=False,chunksize=3000)
            print('%s已经更新至%s' % (info,t2))
        os.remove(sub_fn)         

#每日 填充 行情
data_id=44
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        if len(x)==0:
            continue
        tn1 = 'MktEqudGet0S53'
        sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine)
        if len(t)>0:
            t0 = str(t[t.columns[0]].values[0])
        else:
            t0 = '1990-01-01'
        x2 = x.loc[x.tradeDate>str(t0)]
        if not x2.empty:
            x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('每日 填充 行情数据更新至%s' % x2.tradeDate.max())
        else:
            print('每日 填充 行情数据已经是最新的%s，无需更新' % t0)
        os.remove(sub_fn)

#每日后复权 填充行情
data_id=45
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        if len(x)==0:
            continue
        tn1 = 'MktEqudAdjAfGetF0S53'
        sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine)
        if len(t)>0:
            t0 = str(t[t.columns[0]].values[0])
        else:
            t0 = '1990-01-01'
        x2 = x.loc[x.tradeDate>str(t0)]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('每日后复权 填充行情更新至%s' % x2.tradeDate.max())
        else:
            print('每日后复权 填充行情已经是最新的%s，无需更新' % t0)
        os.remove(sub_fn)

data_id=46
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        if len(x)==0:
            continue
        tn1 = 'MktEqudAdjAfGetF1S53'
        sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine)
        if len(t)>0:
            t0 = str(t[t.columns[0]].values[0])
        else:
            t0 = '1990-01-01'
        x2 = x.loc[x.tradeDate>str(t0)]
        if not x2.empty:
            #x2.rename(columns={'ticker':'symbol'},inplace=True)
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('每日后复权 重下数据20200824 更新至%s' % x2.tradeDate.max())
        else:
            print('每日后复权 重下数据20200824 已经是最新的%s，无需更新' % t0)
        os.remove(sub_fn)

data_id=47
info = '个股日资金流向'
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        if len(x)==0:
            continue
        tn1 = 'MktEquFlowGetS56'
        sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine)
        if len(t)>0:
            t0 = str(t[t.columns[0]].values[0])
        else:
            t0 = '1990-01-01'
        x2 = x.loc[x.tradeDate>str(t0)]
        if not x2.empty:
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('%s 更新至%s' % (info,x2.tradeDate.max()))
        else:
            print('%s 已经是最新的%s，无需更新' % (info,t0))
        os.remove(sub_fn)

data_id=48
info = '沪深港通持股记录'
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str,'ticketCode':str})
        if len(x)==0:
            continue
        tn1 = 'HKshszHoldGetS56'
        sql_str1 = 'select endDate from %s order by endDate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine)
        if len(t)>0:
            t0 = str(t[t.columns[0]].values[0])
        else:
            t0 = '1990-01-01'
        x2 = x.loc[x.endDate>str(t0)]
        if not x2.empty:
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('%s 更新至%s' % (info,x2.endDate.max()))
        else:
            print('%s 已经是最新的%s，无需更新' % (info,t0))
        os.remove(sub_fn)

data_id = 49
info = '沪深融资融券每日交易明细信息'
if len(fns_data[data_id])>0:
    for sub_fn in fns_data[data_id]:
        x = pd.read_csv(sub_fn,dtype={'ticker':str})
        if len(x)==0:
            continue
        tn1 = 'FstDetailGetS56'
        sql_str1 = 'select tradedate from %s order by tradedate desc limit 1' % tn1
        t = pd.read_sql(sql_str1,engine)
        if len(t)>0:
            t0 = str(t[t.columns[0]].values[0])
        else:
            t0 = '1990-01-01'
        x2 = x.loc[x.tradeDate>str(t0)]
        if not x2.empty:
            x2.to_sql(tn1,engine,if_exists='append',index=False,chunksize=3000)
            print('%s 更新至%s' % (info,x2.tradeDate.max()))
        else:
            print('%s 已经是最新的%s，无需更新' % (info,t0))
        os.remove(sub_fn)
        
do_update=1
if do_update==1:      
    #更新通达信数据
    write_ICFT_min()
    write_index_min()
    write_tdx_fenbicj()
    write_ETF_min()
    #更新akshare数据
    update_bond_china_yield()
    update_future_rank_table()
    #runfile('M_yq_finance_update.py')
    #所有国内期货分钟数据
    update_future_minute_data()
    #爬取sina指数数据
    update_us_index()
    #us akshare S54 related
    update_usforex()


