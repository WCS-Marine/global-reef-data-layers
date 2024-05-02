# 01-format-msec.py --------------------------------#


# This file reads in netCDF files from the 'msec' project, align with allreefs:
#  Yeager, Lauren A., Philippe Marchand, David A. Gill, Julia K. Baum, and Jana M. McPherson.
#  "Marine socio‐environmental covariates: Queryable global layers of environmental and anthropogenic
#  variables for marine ecosystem studies." (2017): 1976-1976.
#  https://doi.org/10.1002/ecy.1884

# 1. Read netcdf, extract values at centroid, save
# 3. For each cell,
# 4. Exports file for use in 03-prep-global-gridded.Rmd
# W. Friedman // 01-2024
# ----------------------------------------------------------------------------#
import xarray as xr
import pandas as pd
import os

base_dir = os.getcwd() # Path should end at 'coral-counterfactual'
data_dir = base_dir+'/data_dl/MSEC_Yeager_etal/'
output_dir = base_dir + '/outputs/'
allreefs_fn = base_dir+'/outputs/allreefs_centroids.csv'

# load data ----
allreefs = pd.read_csv(allreefs_fn) # 54596 cells with lat,lon centroids

# Note: msec_wave_sd.nc throws an error; leaving out for now.
msec_files = ["msec_wave_mean.nc", "msec_npp_mean.nc" ,"msec_npp_sd.nc", "msec_reefarea_15km.nc"]
msec_vars = ["wave_energy_mean","npp_mean", "npp_sd", "reef_area_15km"]

# Open and print information for each variable
for fn in msec_files:
    print("\n\n information for:", fn, " ------\n")
    ds = xr.open_mfdataset(data_dir+fn) # open netcdf
    print("CRS:", ds.crs, "\n") # check wgs84, yes
    print("Variables: \n",ds.variables, "\n") # variable def's etc.

for k in range(0, len(msec_files)):
    f = msec_files[k]
    var = msec_vars[k]
    ds = xr.open_mfdataset(data_dir+f) # open netcdf

    # extract data for coral reef cells
    data_dict = dict() # objectid: value
    for i in range(0,len(allreefs)):
      print("extracting", var, "for cell",i,"... \n")
      this_lat = allreefs.latitude[i]
      this_lon = allreefs.longitude[i]
      this_objectid = str(allreefs.OBJECTID[i])

      dat = ds.sel(longitude = this_lon, latitude = this_lat, method = 'nearest')
      data_dict[this_objectid] = dat[var].values

      del(dat)

    if var == "wave_energy_mean":
        allreefs_wave_energy_mean = pd.DataFrame({'OBJECTID':data_dict.keys(), 'wave_energy_mean':data_dict.values()})
        allreefs_wave_energy_mean.to_csv(output_dir+'allreefs_wave_energy_mean.csv', index = False)

    if var == "npp_mean":
        allreefs_npp_mean = pd.DataFrame({'OBJECTID':data_dict.keys(), 'npp_mean':data_dict.values()})
        allreefs_npp_mean.to_csv(output_dir+'allreefs_npp_mean.csv', index = False)

    if var == "npp_sd":
        allreefs_npp_sd = pd.DataFrame({'OBJECTID':data_dict.keys(), 'npp_sd':data_dict.values()})
        allreefs_npp_sd.to_csv(output_dir+'allreefs_npp_sd.csv', index = False)

    if var == "reef_area_15km":
        allreefs_reef_area_15km = pd.DataFrame({'OBJECTID':data_dict.keys(), 'reef_area_15km':data_dict.values()})
        allreefs_reef_area_15km.to_csv(output_dir+'allreefs_reef_area_15km.csv', index = False)

    del(f, var, ds, data_dict)
