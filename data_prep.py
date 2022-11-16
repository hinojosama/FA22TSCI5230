#import python libraries
import pandas as pd #pandas is equivalent to dpylr
import numpy as np #numerical methods
import os #file system manipulation
import pickle as pk
#from tqdm import tqdm #creates a progress bar 

#ensure the staged data exist
if not os.path.exists('data.pickle'):
  import runpy 
  runpy.run_path('data.py')

#load the staged data
dd = pickle.load(open('data.pickle', 'rb'))
dd.keys()

demographics = dd['admissions'].copy()
patients = dd['patients'].copy().drop('dod', axis = 1)

#making LOS var.  #pd is the panda package, function casting to_datetime. then suptract admit from disch time and divide
# by days using timedelta64 function specify days with D and just one day. could make it per week by 1, "W"
demographics['los'] = ((pd.to_datetime(demographics['dischtime']) - 
pd.to_datetime(demographics['admittime']))/ np.timedelta64(1, 'D'))

demographics_1 = demographics.groupby('subject_id').agg(admits= ('subject_id', 'count'),
  eth = ('ethnicity', 'nunique'),
  ethnicity_combo = ('ethnicity', lambda xx: ";".join(sorted(list(set(xx))))),
  language = ('language', 'last'),
  dod = ('deathtime', lambda xx: max(pd.to_datetime(xx))),
  los = ('los', np.median),
  num_ed = ('edregtime', lambda xx: xx.notnull().sum())).reset_index(drop = False).merge(patients, on = 'subject_id')
