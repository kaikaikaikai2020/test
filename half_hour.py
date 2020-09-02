import pandas as pd
import numpy as np
import os
import datetime
import matplotlib.pyplot as plt

# %%
os.listdir('./data')


def read_data(path):
    df = pd.read_csv(path, encoding='gbk', header=2)
    cols = ['time', 'open', 'close']
    df = df[cols]
    df['time'] = pd.to_datetime(df['time'])
    df.fillna(method='bfill', inplace=True)
    return df


def get_half_hour_ret(df, begin_time=datetime.time(9, 30)):
    date_time = datetime.datetime.combine(datetime.date.today(), begin_time)
    time_delta = datetime.timedelta(minutes=30)
    end_time = (time_delta + date_time).time()
    day_sig = (df['min_time'] > begin_time) & (df['min_time'] <= end_time)
    sub_df = df[day_sig]
    return sub_df.groupby('date')['close'].apply(lambda x: x.iloc[-1] / x.iloc[0] - 1)


# %% 此处可以更改不同的指数， 可改为'./data/50.csv'等
df = read_data('./data/300.csv')
df['date'] = df['time'].apply(lambda x: x.date())
df['min_time'] = df['time'].apply(lambda x: x.time())

# %% 时间列表
time_list = []
names = []
flag = True
for hour in [9, 10, 11, 13, 14]:
    for min in [0, 30]:
        if hour == 9 and min == 0:
            flag = False
        if hour == 11 and min == 30:
            flag = False
        if flag:
            beg_time = datetime.time(hour, min)
            time_list.append(beg_time)
            names.append('%s-%s'%(hour, min))
        flag = True

# %%
df_time_ret = pd.concat([get_half_hour_ret(df, beg_time)
                         for beg_time in time_list], axis = 1)

df_time_ret.columns = names

# %% 研报结论图 对应 图20 与 图24 基本复现
sig_1 = df_time_ret['9-30'].apply(lambda x: 1 if x > 0 else -1)
(df_time_ret['14-30'] * sig_1 + 1).cumprod().plot(title = '9-30 and 14-30')
plt.show()

# %%
sig_2 = df_time_ret['14-0'].apply(lambda x: 1 if x > 0 else -1)
(df_time_ret['14-30'] * sig_2 + 1).cumprod().plot(title = '14-0 and 14-30')
plt.show()