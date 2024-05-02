#--- 01-format-noaa-thermalstress.R --------------#
# This file loads data from NOAA Coral Reef Watch
# documenting thermal history & stress
#
# Data are converted from NetCDF to raster for 
# use in analysis. 
#
# W. Friedman - Sept 2021
# ----------------------------------------------- #

# INFO: 
# Thermal History - Stress Frequency (1985-2020)- 5km resolution
# https://coralreefwatch.noaa.gov/product/thermal_history/stress_frequency.php
# Number of Significant Bleaching-level Heat Stress Events (DHW≥4)
# Time between Significant Bleaching-level Heat Stress Events (DHW≥4)
# 
# "Stress events are defined for 1985-2020 by applying Coral Reef Watch's Degree Heating Week (DHW) methodology at coral reef-containing and adjacent satellite pixel locations worldwide, using the Version 3.1 daily global 5km CoralTemp satellite sea surface temperature (SST) data product."
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
#library(terra) # replaces raster. consider updating code to use terra instead.


# Load netCDF file for thermal stress ----
# Note: these data are not stored on GitHub - file is too big. 
# In (untracked) "data_dl" folder

nc_data <- nc_open(here("globalprep","analysis","coral-counterfactual",
                        "data_dl","NOAA_ThermalHistory",
                        "noaa_crw_thermal_history_stress_freq_v3.1.2.nc"))


# Get info ----
# epsg_code: EPSG:4326

# Get info for all variables:
print(nc_data)

# Save to text file
sink(here("globalprep","analysis","coral-counterfactual","data",
          "noaa_thermalstress_info.txt"))
print(nc_data)
sink()

# Print variable names: 
names(nc_data$var)


### Save variables of interest  ----

# int n_ge4[lon,lat]   (Contiguous storage)  
# long_name: Number of events for which the thermal stress, measured by Degree Heating Weeks, reached or exceeded 4 degC-weeks.
# units: counts
# valid_min: 0
# valid_max: 24
# coordinates: lon lat
# comment: The number of events for which the thermal stress, measured by Degree Heating Weeks, reached or exceeded 4 degC-weeks.
# coverage_content_type: physicalMeasurement
# grid_mapping: crs


# n_ge4: Number of events for which the thermal stress, measured by Degree Heating Weeks, reached or exceeded 4 degC-weeks.
dhw4 <- ncvar_get(nc_data, "n_ge4")
dim(dhw4)

dhw_lat <- ncvar_get(nc_data, "lat")
dhw_lon <- ncvar_get(nc_data, "lon")

# mask. An array in the same dimension as the data array classifying which pixels are included in the 
# analysis (i.e., contain data). These were determined as reef-containing pixels plus an ~11-km buffer 
# around those pixels.

dhw_mask <- ncvar_get(nc_data,"mask")

# reef_mask. An array in the same dimension as the data array classifying which pixels contain reefs, as determined using the ReefBase, Millennium Maps, and Reefs at Risk–Revisited datasets, augmented with other documented coral reef locations from collaborative reef studies.

dhw_reefmask <- ncvar_get(nc_data,"reef_mask")

# After saving variables of interest, close the file:
nc_close(nc_data) 


# Convert data to raster ----
# crs = 4326 per info in variable 'crs' (EPSG:4326)

r_dhw4 <- raster(t(dhw4), 
                 xmn=-180, xmx=180, ymn=-35.3,ymx = 34.2,
                 crs=CRS("EPSG:4326"))

r_mask <- raster(t(dhw_mask), 
                 xmn=-180, xmx=180, ymn=-35.3,ymx = 34.2,
                 crs=CRS("EPSG:4326"))


# Check raster against metadata: 
# crs = 4326 per info in variable 'crs' (EPSG:4326)
# geospatial_lon_min: -180
# geospatial_lon_max: 180
# geospatial_lat_min: -40
# geospatial_lat_max: 40
# spatial_resolution: 0.05 degree
# geospatial_lat_units: degrees north
# geospatial_lat_resolution: 0.05
# geospatial_lon_units: degrees east
# geospatial_lon_resolution: 0.05

r_dhw4
r_mask


# Format & plot rasters ---- 

# We will need to transpose and flip to orient the data correctly. 
# The best way to figure this out is through trial and error, but 
# remember that most netCDF files record spatial data from the bottom left corner.

r_dhw4 <- flip(r_dhw4, direction='y')
r_mask <- flip(r_mask, direction='y')

# # Create a new raster of dhw4 values for *just* those cells that are reefs
# !! THIS DOES NOT WORK BECAUSE "REEF_MASK" IS WRONG"
# r_dhw4_reefs <-mask(r_dhw4, r_reefmask, maskvalue = 0, updatevalue = NA)
# r_dhw4_reefs

# # Create a binary raster of reef cells with dhw4 > 0
# r_dhw4_binary <- r_dhw4_reefs > 0
# r_dhw4_binary

# Plot
plot(r_dhw4, col = viridis(8))
plot(r_mask, col = c("black","white")) 


# Save rasters ----

# Base rasters (original data; untransformed)
writeRaster(r_dhw4,
            here("globalprep","analysis","coral-counterfactual","data",
                 "noaa_dhw4.tif"),
            "GTiff",
            overwrite=TRUE)

writeRaster(r_mask,
            here("globalprep","analysis","coral-counterfactual","data",
                 "noaa_dhw_mask.tif"),
            "GTiff",
            overwrite=TRUE)


rm(list=ls())