#import python libraries
import pandas as pd #pandas is equivalent to dpylr
import numpy as np #numerical methods
import os #file system manipulation
import requests as rq #
import zipfile as zf
import pickle
from tqdm import tqdm

input_data = 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip';


#Create a data directory if it doesn't already exist (don't give an error if it does)
os.makedirs("data", exist_ok=True)

#Platform-independent code for specifying where the raw downloaded data will go
download_path = os.path.join("data", "tempdata.zip")

#Download the file from the location specified by the input_data variable
#as per https://stackoverflow.com/a/37573701/945039.  Will make a custom progress
#bar to track the download progress.
request = rq.get(input_data, stream = True)
size_in_bytes = request.headers.get('content-length',0)
block_size = 1024
progress_bar = tqdm(total=int(size_in_bytes), unit='iB', unit_scale = True)
#make a loop to update the progress bar. wb means with bytes, len is length, 
#file is not part of the language it is a temporary things with property write
"""Save the downloaded file to the data directory
... but the concise less readable way to do the same thing is:
open(Zipped_Data, 'wb').write(requests.get(Input_data))"""
with open(download_path, "wb") as file: 
  for data in request.iter_content(block_size):
    progress_bar.update(len(data))
    file.write(data)
progress_bar.close()    

#assertions are used in code to throw an error early in a process to avoid spending 
#more time in something that is expected to fail.
assert progress_bar.n==int(size_in_bytes),'Download incomplete'

to_unzip = zf.ZipFile(download_path)

#if it is an R vector it is a Python list.  R list is Python dictionary. 3==[3] in
#R these are equivalent, in python they are not. In R a vector is one dimensional.
#in python you can put vectors in vectors. ex: [1, 2, 3, 4, 5, ['a', 'b', 'c']]
#the attribute ~ data the method is ~ the function. If you want 4th item put 3 in brackets
#this is called zero indexing. Note some things are static might see them wrapped in parenthesis
#colon starts a loop and empty spaces for indentation means the indented lines belong to above
#use the os.path.split.  We need dd to be a dictionary meaning each value has an assigned name.

"""Unzip and read the downloaded data into a dictionary named dd
full names of all files in the zip
look for only the files ending in csv.gz
when found, create names based on the stripped down file names and
assign to each one the corresponding data frame which will be uncompressed
as it is read. The low_memory argument is to avoid a warning about mixed data types"""
dd = {}
for ii in to_unzip.namelist():
  if ii.endswith("csv.gz"):
    dd[os.path.split(ii)[1].replace(".csv.gz", "")] = pd.read_csv(to_unzip.open(ii), compression = 'gzip', low_memory = False) 
    
dd.keys() #returns the names 

#Use pickle to save the processed data
pickle.dump(dd,file=open('data.pickle','wb'));
