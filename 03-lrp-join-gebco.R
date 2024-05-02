# Extract depth for all LRP grids from GEBCO 2022
# https://www.gebco.net/data_and_products/gridded_bathymetry_data/#global
# GEBCO Compilation Group (2022) GEBCO_2022 Grid (doi:10.5285/e0f0bb80-ab44-2739-e053-6c86abc0289c)
# Notes: 
# GEBCO geoTIFFs are binned by region
# - Subset data to those regions
# - Get intersections per region
# - Combine into a single file

library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
library(velox) # extract raster data
library(janitor) # dupes

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

# Extract GEBCO depth ----

gebco_files <- list.files(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                               "GEBCO_2022_sub_ice_topo_geotiff"), 
                          pattern = "*.tif")


# define a function to calculate median depth for negative (underwater) values only: 
median_marine <- function(numeric_vec, na.rm = T){
  marine_vals <- numeric_vec[numeric_vec <= 0]
  median(marine_vals, na.rm = na.rm)
}

# initialize empty SF frame to collect data
lrp_depth <- allreefs[0,]

for(fn in gebco_files){
  r_depth <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                                    "GEBCO_2022_sub_ice_topo_geotiff", 
                                    fn), 
                               package = "raster") %>% 
    crop(extent(allreefs)) 
  
  # plot(r_depth)
  # Get mean of values intersecting 'allreefs' polygons - save this!
  # (takes ~2min per file)
  this_lrp_depth <- extract(r_depth, allreefs, fun = median_marine, na.rm=T)
  
  this_lrp_depth <- allreefs %>% 
    cbind(gebco_depth = this_lrp_depth) %>% 
    filter(!is.na(gebco_depth))
  
  lrp_depth <- bind_rows(lrp_depth, this_lrp_depth)
  
  # Clean up large objects
  rm(r_depth, this_lrp_depth)
}

# clean up (55) dupes
dupes <- lrp_depth %>% as_tibble() %>% 
  get_dupes(OBJECTID) %>% 
  group_by(OBJECTID) %>% 
  summarise(gebco_depth_dupe = mean(gebco_depth, na.rm=T), 
            dupe = 1)

lrp_depth <- lrp_depth %>% 
  left_join(dupes) %>% 
  mutate(gebco_depth = if_else(!is.na(dupe), gebco_depth_dupe, gebco_depth)) %>% 
  distinct(OBJECTID, .keep_all = T) %>% 
  select(OBJECTID, gebco_depth, geometry)

# Save
# Write to file
fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_gebco.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(lrp_depth, dsn = fn, driver = "GeoJSON", append = F)

# clean up
rm(dupes, gebco_files, fn)
