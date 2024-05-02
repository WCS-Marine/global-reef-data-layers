# 03-lrp-join-sst.R
# load LRP data
# load SST data
# Add SST data to lrp
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

allreefs

#allreefs
#plot(allreefs, max.plot = 1)


# Extract SST Variability (STDV) ----

# - Variable: SST variability
# - Source: NOAA Coral Reef Watch (https://coralreefwatch.noaa.gov/product/thermal_history/stress_frequency.php)
# - File: ‘noaa_crw_thermal_history_sst_variability_v3.1.2.nc’’
# - Type: Raster
# - Description: “The standard deviation of the warm-season average temperature values calculated for each year in the time-series, where the warm season is defined as the three-month period centered on the climatologically warmest month.” (1985-2020; n = 36y)
# - Formatted by: 01-format-noaa-sst-variability.R

# Load sst raster
r_sst_stdv <- raster(here("globalprep","analysis","coral-counterfactual","data",
                          "noaa_sst_stdv_warmseason.tif"), package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_sst_stdv)

# Get median of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_sst_stdv <-  extract(r_sst_stdv, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_sst_stdv)


# Extract SST Max ----
#- Variable: SST Max
#- Source: Bio-Oracle
#- Type: Raster

r_sst_max <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                         "Bio-Oracle", "Present.Surface.Temperature.Max.tif"), 
                    package = "raster") %>% 
  crop(extent(allreefs))

#plot(r_sst_max) 


# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_sst_max <-  extract(r_sst_max, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_sst_max)


# Extract SST Range ----
# - Variable: SST Range
# - Source: Bio-Oracle
# - Type: Raster

# Load raster
r_sst_range <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                           "Bio-Oracle", "Present.Surface.Temperature.Range.tif"), 
                      package = "raster") %>% 
  crop(extent(allreefs))

#plot(r_sst_range) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_sst_range <-  extract(r_sst_range, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_sst_range)



# Combine with 'all reefs', save ----
allreefs_sst <- allreefs %>% 
  cbind(allreefs_sst_max, allreefs_sst_range, allreefs_sst_stdv) %>% 
  rename(sst_max = allreefs_sst_max, 
         sst_range = allreefs_sst_range, 
         sst_stdv = allreefs_sst_stdv)


# Write to file

fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_sst.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(allreefs_sst, dsn = fn, driver = "GeoJSON", append = F)


# Remove all but the joined reef pressures & effluent table
rm(allreefs_sst_max, allreefs_sst_range, allreefs_sst_stdv)
