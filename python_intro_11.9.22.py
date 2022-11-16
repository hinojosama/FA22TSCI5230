#import python libraries
import pandas as pd #pandas is equivalent to dpylr
import numpy as np #numerical methods
import os #file system manipulation
import requests as rq #
import zipfile as zf
import pickle as pk
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
with open(download_path, "wb") as file: 
  for data in request.iter_content(block_size):
    progress_bar.update(len(data))
    file.write(data)
progress_bar.close()    
    
Save the downloaded file to the data directory
... but the concise less readable way to do the same thing is:
open(Zipped_Data, 'wb').write(requests.get(Input_data))
Unzip and read the downloaded data into a dictionary named dd
full names of all files in the zip
look for only the files ending in csv.gz
when found, create names based on the stripped down file names and
assign to each one the corresponding data frame which will be uncompressed
as it is read. The low_memory argument is to avoid a warning about mixed data types
Use pickle to save the processed data

