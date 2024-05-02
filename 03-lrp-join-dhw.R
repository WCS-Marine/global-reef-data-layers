# 07-lrp-join-dhw.R
# load LRP data
# load DWH data
# Save table

library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))

# Load LRP grid cells ----
# Andrello et al 2021 - local reef pressures
# - 5km polygons (only for reef areas) with values for impacts on  coral reefs
# - See (https://programs.wcs.org/vibrantoceans/Map)
# 
# - paper: (https://www.biorxiv.org/content/10.1101/2021.04.03.438313v1)
# - download data & see readme at: (https://github.com/WCS-Marine/local-reef-pressures)- 
#   - also  see 'key.xlsx' for variable names and descriptions


allreefs_info <- read_excel(here("globalprep", "analysis", "coral-counterfactual","data_dl",
                                 "wcs-local-reef-pressures","key.xlsx"))

allreefs_info

# load dataset (original allreefs.Rdata transformed using "01-format-allreefs.R")

load(here("globalprep", "analysis", "coral-counterfactual","data_dl",
          "wcs-local-reef-pressures", "allreefs_WGS84.RData"))

allreefs <- allreefs %>% 
  select(OBJECTID, geometry)

#allreefs
#plot(allreefs, max.plot = 1)


#  DHW0 Events ----

#- Variable: dhw0
#- Source: NOAA Coral Reef Watch (https://coralreefwatch.noaa.gov/product/thermal_history/stress_frequency.php)
#- File: ‘noaa_crw_thermal_history_stress_freq_v3.1.2.nc’
#- Type: Raster
#- Description: “The number of events for which the thermal stress, measured by Degree Heating Weeks, exceeded 0 degC-weeks.” (1985-2020; n = 36y)
#- Formatted by:  01-format-noaa-dhw0-dhw4.R

# Load dhw raster
r_dhw0 <- raster(here("globalprep","analysis","coral-counterfactual","data",
                      "noaa_dhw0.tif"), package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_dhw0)

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_dhw0 <-  extract(r_dhw0, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_dhw0)



# DHW4 Events ----
#- Variable: dhw4
#- Source: NOAA Coral Reef Watch (https://coralreefwatch.noaa.gov/product/thermal_history/stress_frequency.php)
#- File: ‘noaa_crw_thermal_history_stress_freq_v3.1.2.nc’
#- Type: Raster
#- Description: “The number of events for which the thermal stress, measured by Degree Heating Weeks, reached or exceeded 4 degC-weeks.” (1985-2020)
#- Formatted by:  01-format-noaa-thermalstress.R

# Load thermal stress raster
r_dhw4 <- raster(here("globalprep","analysis","coral-counterfactual","data",
                      "noaa_dhw4.tif"), package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_dhw4)

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_dhw4 <-  extract(r_dhw4, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_dhw4)




# Combine with 'all reefs', save ----
allreefs_dhw <- allreefs %>% 
  cbind(allreefs_dhw0, allreefs_dhw4) %>% 
  rename(dhw0 = allreefs_dhw0, 
         dhw4 = allreefs_dhw4)

# Write to file

fn = here("globalprep","analysis","coral-counterfactual", "outputs", 
          "allreefs_dhw.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(allreefs_dhw, dsn = fn, driver = "GeoJSON", append = F)


# Remove all but the joined reef pressures & effluent table
# DO NOT remove allreefs (will remove from global workspace)
rm(allreefs_dhw0, allreefs_dhw4)
