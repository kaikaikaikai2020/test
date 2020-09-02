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


def get_sign_df(df):
    sub_corr = df.copy()
    sign_df = sub_corr.applymap(lambda x: np.sign(x)).stack()
    sign_df = sign_df[sign_df != 0]
    return sign_df


# %% 此处更改不同指数
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
            names.append('%s-%s' % (hour, min))
        flag = True

# %%
df_time_ret = pd.concat([get_half_hour_ret(df, beg_time)
                         for beg_time in time_list], axis=1)

df_time_ret.columns = names

# %% 利用最近三年检测
years = pd.Index([i.year for i in df_time_ret.index])
corr_dict = {}
for year in [2017, 2018, 2019]:
    sub_time_df = df_time_ret[years == year]
    sub_corr = sub_time_df.corr()
    mask = np.tril(np.ones_like(sub_corr), -1)
    sub_corr = sub_corr * mask
    corr_dict[year] = sub_corr

# %% 稳定性的测试
sign_s = [get_sign_df(corr_dict[year]) for year in [2017, 2018, 2019]]

for ind, sign_df in enumerate(sign_s):
    if ind == 0:
        sig = sign_df
    elif ind != 0:
        non_eq_ind = sig[sig != sign_df].index
        sig.loc[non_eq_ind] = 0
sig = sig[sig != 0]

# %% 选择 相关性最高 作为信号指标
for ind_flag, year in enumerate([2017, 2018, 2019]):
    sub_time_df = df_time_ret[years == year]
    sub_corr = sub_time_df.corr()
    if ind_flag == 0:
        corr_sum = sub_corr
    else:
        corr_sum += sub_corr
corr_mean = (corr_sum / 3).stack().loc[sig.index]
corr_mean = corr_mean[corr_mean.apply(np.abs) > 0.05]

# %% 生成策略
to_hour = corr_mean.index.get_level_values(0).unique()
stra_dict = {}
for hour in to_hour:
    sig_hour = corr_mean.loc[hour].apply(np.abs).idxmax()
    hour_sign = np.sign(corr_mean.loc[(hour, sig_hour)])
    stra_dict[(sig_hour, hour)] = hour_sign
print(stra_dict)

# %% 回测结果
sig_rets = []
for k, v in stra_dict.items():
    sig_hour, to_hour = k
    if v == 1:
        sig_df = df_time_ret[sig_hour].apply(lambda x: 1 if x > 0 else -1)
        sig_ret = (df_time_ret[to_hour] * sig_df)
    if v == -1:
        sig_df = df_time_ret[sig_hour].apply(lambda x: -1 if x > 0 else 1)
        sig_ret = (df_time_ret[to_hour] * sig_df)
    sig_rets.append(sig_ret)

sig_ret = pd.concat(sig_rets, axis = 1).sum(axis = 1)

# %%
(sig_ret + 1).cumprod().plot()
plt.show()