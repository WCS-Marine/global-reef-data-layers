# 01-extract-noaa-sst.R ------------------#
# 1. Import coral reef cells from Andrello et al. 2021 ('lrp grids')
# 2. For each day, read a *.csv file of global sst data from ERDDAP 
#    (downloaded in 00-dl-noaa-sst.R)
#    e.g. 
#    https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.csv?CRW_SST%5B(1986-01-01T12:00:00Z):1:(1986-01-01T12:00:00Z)%5D%5B(40):1:(-40)%5D%5B(-179.975):1:(179.975)%5D
# 3. convert to spatial object
# 4. Spatial join SST points to all reef polygons (55,000), 
#    extract daily SST (takes ~2min per day; all cells) 
#
# NOTE: this takes a LOT of buffer memory - pay attention to # of cores used
# DONE ON AURORA
#
# W. Friedman // 7.28.2022
# ----------------------------------------#

library(here)
#source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
library(tidyverse)
library(dplyr)
library(sf)
library(doParallel)
library(foreach)

# 0. SET NUMBER OF CORES TO USE ----
# this uses a lot of memory; try 4 instead of 6 cores (aurora)
num_cores <- 4

# 1. import lrp grids ---- 
# read lrp grids (with gcc data); convert to spatial (crs = 4326)

ccdat <- read_rds(here("globalprep", "analysis", "coral-counterfactual",
                       "outputs","04a_lrp_gcc_df.RDS")) %>% 
  select(objectid, geometry, pct_hardcoral, latitude) %>% 
  st_as_sf(crs = 4326)

# 2. Get SST files ---- 
# For each day, read a *.csv file of global sst data from ERDDAP 
sst_files <- list.files(path = here("globalprep","analysis","coral-counterfactual",
                                    "data_dl","NOAA_CRW_SST","sst_global"), pattern = "*.csv")


# 3. Define a function to extract SST ----
extract_sst <- function(sst_fn, ccdat_sf){
  
  sst <- readr::read_csv(here::here("globalprep","analysis","coral-counterfactual",
                                    "data_dl","NOAA_CRW_SST","sst_global",
                                    sst_fn),                
                         skip = 2, 
                         col_names = c("date_utc","latitude","longitude","sst_deg_c"), 
                         col_types = list(
                           date_utc = readr::col_character(),
                           latitude = readr::col_double(),
                           longitude = readr::col_double(),
                           sst_deg_c = readr::col_double())) %>% 
    tibble::as_tibble()
  
  sst['sst_date'] <- stringr::str_split(sst$date_utc[1], "T")[[1]][1]
  
  # make sst as small as possible; convert to spatial (~1-2min)
  sst <- sst %>% 
    dplyr::select(sst_date, latitude, longitude, sst_deg_c) %>% 
    dplyr::filter(latitude <= max(ccdat$latitude), 
                  latitude >= min(ccdat$latitude)) %>% 
    sf::st_as_sf(coords = c("longitude","latitude"), 
                 crs = 4326)
  
  # Extract SST for all 55,000 coral reef cells (lrp) (~2-5min)
  #stime <- date()
  sst_lrp <- sf::st_join(ccdat_sf, sst, join = st_intersects)
  #etime <- date() 
  
  # Write to file 
  sst_lrp %>% 
    readr::write_csv(here::here("globalprep","analysis","coral-counterfactual",
                                "data_dl","NOAA_CRW_SST","sst_global_lrp",
                                paste0("lrp_",sst_fn)))
  
  # Return something
  return(sst_fn)
}
# test function: 
# x <- extract_sst(fn, ccdat)

# data checks: make sure its 4326
library(crsuggest)
sst_sf <- sst %>% 
  sf::st_as_sf(coords = c("longitude","latitude"), 
               crs = 3395) #crs = 4326)

possible_crs <- suggest_top_crs(sst_sf)


# 4. Set up parallel processing ----
# parallel setup: 
n.cores <- num_cores

#create the cluster
my.cluster <- parallel::makeCluster(
  n.cores, 
  type = "FORK"
)

#check cluster definition (optional)
print(my.cluster)

#register it to be used by %dopar%
doParallel::registerDoParallel(cl = my.cluster)

#check if it is registered (optional)
foreach::getDoParRegistered()

#how many workers are available? (optional)
foreach::getDoParWorkers()


# 5. Extract SST over LRP grids, in parallel ----
x <- foreach(
  i = 1:length(sst_files), 
  .combine = 'c'
) %dopar% {
  try(extract_sst(sst_files[i], ccdat))
}


parallel::stopCluster(cl = my.cluster)