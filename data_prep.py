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
