# -*- coding: utf-8 -*-
"""
Created on Thu Apr  9 17:16:03 2020

@author: adair2019
"""

# 写入数据到文件
import json
data_list = {'mysql_para':{'user_name':'root','pass_wd':'liudehua','port':3306},
             'yuqerdata_dir':r"D:\worksPool\works2020\adair2020_W\yuqerdata\data",
             'S37_dir':{'S36':'D:\worksPool\works2020\adair2020_W\some\S36\program',
                        'S34':'D:\worksPool\works2020\adair2020_W\some\S34\program_f',
                        'S33':'D:\worksPool\works2020\adair2020_W\some\S33\program',
                        'S32':'D:\worksPool\works2020\adair2020_W\some\S32\program',
                        'S31':'D:\worksPool\works2020\adair2020_W\some\S31\program',
                        'S30':'D:\worksPool\works2020\adair2020_W\some\S30\programm',
                        'S29':'D:\worksPool\works2020\adair2020_W\some\S29\program',
                        'S28':'D:\worksPool\works2020\adair2020_W\some\S28\program',
                        'S26':'D:\worksPool\works2020\adair2020_W\some\S26\program',
                        'S24':'D:\worksPool\works2020\adair2020_W\some\S24\program',
                        'S23':'D:\worksPool\works2020\adair2020_W\some\S23\program',
                        'S22':'D:\worksPool\works2020\adair2020_W\some\S22\program',
                        'S19':'D:\worksPool\works2020\adair2020_W\some\S19_machineLearning_Y\program',
                        'S17':'D:\worksPool\works2020\adair2020_W\some\S17_个股异动现象_Y\programm',
                        'S15':'D:\worksPool\works2020\adair2020_W\some\S15_大类资产轮动_Y\programm',
                        'S14':'D:\worksPool\works2020\adair2020_W\some\S14_Y\programm',
                        'S13':'D:\worksPool\works2020\adair2020_W\some\S13_Y\programmf',
                        'S11':'D:\worksPool\works2020\adair2020_W\some\S11_Y\programm',
                        'S7':'D:\worksPool\works2020\adair2020_W\some\S7_zzw\programmf',
                        'S5':'D:\worksPool\works2020\adair2020_W\some\S5_DMD_Y\programm'}}
with open('para.json','w',encoding='utf-8') as f:
  json.dump(data_list,f,ensure_ascii=False)
# 从文件读取数据
with open('para.json','r',encoding='utf-8') as f:
    para = json.load(f)
    print(para)
