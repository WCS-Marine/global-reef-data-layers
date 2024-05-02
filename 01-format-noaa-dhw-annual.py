# 01-format-noaa-dhw-annual-max-cumulative.py --------------------------------#
# What is the cumulative stress for each reef cell?

# 1. Annual nc files were downloaded from 1988-2022 via FTP at: 
#    ftp.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1_op/nc/v1.0/annual
#    More info: https://coralreefwatch.noaa.gov/product/5km/methodology.php#dhw
#    Files contain globally gridded values indicating annual maximum DHW
# 2. This script combines all annual observation files, then
# 3. For each cell, (a) extracts annual max dhw, (b) sums to create cumulative max dhw
# 4. Exports file for use in 03-prep-global-gridded.Rmd
# W. Friedman // 01-2024
# ----------------------------------------------------------------------------#

import xarray as xr
import pandas as pd

#base_dir = os.getcwd() # Path to 'MACMON-global'
base_dir = '/Users/friedman/Documents/Projects/WCS/MACMON-global'
data_dir = base_dir+'/globalprep/analysis/coral-counterfactual/data_dl/NOAA_CRW_Annual/'
output_dir = base_dir + '/globalprep/analysis/coral-counterfactual/outputs/'
cc_cells_fn = base_dir+'/globalprep/analysis/coral-counterfactual/outputs/allreefs_cc_centroids.csv'
allreefs_fn = base_dir+'/globalprep/analysis/coral-counterfactual/outputs/allreefs_centroids.csv'

# load data ----
# cc_cells = pd.read_csv(cc_cells_fn) # 1671 cells
allreefs = pd.read_csv(allreefs_fn) # 54596 cells

# combine dhw_max files (takes a min..) ----
ds = xr.open_mfdataset(data_dir+'ct5km_dhw-max*.nc',combine = 'by_coords') #concat_dim="time")

# for each reef cell and year, save max dhw ----
#dhw_max = pd.DataFrame()
dhw_max = dict() # objectid:

for i in range(0,len(allreefs)):
  print("processing cell",i,"... \n")
  this_lat = allreefs.latitude[i]
  this_lon = allreefs.longitude[i]
  this_objectid = str(allreefs.OBJECTID[i])

  dat = ds.sel(lon = this_lon, lat = this_lat, method = 'nearest')
  dhw_max[this_objectid] = sum(dat.degree_heating_week.values)

  del(dat)

# format and save ---- 
dhw_max_cumulative = pd.DataFrame({'OBJECTID':dhw_max.keys(), 'dhw_max_cuml':dhw_max.values()})

dhw_max_cumulative.to_csv(output_dir+'allreefs_dhw_annualmax_cumulative.csv', index = False)

