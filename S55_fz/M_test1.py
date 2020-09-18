# -*- coding: utf-8 -*-
"""
Created on Thu Sep 17 20:02:35 2020

@author: adair2019
"""

from yq_toolsS45 import save_pickle,get_file_name

import os
datadir='dataset_uqer'
if not os.path.exists(datadir):
    os.makedirs(datadir)
    
x = get_file_name(datadir,'.csv') 
save_pickle('testdata1.pkl',x)