#01-format-noaa-sst-2b.py
# # RUNNING on Aurora ... 
# - terminal 2 (1998-2001
# - terminal 1 (2002-2006)
# - terminal 3 (2007-2011)
# - terminal 5 (2012-2016)
# - terminal 4 (2017-2021)
# for each year: 
# - read in annual, global sst file
# - extract sst by cell; save by year-cell
# - save as *.csv
# NEXT (2c): combine all cells to allyears-cell
# follows 00-dl-noaa-sst.R, 01-extract-noaa-sst.R, 01-format-noaa-sst-2.py
# W. Friedman Aug-2022

import pandas as pd
import os
import glob
import re
import numpy as np

sst_dir = "data_dl/NOAA_CRW_SST/sst_global_lrp_combn/"
sst_files = []
out_dir = "data_dl/NOAA_CRW_SST/sst_bycell/sst_cells_byyear/"


for fn in glob.glob(sst_dir+"sst_global*.csv"):
    sst_files.append(fn)

sst_files.sort()

sst = pd.read_csv(sst_files[0]) # these are big; 2-4Gb; takes a minute to read in.
object_ls = list(set(sst.objectid))
# mdl_objects = list(set(sst.objectid[~np.isnan(sst.pct_hardcoral)]))
del(sst)

# make a directory for each object_id to aggregate annual files - just once!
# for obj in object_ls:
#   try: 
#     os.mkdir(out_dir+'sst_objectid_'+str(obj))
#   except:
#     pass

# just run for files > 1997; or split to multiple ranges 
# (end range is +1 actual end year)

for fn in sst_files:
    yr = fn[-8:-4]
    if int(yr) in list(range(2017,2022)): 
        this_sst = pd.read_csv(fn)
        print("generating files for each cell by year: "+yr, "...")

        for obj in object_ls:
            object_sst = this_sst[this_sst.objectid == obj]
            object_sst.to_csv(out_dir+"sst_objectid_"+str(obj)+"/sst_objectid_"+str(obj)+"_"+yr+".csv", index = False)
