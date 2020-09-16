
# coding: utf-8

# In[ ]:

#import toolkits
#toolkits.delete_files(list_files())

from yq_toolsS45 import time_use_tool
import uqer
from uqer import DataAPI
from multiprocessing.dummy import Pool as ThreadPool
import multiprocessing
import os
num_core = min(multiprocessing.cpu_count()*10,99)
client = uqer.Client(token='34e1248d676e3552680ef30cef925928c5147dba193bcb54ef70ddc4bd67daaa')
datadir='dataset_uqer'
if not os.path.exists(datadir):
    os.makedirs(datadir)
"""
历史数据爬取
"""
#清空 zip 保留csv
#import toolkits
import os
def list_files():
    return os.listdir()
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
import zipfile
import pandas as pd
import time
import datetime
import numpy as np 
   
def save_data_adair(fn_d1,x,fn_d2=None):
    if fn_d2 is None:
        fn_d2 = fn_d1
    fn1_d1 =os.path.join(datadir, '%s.csv' % fn_d1)
    #fn2_d1 = '%s.zip' % fn_d2
    x.to_csv(fn1_d1,index=False)
    #z=zipfile.ZipFile(fn2_d1,'a',zipfile.ZIP_DEFLATED)
    #z.write(fn1_d1)
    #z.close()
    #toolkits.delete_files([fn1_d1])
    
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


def get_databy_day(t0):
    sub_clock = time_use_tool()
    t0_f2 = datetime.datetime.strptime(t0, '%Y%m%d').strftime('%Y-%m-%d')
    tt = t0
    t0_0 = t0_f2
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
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            x=DataAPI.MktEqudGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0,endDate=tt,isOpen=1,field=u"",pandas="1") 
            x.drop(['secID','secShortName','exchangeCD','vwap','isOpen'],axis=1, inplace=True)

            save_data_adair(fn_d2,x,'MktEqudGet')
            print('正股日数据已经更新到%s' % fn2_d2) 
        else:
            print('%s已经存在，正股日数据已经更新，未执行' % fn2_d2) 
        #3 指数日行情
        t= get_tradingdate_adair(tt)
        fn_d3 = 'indicator_data%s' % tt
        fn1_d3 = '%s.csv' % fn_d3
        fn2_d3=  '%s.zip' % fn_d3
        t0_f1 = '%s-%s-%s' % (t0[0:4],t0[4:6],t0[6:])
        tt_f1 = '%s-%s-%s' % (tt[0:4],tt[4:6],tt[6:])
        t=t[t>=t0_f1]
        t=t[t<=tt_f1]
        if fn2_d3 not in list_files():
            i=0
            for sub_t in t:
                x=DataAPI.MktIdxdGet(indexID=u"",ticker=u"",tradeDate=sub_t,beginDate=u"",
                                     endDate=u"",exchangeCD=u"XSHE,XSHG",field=u"",pandas="1")
                if i==0:
                    re=x
                else:
                    re = re.append(x)
                i = i +1
                if i%3 ==0:
                    print('%d-%s' % (i,sub_t))
            test_v = 0;
            if len(t)>0:
                if len(re)>0:
                    save_data_adair(fn_d3,re,'MktIdxdGet')
                    test_v = test_v+1
            if test_v>0:
                print('指数日数据已经更新到%s' % fn2_d3) 
            else:
                print('指数日数据没有更新')
        else:
            print('%s已经存在，指数日数据已经更新，未执行' % fn2_d3) 

        #4交易日期更新
        fn_d4= 'tradingdate%s' % tt
        fn1_d4 = '%s.csv' % fn_d4
        fn2_d4 = '%s.zip' % fn_d4

        if fn2_d4 not in list_files():
            tt2 = (datetime.datetime.now()+datetime.timedelta(days=5)).strftime("%Y-%m-%d")
            x = get_tradingdate_adair(tt2)
            x = pd.DataFrame({'tradingdate':x})
            save_data_adair(fn_d4,x,'get_tradingdate_adair')
            print('交易日数据已经更新到%s' % fn2_d2) 
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2) 

    #ST标记
    def update_st_data():   
        fn_d2 = 'st_data%s' % tt
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.SecSTGet(beginDate=t0,endDate=tt,secID=u"",ticker=z1,field=['ticker','tradeDate','STflg'],pandas="1")
            save_data_adair(fn_d2,x,'SecSTGet')
            print('st交易日数据已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)    

    #后复权月度行情
    def get_month_data():    
        fn_d2 = 'MktEqumAdjAfGet%s' % tt
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.MktEqumAdjAfGet(secID=u"",ticker=z1,monthEndDate=u"",beginDate=t0,
                                      endDate=tt,isOpen=u"",field=u"",pandas="1")
            save_data_adair(fn_d2,x,'MktEqumAdjAfGet')
            print('后复权月度行情已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)   
    #股票基本信息
    def get_symbol_basic_info():     
        fn_d2 = 'EquGet%s' % tt
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            x = DataAPI.EquGet(secID=u"",ticker=u"",equTypeCD=u"A",listStatusCD=u"",
                       exchangeCD="",ListSectorCD=u"",field=u"",pandas="1")   
            save_data_adair(fn_d2,x,'EquGet')
            print('股票基本信息已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，股票基本信息已经更新，未执行' % fn2_d2) 

    #申万获取行业
    def get_industry_data_adair():    
        fn_d2 = 'EquIndustryGet%s' % tt
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            x =DataAPI.EquIndustryGet(secID=u"",ticker=u"",
                                  industryVersionCD=u"010303",industry=u"",industryID=u"",industryID1=u"",industryID2=u"",
                                  industryID3=u"",intoDate=u"",equTypeID=u"",field=u"",pandas="1")  
            save_data_adair(fn_d2,x,'EquIndustryGet')
            print('申万获取行业信息已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，申万获取行业信息已经更新，未执行' % fn2_d2) 
    #获取后复权因子
    #DataAPI.MktEqudAdjAfGet(secID=u"",ticker=u"688001",tradeDate=u"",beginDate=u"20190801",endDate=u"20190805",isOpen="",field=u"",pandas="1")
    def MktEqudAdjAfGet():
        fn_d2 = 'MktEqudAdjAfGet_data%s' % tt
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            t= get_tradingdate_adair(tt)
            #t0_f1 = t0
            #tt_f1 = tt
            t0_f1 = '%s-%s-%s' % (t0[0:4],t0[4:6],t0[6:])
            tt_f1 = '%s-%s-%s' % (tt[0:4],tt[4:6],tt[6:])
            t=t[t>=t0_f1]
            t=t[t<=tt_f1]
            i = 0
            #z_fn=zipfile.ZipFile(fn2_d2,'w',zipfile.ZIP_DEFLATED)
            for sub_t in t:
                sub_x=DataAPI.MktEqudAdjAfGet(secID=u"",ticker=z1,tradeDate=sub_t,beginDate=u"",endDate=u"",
                                          isOpen=1,field=u"",pandas="1") 
                #sub_fn = 'MktEqudAdjAfGet_data%s.csv' % sub_t
                #sub_x.to_csv(sub_fn,index=False)
                #z_fn.write(sub_fn)
                #toolkits.delete_files([sub_fn])

                sub_fn = 'MktEqudAdjAfGet_data%s' % sub_t
                save_data_adair(sub_fn,sub_x,'MktEqudAdjAfGet')

                #if i==0:
                #    x = sub_x
                #else:
                #    x = x.append(x)
                i = i +1
                if np.mod(i,20)==0:
                    print(sub_t)
            #z_fn.close()

            #save_data_adair(fn_d2,x)
            #return x
            print('后复权因子数据已经更新到%s' % fn2_d2) 
        else:
            #return None
            print('%s已经存在，后复权因子数据已经更新，未执行' % fn2_d2) 

    #DataAPI.IdxCloseWeightGet(secID=u"",ticker=u"000300",beginDate=u"20151101",endDate=u"20151130",field=u"",pandas="1")  指数成分股数据
    def IdxCloseWeightGet_adair(): 
        fn_d2 = 'IdxCloseWeightGet%s' % tt
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2=  '%s.zip' % fn_d2
        tickercode = ['000001','000002','000003','000004','000005','000006','000007','000008','000009','000010','000011','000012','000013','000015',
                      '000016','000020','000090','000132','000133','000300','000852','000902','000903','000904','000905','000906','000907','000922',
                      '399001','399002','399004','399005','399006','399007','399008','399009','399010','399011','399012','399013','399015','399107',
                      '399108','399301','399302','399306','399307','399324','399330','399333','399400','399401','399649','000985']
        #z_fn=zipfile.ZipFile(fn2_d2,'w',zipfile.ZIP_DEFLATED)
        x=[]
        for i,sub_ticker in enumerate(tickercode):
            sub_x=DataAPI.IdxCloseWeightGet(secID=u"",ticker=sub_ticker,beginDate=t0,endDate=tt,field=u"effDate,ticker,consTickerSymbol,weight",pandas="1")
            x.append(sub_x)
            #sub_fn = 'IdxCloseWeightGet%s.csv' % sub_ticker
            #sub_x.to_csv(sub_fn,index=False)
            #z_fn.write(sub_fn)
            #toolkits.delete_files([sub_fn])
            print('%d-%s' % (i,sub_ticker))
        #z_fn.close()
        x=pd.concat(x)
        save_data_adair(fn_d2,x,'IdxCloseWeightGet')

    #指数月度行情
    def MktIdxmGet_adair():
        fn_d2 = 'MktIdxmGet%s' % tt
        x=DataAPI.MktIdxmGet(beginDate=t0,endDate=tt,indexID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktIdxmGet')
    #S26 10因子表
    #DataAPI.MktStockFactorsOneDayGet(tradeDate=u"20150227",secID=u"",ticker=u"000001,600000",field=u"",pandas="1")
    def get_MktStockFactorsOneDayGet_S26():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'MktStockFactorsOneDayGet_S26_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = 'Factor Data'
        key_str = u"ticker,tradeDate,HBETA,RSTR24,MLEV,FEARNG,EGRO,VOL20,VOL60,VOL240,Volatility,LCAP"
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                sub_t = sub_t.replace('-','')
                sub_x=DataAPI.MktStockFactorsOneDayGet(tradeDate=sub_t,secID=u"",ticker=z1,field=key_str,pandas="1")
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_MktStockFactorsOneDayGet_S26')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None

    #S26 10因子表 added
    #DataAPI.MktStockFactorsOneDayGet(tradeDate=u"20150227",secID=u"",ticker=u"000001,600000",field=u"",pandas="1")
    def get_MktStockFactorsOneDayGet_add_S26():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'MktStockFactorsOneDayGet_add_S26_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = 'Factor Data_add'
        key_str = u"ticker,tradeDate,GrossIncomeRatio,OperCashInToCurrentLiability,InventoryTRate"
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                sub_t = sub_t.replace('-','')
                sub_x=DataAPI.MktStockFactorsOneDayGet(tradeDate=sub_t,secID=u"",ticker=z1,field=key_str,pandas="1")
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_MktStockFactorsOneDayGet_add_S26')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None

    #S19 补充因子表 因子数据前退一个交易日
    #DataAPI.MktStockFactorsOneDayGet(tradeDate=u"20150227",secID=u"",ticker=u"000001,600000",field=u"",pandas="1")
    def get_S19_factors_added():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'get_S19_factors_added_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = 'get_S19_factors_added'
        key_str = u"ticker,tradeDate,PS,PCF,NetProfitGrowRate,GrossIncomeRatio,EquityToAsset,BLEV,CashToCurrentLiability,CurrentRatio,Skewness"
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                sub_t = sub_t.replace('-','')
                sub_x=DataAPI.MktStockFactorsOneDayGet(tradeDate=sub_t,secID=u"",ticker=z1,field=key_str,pandas="1")
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_S19_factors_added')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None

    #获取所有因子数据 S45 added
    def get_MktStockFactorsOneDayGet_full():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'MktStockFactorsOneDayGet_re_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = 'MktStockFactorsOneDayGet_full'
        key_str = u""
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                sub_t = sub_t.replace('-','')
                sub_x=DataAPI.MktStockFactorsOneDayGet(tradeDate=sub_t,secID=u"",ticker=z1,field=key_str,pandas="1")
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_MktStockFactorsOneDayGet_full')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None
    """
    tref = tref[tref>t0_f2]

    for i,sub_t in enumerate(tref[0:max_num]):
        sub_t_f1 = datetime.datetime.strptime(sub_t, '%Y-%m-%d').strftime('%Y%m%d')
        x = DataAPI.MktStockFactorsOneDayGet(tradeDate=sub_t,secID=u"",ticker=u"",field=u"",pandas="1")
        fn_d1='MktStockFactorsOneDayGet_re%s' % sub_t_f1
        save_data_adair(fn_d1,x)
        print('%s %d-%d' %(sub_t,i,max_num))

    compress_all_zip_data( 'all_re%s.zip' % fn_d1 )   

    """    

    #S19数据立方替代表 因子数据都前退一个交易日
    def get_S19_factors_datacub():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'get_S19_factors_datacub_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = 'get_S19_factors_datacub'
        key_str = u"ticker,tradeDate,DAREC,DAREV,DASREV,EquityToAsset,GREC,GREV,GSREV,Skewness,EPS"
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                sub_t = sub_t.replace('-','')
                sub_x=DataAPI.MktStockFactorsOneDayGet(tradeDate=sub_t,secID=u"",ticker=z1,field=key_str,pandas="1")
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_S19_factors_datacub')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None
    #S13
    #基金日行情
    def MktFunddget_adair():   
        info='基金日行情'
        fn_d2 = 'MktFunddget_adair%s' % tt
        x=DataAPI.MktFunddGet(secID=u"",ticker=u"",tradeDate=u"",beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFunddget_adair')
        print('%s已经更新到%s' % (info,fn_d2))  
    #x=DataAPI.MktMFutdGet(mainCon=u"",contractMark=u"",contractObject=u"",tradeDate=u"20191231",startDate=u"",endDate=u"",field=u"",pandas="1")
    #期货主力、连续合约日行情 
    def MktMFutdGet_adair():
        info='期货主力、连续合约日行情'
        fn_d2 = 'MktMFutdGet_adair%s' % tt
        x=DataAPI.MktMFutdGet(mainCon=u"",contractMark=u"",contractObject=u"",tradeDate=u"",startDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktMFutdGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))  
    #期货期货会员成交量排名 x = DataAPI.MktFutMTRGet(beginDate=sub_tref[0],endDate=sub_tref[-1],secID=u"",ticker=u"",field=u"",pandas="1")
    def MktFutMTRGet_adair():
        info='期货期货会员成交量排名'
        fn_d2 = 'MktFutMTRGet_adair%s' % tt
        x= DataAPI.MktFutMTRGet(beginDate=t0,endDate=tt,secID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutMTRGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))  

    #期货期货会员空头持仓排名 x = DataAPI.MktFutMSRGet(beginDate=sub_tref[0],endDate=sub_tref[-1],secID=u"",ticker=u"",field=u"",pandas="1")
    def MktFutMSRGet_adair():
        info='期货期货会员空头持仓排名'
        fn_d2 = 'MktFutMSRGet_adair%s' % tt
        x= DataAPI.MktFutMSRGet(beginDate=t0,endDate=tt,secID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutMSRGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))  

    #期货期货会员多头持仓排名 x = DataAPI.MktFutMLRGet(beginDate=sub_tref[0],endDate=sub_tref[-1],secID=u"",ticker=u"",field=u"",pandas="1")
    def MktFutMLRGet_adair():
        info='期货期货会员空头持仓排名'
        fn_d2 = 'MktFutMLRGet_adair%s' % tt
        x= DataAPI.MktFutMLRGet(beginDate=t0,endDate=tt,secID=u"",ticker=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutMLRGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))
    #期货合约信息 
    def FutuGet_adair():
        info = '期货合约信息'
        fn_d2 = 'FutuGet_adair%s' % tt
        x=DataAPI.FutuGet(secID=u"",ticker=u"",exchangeCD=u"",contractStatus="",contractObject=u"",field=u"",pandas="1")
        x.drop(['deliGrade','deliPriceMethod','settPriceMethod'],axis=1,inplace=True)
        save_data_adair(fn_d2,x,'FutuGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))

    #期货仓单日报
    def MktFutWRdGet_adair():
        info='期货仓单日报'
        fn_d2 = 'MktFutWRdGet_adair%s' % tt
        x= DataAPI.MktFutWRdGet(beginDate=t0,endDate=tt,contractObject=u"",exchangeCD=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktFutWRdGet_adair')
        print('%s已经更新到%s' % (info,fn_d2))    
    #可转债市场表现
    def MktConsBondPerfGet_adair():    
        fn_d1= 'MktConsBondPerfGet_adair%s' % tt
        fn2_d1 = '%s.zip' % fn_d1
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
        x= DataAPI.MktIdxdEvalGet(secID=u"",ticker=u"000922",beginDate=t0,endDate=tt,PEType=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'MktIdxdEvalGet_adair')
        print('%s已经更新到%s' % (info,fn_d2)) 

    #S31
    #ETF基金申赎清单成分券信息
    def FundETFConsGet_adair():
        x=DataAPI.FundETFConsGet(secID=u"",ticker=['510050','510300','510500'],beginDate=t0,endDate=tt,field=u"",pandas="1")
        fn='FundETFConsGet_adair %s' % tt
        save_data_adair(fn,x,'FundETFConsGet_adair')

    def FundETFPRListGet_adair():
        x = pd.DataFrame()
        for sub_code in ['510050','510300','510500']:
            sub_x=DataAPI.FundETFPRListGet(secID=u"",ticker=sub_code,beginDate=t0,endDate=tt,field=u"",pandas="1")
            x = x.append(sub_x)
        fn='FundETFPRListGet_adair%s' % tt
        save_data_adair(fn,x,'FundETFPRListGet_adair')
    #后复权周度行情
    def get_ticker_week_data():    
        fn_d2 = 'MktEquwAdjAfGet%s' % tt
        fn2_d2=  '%s.zip' % fn_d2
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
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            x=DataAPI.MktIdxwGet(beginDate=t0,endDate=tt,indexID=u"",ticker=u"",field=u"",pandas="1")
            save_data_adair(fn_d2,x,'get_index_week_data')
            print('后复权周度行情已经更新到%s' % fn_d2)
        else:
            print('%s已经存在，交易日数据已经更新，未执行' % fn2_d2)   
    #日历数据下载 S45 added
    def get_TradeCalGet():
        fn_d2 = 'yuqer_cal%s' % tt
        x=DataAPI.TradeCalGet(exchangeCD=u"XSHG,XSHE",beginDate=u"",endDate=tt,isOpen=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'get_TradeCalGet')
        print('交易日数据已更新%s' % fn_d2)

    #S46 贴吧数据 
    def get_SocialDataGubaGet():
        fn_d2 = 'SocialDataGubaGet_data%s' % tt
        x=DataAPI.SocialDataGubaGet(ticker=u"",beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair(fn_d2,x,'get_SocialDataGubaGet')
        print('贴吧数据已更新%s' % fn_d2)

    #S49 申万行业回填（含科创板）sw_fields= ['secID','ticker','secShortName','oldTypeName','intoDate','outDate','isNew','industryName1']
    #    stock_indus_info = DataAPI.MdSwBackGet(secID=u"",ticker=u"",intoDate=u"",outDate=u"",field=u"",pandas="1")
    def get_MdSwBackGet():
        fn_d2 = 'MdSwBackGet_data%s' % tt
        x=DataAPI.MdSwBackGet(secID=u"",ticker=u"",intoDate=u"",outDate=u"",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'get_MdSwBackGet')
        print('申万行业回填（含科创板）%s' % fn_d2)

    #S51 基金基本信息
    def get_FundGet():
        fn_d2 = 'FundGet_S51%s' % tt
        x=[]
        fields = ['secID', 'ticker', 'secShortName', 'tradeAbbrName', 'category',
               'operationMode', 'indexFund', 'etfLof', 'isQdii', 'isFof', 'isGuarFund',
               'guarPeriod', 'guarRatio', 'exchangeCd', 'listStatusCd', 'managerName',
               'status', 'establishDate', 'listDate', 'delistDate', 'expireDate',
               'managementCompany', 'managementFullName', 'custodian',
               'custodianFullName',  'perfBenchmark',
               'circulationShares', 'isClass', 'idxID', 'idxTicker', 'idxShortName',
               'managementShortName', 'custodianShortName']
        for t in ['E','H','B','SB','M','O']:
            temp = DataAPI.FundGet(secID=u"",ticker=u"",etfLof=u"",listStatusCd=u"",category=t,idxID=u"",idxTicker=u"",operationMode=u"",beginDate=u"",endDate=u"",status="",field=fields,pandas="1")
            x.append(temp)
            print(t)
        y=pd.concat(x)
        save_data_adair(fn_d2,y,'get_FundGet')

    #基金资产配置
    def get_FundAssetsGet():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'yq_FundAssetsGet_S51_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = '基金资产配置'
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                #sub_t = sub_t.replace('-','')
                sub_x=DataAPI.FundAssetsGet(secID=u"",ticker=u"",reportDate=u"",updateTime=sub_t,beginDate=u"",endDate=u"",field=u"",pandas="1") 
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_FundAssetsGet')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None
    #基金历史净值(货币型,短期理财债券型除外)
    def get_FundNavGet():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'FundNavGet_S51_%s' % sub_tt
        fn1_d1 = '%s.csv' % fn_d1
        fn2_d1 = '%s.zip' % fn_d1
        info = '基金历史净值(货币型,短期理财债券型除外)'
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        i = 0
        if fn2_d1 not in list_files():
            x = pd.DataFrame()
            for sub_t in t:
                #sub_t = sub_t.replace('-','')
                sub_x=DataAPI.FundNavGet(secID=u"",ticker=u"",dataDate=sub_t,beginDate=u"",endDate=u"",partyID="",partyShortName="",field=u"",pandas="1")
                x=pd.concat([x,sub_x])
                i = i +1
                if np.mod(i,7)==0:
                    print('complete:%s' % sub_t)
            save_data_adair(fn_d1,x,'get_FundNavGet')
            print('%s已经更新到%s' % (info,fn2_d1))  
            return x
        else:
            print('%s已经存在，%s数据已经更新，未执行' % (fn2_d1,info)) 
            return None

    #CME期货日行情
    def get_MktCmeFutdGet():
        fn_d2 = 'MktCmeFutdGet_S50%s' % tt
        field = """ticker,tradeDate,deliYear,deliMonth,contractObject,preSettlePrice,preOpenInt,openPrice,highestPrice,highestPriceSide,lowestPrice,lowestPriceSide,closePrice,closePriceSide,settlePrice,chg,turnoverVol"""
        x=DataAPI.MktCmeFutdGet(ticker=u"",tradeDate=u"",beginDate=t0,endDate=tt,contractObject=u"",field=field,pandas="1")
        #x=DataAPI.FundHoldingsGet(secID=secID,ticker=u"",reportDate=u"",beginDate=t0,endDate=tt,secType="",holdingTicker="",holdingSecID="",field=u"",pandas="1")
        save_data_adair(fn_d2,x,'get_MktCmeFutdGet')
        print('CME期货日行情%s' % fn_d2)    

    #银行间同业拆借利率
    def MktIborGet_adair():
        sub_t0 = datetime.datetime.strptime(t0_0, '%Y-%m-%d').strftime('%Y-%m-%d')
        sub_tt = datetime.datetime.strptime(tt, '%Y%m%d').strftime('%Y-%m-%d')
        fn_d1= 'MktIborGet_adair_%s' % sub_tt
        fn2_d1 = '%s.zip' % fn_d1
        info = '银行间同业拆借利率'
        key_str = u""
        t = get_tradingdate_adair(tt)
        t = t[np.logical_and(t>=sub_t0,t<=sub_tt)]
        t = t.tolist()
        x=[]
        for i in t:
            x.append(DataAPI.MktIborGet(secID=u"",ticker=u"",tradeDate=i.replace('-',''),beginDate=u"",endDate=u"",currency=u"",field=u"",pandas="1"))
            print('complete %s' % i)
        x=pd.concat(x)
        save_data_adair(fn_d1,x,'MktIborGet_adair')
        print('%s已经更新到%s' % (info,fn2_d1))  
    # S53 上市公司特殊状态
    def EquInstSstateGet_adair():
        x=DataAPI.EquInstSstateGet(secID=u"",ticker=z1,beginDate=t0,endDate=tt,field=u"",pandas="1")
        save_data_adair('EquInstSstateGet%s' % tt,x,'EquInstSstateGet_adair')
    #S53 每日行情填充数据
    def get_MktEqudGet0S53():
        #x.loc[x.tradeDate>='2019-12-01']
        #2 股票日行情
        #股票日行情 半年
        key_str = '正股 filling 日数据'
        fn_d2 = 'MktEqudGet0S53_%s' % tt
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2=  '%s.zip' % fn_d2
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
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            t= get_tradingdate_adair(tt)
            x=DataAPI.MktEqudAdjAfGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0,endDate=tt,
                                          isOpen=0,field=u"",pandas="1") 
            save_data_adair(fn_d2,x,'MktEqudAdjAfGetF0S53')
            #return x
            print('%s已经更新到%s' % (key_str1,fn2_d2)) 
        else:
            #return None
            print('%s已经存在，%s已经更新，未执行' % (fn2_d2,key_str1)) 


    #获取后复权数据，更新(平台更新)
    def MktEqudAdjAfGetF1S53():

        key_str0 = 'MktEqudAdjAfGetF1S53'
        key_str1 ='后复权因子重新下载数据'
        fn_d2 = '%s_%s' % (key_str0,tt)
        fn1_d2 = '%s.csv' % fn_d2
        fn2_d2=  '%s.zip' % fn_d2
        if fn2_d2 not in list_files():
            z1,z=get_symbol_adair()
            t= get_tradingdate_adair(tt)
            x=DataAPI.MktEqudAdjAfGet(secID=u"",ticker=z1,tradeDate=u"",beginDate=t0,endDate=tt,
                                          isOpen="",field=u"",pandas="1") 
            save_data_adair(fn_d2,x,'MktEqudAdjAfGetF1S53')
            #return x
            print('%s已经更新到%s' % (key_str1,fn2_d2)) 
        else:
            #return None
            print('%s已经存在，%s已经更新，未执行' % (fn2_d2,key_str1)) 

    #补充停复牌数据
    def SecIDGet_adair():
        key_str0 = 'SecIDGet'
        key_str1 ='证券编码及基本上市信息'
        fn_d2 = '%s_%s' % (key_str0,tt)
        x = DataAPI.SecIDGet(assetClass=u"E",  pandas="1")
        save_data_adair(fn_d2,x,'SecIDGet')
        print('%s已经存在，%s已经更新' % (fn_d2,key_str1))
        x= DataAPI.SecHaltGet(secID=u"",ticker=u"",beginDate=u"20000101",endDate=u"",listStatusCD="",assetClass="",field=u"",pandas="1")
        save_data_adair('SecHaltGet%s' % tt,x,'SecHaltGet')
        print('停复牌数据已经更新') 
    
    #1-3
    get_ticker_data()
    #4
    update_st_data()
    #5
    get_month_data()
    #6
    #get_symbol_basic_info()
    #7
    get_industry_data_adair()
    #8获取后复权因子
    MktEqudAdjAfGet()
    #9
    IdxCloseWeightGet_adair()
    #10
    MktIdxmGet_adair()
    #11
    get_MktStockFactorsOneDayGet_add_S26()
    #12
    get_MktStockFactorsOneDayGet_S26()
    #13 S19补充因子
    get_S19_factors_added()
    #14 获取数据立方替代因子
    get_S19_factors_datacub()
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
    #21 期货合约信息 
    FutuGet_adair()
    #22期货仓单日报
    MktFutWRdGet_adair()
    #23可转债市场表现
    MktConsBondPerfGet_adair()
    #24指数估值
    MktIdxdEvalGet_adair()
    #25ETF基金申赎清单成分券信息
    FundETFConsGet_adair()
    #26ETF基金申赎清单基本信息
    FundETFPRListGet_adair()
    #27指数周行情
    get_ticker_week_data()
    #28 指数周度行情
    get_index_week_data()
    #29 因子数据
    get_MktStockFactorsOneDayGet_full()
    #30
    #get_TradeCalGet()
    #31 贴吧数据
    get_SocialDataGubaGet()
    #32 申万行业回填（含科创板）
    get_MdSwBackGet()
    #33 基金基本信息
    #get_FundGet()    
    #34 基金资产配置
    get_FundAssetsGet()
    #35 基金历史净值(货币型,短期理财债券型除外)
    get_FundNavGet()
    #36 CME期货日行情
    get_MktCmeFutdGet()
    #37 银行间同业拆借利率
    MktIborGet_adair()
    #38 每日行情填充数据
    get_MktEqudGet0S53()
    #39 后复权填充数据
    MktEqudAdjAfGetF0S53()
    #40 补充停复牌数据
    #SecIDGet_adair()
    sub_clock.use('complete %s' % t0)

t_f = '2020-09-13'
tref = get_tradingdate_adair(t_f)
#tref = tref[:3]
tref = [i.replace('-','') for i in tref]
    
pool = ThreadPool(processes=num_core)
temp = pool.map(get_databy_day, tref)
pool.close()
pool.join() 

"""
get_FundGet()
get_TradeCalGet()
SecIDGet_adair()
get_symbol_basic_info()
"""