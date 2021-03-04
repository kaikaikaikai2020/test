#日度框架测试
#HA配对交易
#tF '1.4.0'
import pandas as pd
import numpy as np
import MAIN.Basics as basics
import MAIN.Reinforcement as RL
import tensorflow as tf

#import seaborn as sns
import matplotlib.pyplot as plt
from UTIL import FileIO
from STRATEGY.Cointegration import EGCointegration

from yq_toolsS45 import save_pickle,read_pickle
import os
import multiprocessing
num_core = multiprocessing.cpu_count()
num_core = int(num_core/2)

pn0 = r'HA_result'
if not os.path.exists(pn0):
    os.mkdir(pn0)
# Read config
config_path  = 'CONFIG\config_train.yml'
config_train = FileIO.read_yaml(config_path)

def cal_HA_data(fn1,fn2):
    com_fn1 =os.path.join(pn0, 'bac-%s-%s.csv' % (fn1,fn2))
    com_fn2 =os.path.join(pn0, 'par-%s-%s.pkl' % (fn1,fn2))
    com_fn3 =os.path.join(pn0, 'position-%s-%s.xlsx' % (fn1,fn2))
    # Read prices
    x = pd.read_csv(r'STATICS\PRICE\%s.csv' % fn1)
    y = pd.read_csv(r'STATICS\PRICE\%s.csv' % fn2)
    x, y = EGCointegration.clean_data(x, y, 'date', 'close')
    
    # Separate training and testing sets
    train_pct = 0.5
    train_len = round(len(x) * train_pct)
    idx_train = list(range(0, train_len))
    idx_test  = list(range(train_len, len(x)))
    EG_Train = EGCointegration(x.iloc[idx_train, :], y.iloc[idx_train, :], 'date', 'close')
    EG_Test  = EGCointegration(x.iloc[idx_test,  :], y.iloc[idx_test,  :], 'date', 'close')
    
    # Create action space
    n_hist    = list(np.arange(20, 201, 20))
    n_forward = list(np.arange(20, 201, 20))
    trade_th  = list(np.arange(1,  5.1, 1))
    stop_loss = list(np.arange(1,  2.1, 0.5))
    cl        = list(np.arange(0.05,  0.11, 0.05))
    actions   = {'n_hist':    n_hist,
                 'n_forward': n_forward,
                 'trade_th':  trade_th,
                 'stop_loss': stop_loss,
                 'cl':        cl}
    n_action  = int(np.product([len(actions[key]) for key in actions.keys()]))
    
    # Create state space
    transaction_cost = [0.001]
    states  = {'transaction_cost': transaction_cost}
    n_state = len(states)
    
    # Assign state and action spaces to config
    config_train['StateSpaceState'] = states
    config_train['ActionSpaceAction'] = actions
    
    # Create and build network
    one_hot  = {'one_hot': {'func_name':  'one_hot',
                            'input_arg':  'indices',
                             'layer_para': {'indices': None,
                                            'depth': n_state}}}
    output_layer = {'final': {'func_name':  'fully_connected',
                              'input_arg':  'inputs',
                              'layer_para': {'inputs': None,
                                             'num_outputs': n_action,
                                             'biases_initializer': None,
                                             'activation_fn': tf.nn.relu,
                                             'weights_initializer': tf.ones_initializer()}}}
    
    state_in = tf.placeholder(shape=[1], dtype=tf.int32)
    
    N = basics.Network(state_in)
    N.build_layers(one_hot)
    N.add_layer_duplicates(output_layer, 1)
    
    # Create learning object and perform training
    RL_Train = RL.ContextualBandit(N, config_train, EG_Train)
    
    sess = tf.Session()
    if not os.path.exists(com_fn2):
        RL_Train.process(sess, save=False, restore=False)
        
        # Extract training results
        action = RL_Train.recorder.record['NETWORK_ACTION']
        reward = RL_Train.recorder.record['ENGINE_REWARD']
        print(np.mean(reward))
        
        df1 = pd.DataFrame()
        df1['action'] = action
        df1['reward'] = reward
        #mean_reward = df1.groupby('action').mean()
        #sns.distplot(mean_reward)
        
        # Test by trading continuously
        [opt_action] = sess.run([RL_Train.output], feed_dict=RL_Train.feed_dict)
        opt_action = np.argmax(opt_action)
        action_dict = RL_Train.action_space.convert(opt_action, 'index_to_dict')
        save_pickle(com_fn2,action_dict)
    else:
        action_dict=read_pickle(com_fn2)
    #indices = range(action_dict['n_hist'], len(EG_Test.x) - action_dict['n_forward']-1)
    
    indices = range(action_dict['n_hist'],len(EG_Test.x)-1)
    
    pnl = pd.DataFrame()
    pnl['Time'] = EG_Test.timestamp
    pnl['Trade_Profit'] = 0
    pnl['Cost'] = 0
    pnl['N_Trade'] = 0
    
    import warnings
    warnings.filterwarnings('ignore')
    
    rec_mark = []
    for i in indices:
        if i % 100 == 0:
            print(i)
        EG_Test.process(index=i, transaction_cost=0.001, **action_dict)
        trade_record = EG_Test.record
        if (trade_record is not None) and (len(trade_record) > 0):
            print('value at {}'.format(i))
            trade_record = pd.DataFrame(trade_record)
            trade_cost   = trade_record.groupby('trade_time')['trade_cost'].sum()
            close_cost   = trade_record.groupby('close_time')['close_cost'].sum()
            profit       = trade_record.groupby('close_time')['profit'].sum()
            open_pos     = trade_record.groupby('trade_time')['long_short'].sum()
            close_pos    = trade_record.groupby('close_time')['long_short'].sum() * -1
    
            pnl['Cost'].loc[pnl['Time'].isin(trade_cost.index)] += trade_cost.values
            pnl['Cost'].loc[pnl['Time'].isin(close_cost.index)] += close_cost.values
            pnl['Trade_Profit'].loc[pnl['Time'].isin(close_cost.index)] += profit.values
            pnl['N_Trade'].loc[pnl['Time'].isin(trade_cost.index)] += open_pos.values
            pnl['N_Trade'].loc[pnl['Time'].isin(close_cost.index)] += close_pos.values
            trade_record['signal_time']=EG_Test.timestamp[i]
            rec_mark.append(trade_record)
    
    rec_mark = pd.concat(rec_mark)
    warnings.filterwarnings(action='once')   
    sess.close()
    #save result
    pnl.to_csv(com_fn1)
    rec_mark.to_excel(com_fn3)
    
    pnl['PnL'] = (pnl['Trade_Profit'] - pnl['Cost']).cumsum()
    plt.figure()
    plt.plot(pnl['PnL'])
    
def do_cal(inputdata):
    fn1,fn2 = inputdata
    try:
        cal_HA_data(fn1,fn2)
    except:
        print('Error %s-%s' % (fn1,fn2))


if __name__ == '__main__':
    x=pd.read_csv('stockListHA.csv',dtype={'f1':str,'f2':str})
    for fn1,fn2 in zip(x.f1.tolist(),x.f2.tolist()):
        cal_HA_data(fn1,fn2)
    #fn1,fn2=x.f1.tolist()[0],x.f2.tolist()[0]  
    #cal_HA_data(fn1,fn2)
