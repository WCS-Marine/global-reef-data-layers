#--- 01-format-noaa-sst-variability.R --------------#
# This file loads data from NOAA Coral Reef Watch
# documenting thermal history & stress
#
# Data are converted from NetCDF to raster for 
# use in analysis. 
#
# W. Friedman - Sept 2021
# ----------------------------------------------- #

# INFO: 
# SST Variability (1985-2020)- 5km resolution
# https://coralreefwatch.noaa.gov/product/thermal_history/stress_frequency.php
# 
# "Data and images are produced globally at 5km-resolution and are updated daily." 
# 
# NetCDF:
#   https://rpubs.com/boyerag/297592
# 
# File downloaded from FTP on 9/15/2021 (via Cyberduck). could  change to save/load with R instead.
# https://rstudio-pubs-static.s3.amazonaws.com/259387_8b47830276b14b359491eeff5d13dd31.html
# 
# See Tutorial R / NOAA NetCDF data here (including download)
# https://coastwatch.pfeg.noaa.gov/projects/r/Projected.html

# Load libraries ---- 
library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(here)
library(viridis)
#library(terra) # replaces raster. consider updating code to use terra instead.


# Load netCDF file for thermal stress ----
# Note: these data are not stored on GitHub - file is too big. 
# In (untracked) "data_dl" folder

nc_data <- nc_open(here("globalprep","analysis","coral-counterfactual",
                        "data_dl","NOAA_ThermalHistory",
                        "noaa_crw_thermal_history_sst_variability_v3.1.2.nc"))


# Get info ----
# epsg_code: EPSG:4326

# Get info for all variables:
print(nc_data)

# Save to text file
sink(here("globalprep","analysis","coral-counterfactual","data",
          "noaa_sst_variability_info.txt"))
print(nc_data)
sink()

# Print variable names: 
names(nc_data$var)


### Save variables of interest  ----

# float stdv_warmseason[lon,lat]   (Contiguous storage)  
# long_name: Warm-season variability
# units: degrees_Celsius
# valid_min: 0.12280635535717
# valid_max: 1.1193767786026
# coordinates: lon lat
# comment: The standard deviation of the warm-season average temperature values calculated for each year in the time-series, where the warm season is defined as the three-month period centered on the climatologically warmest month.
# coverage_content_type: physical Measurement
# grid_mapping: crs


stdv_warmseason <- ncvar_get(nc_data, "stdv_warmseason")
dim(stdv_warmseason) # 7200x1390

sst_lat <- ncvar_get(nc_data, "lat")
sst_lon <- ncvar_get(nc_data, "lon")

# mask. An array in the same dimension as the data array classifying which pixels are included in the 
# analysis (i.e., contain data). These were determined as reef-containing pixels plus an ~11-km buffer 
# around those pixels.

sst_mask <- ncvar_get(nc_data,"mask")

# After saving variables of interest, close the file:
nc_close(nc_data) 


# Convert data to raster ----
# crs = 4326 per info in variable 'crs' (EPSG:4326)

r_stdv_warmseason <- raster(t(stdv_warmseason), 
                 xmn=-180, xmx=180, ymn=-35.3,ymx = 34.2,
                 crs=CRS("EPSG:4326"))

r_sst_mask <- raster(t(sst_mask), 
                 xmn=-180, xmx=180, ymn=-35.3,ymx = 34.2,
                 crs=CRS("EPSG:4326"))


# Check raster against metadata: 
# epsg_code: EPSG:4326
# geospatial_lon_min: -179.975006103516
# geospatial_lon_max: 179.975006103516
# geospatial_lat_min: -35.2749977111816
# geospatial_lat_max: 34.1750030517578
# spatial_resolution: 0.05 degree
# geospatial_lat_units: degrees north
# geospatial_lat_resolution: 0.05
# geospatial_lon_units: degrees east
# geospatial_lon_resolution: 0.05
# acknowledgment: NOAA Coral Reef Watch program

r_stdv_warmseason
r_sst_mask


# Format & plot rasters ---- 

# We will need to transpose and flip to orient the data correctly. 
# The best way to figure this out is through trial and error, but 
# remember that most netCDF files record spatial data from the bottom left corner.

r_stdv_warmseason <- flip(r_stdv_warmseason, direction='y')
r_sst_mask <- flip(r_sst_mask, direction='y')


# Plot
plot(r_stdv_warmseason, col = viridis(8))
plot(r_sst_mask, col = c("black","white")) 


# Save rasters ----

# Base rasters (original data; untransformed)
writeRaster(r_stdv_warmseason,
            here("globalprep","analysis","coral-counterfactual","data",
                 "noaa_sst_stdv_warmseason.tif"),
            "GTiff",
            overwrite=TRUE)

writeRaster(r_sst_mask,
            here("globalprep","analysis","coral-counterfactual","data",
                 "noaa_sst_mask.tif"),
            "GTiff",
            overwrite=TRUE)


rm(list=ls())
