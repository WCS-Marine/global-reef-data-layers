# Extract depth for all LRP grids from Global Mangrove Watch (GMW v3.0; 2022)
# Years downloaded: 2015, 2018, 2022
# Downloaded with permission by W.F. (friedman@thrivingoceanscollective.org) on 23-Sept-2022
# https://www.globalmangrovewatch.org/
# https://www.eorc.jaxa.jp/ALOS/en/dataset/gmw_e.htm
# https://www.eorc.jaxa.jp/ALOS/en/dataset/gmw/area/gmw_map_e.htm
# Notes: 
# Dataset name: 	Global Mangrove Watch, version 3.0
# Content: 	Mangrove geographical extent for the years 1996, 2007, 2008, 2009, 2010, 2015, 2016, 2017, 2018, 2019 and 2020
# Pixel spacing: 	25 m (0.000222 degrees)
# Data type: 	Raster (BYTE)
# Pixel values: 	DN=1: mangroves; DN=0: non-mangrove
# Format: 	GeoTIFF
# Projection: 	Geographic coordinates (WGS 84, EPSG=4326)

# GMW geoTIFFs are binned by region
# - Subset data to those regions
# - Get intersections per region
# - Combine into a single file

library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
library(velox) # extract raster data
library(foreach) # parallel
library(doParallel) # parallel

ncores <- 4 # more than this slows things down too much on antares

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


# Setup parallel ----
# setup
n.cores <- ncores # max # of cores to use

#create the cluster
my.cluster <- parallel::makeCluster(
  n.cores,
  type = "PSOCK"
)

#check cluster definition (optional)
print(my.cluster)
#register it to be used by %dopar%
doParallel::registerDoParallel(cl = my.cluster)

#check if it is registered (optional)
foreach::getDoParRegistered()
#how many workers are available? (optional)
foreach::getDoParWorkers()

# Define function ----
extract_gmw <- function(allreefs, path, fn){
  require(tibble)
  require(raster)
  require(dplyr)
  
  r_gmw <- raster(paste(path, fn, sep = "/"), 
                  package = "raster") %>% 
    crop(extent(allreefs)) 
  
  # plot(r_gmw)
  
  # Get mean of values intersecting 'allreefs' polygons - save this!
  # (takes ~1min per file)
  this_mangrove_dat <- extract(r_gmw, allreefs, fun = sum, na.rm=T)
  
  if("matrix" %in% class(this_mangrove_dat)){
    this_mangrove_dat <- allreefs %>%
      cbind(gmw_dat = this_mangrove_dat) %>%
      filter(!is.na(gmw_dat)) %>% 
      mutate(gmw_area_m = gmw_dat * 25) # number of 25m pixels with data -> area (m)
  }else(
    this_mangrove_dat = allreefs[0,]
  )
  
  return(this_mangrove_dat)
}

# Extract mangrove data ----
gmw_path <- here("globalprep","analysis","coral-counterfactual", "data_dl", 
                 "GMW_v3_2022","gmw_v3_2015")

gmw_files <- list.files(gmw_path, pattern = "*.tif")

# TEST
# gmw_files = gmw_files[1000:1010]

# run in parallel
lrp_mangroves <- foreach(
  i = 1:length(gmw_files),
  .combine = rbind
) %dopar% {
  try(extract_gmw(allreefs, gmw_path, gmw_files[i]))
}

#1211
lrp_mangroves

# STOP CLUSTER ----
stopCluster(my.cluster)

# SAVE ----
# Write to file
fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_gmw.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(lrp_mangroves, dsn = fn, driver = "GeoJSON", append = F)