# 00-download-noaa-SST-bycell.R ----------#
# 
# for each CELL (1600, 55000)
# for each MONTH (432) or YEAR (36)
# download and save all daily temp data from NOAA CRW
#    using ERDDAP server
# combine into a single file per object, save
# -----------------------------------#
library(here)
library(tidyverse)
library(sf)
library(foreach)
library(doParallel)
library(lubridate)

options(timeout = 3600) # set to 1hr

# 1. import lrp grids ---- 
ccdat <- read_rds(here("globalprep", "analysis", "coral-counterfactual",
                       "outputs","04a_lrp_gcc_df.RDS")) %>% 
  st_as_sf(crs = 4326)

#ccdat %>% filter(!is.na(pct_hardcoral_transform)) # 1671 cells with with coral data

# 2. get lrp centroids
lrp_centroids <- st_centroid(ccdat)

# 3. for each reef cell (by objectid); download daily SST from 04-01-1985-12-31-2022
# from erddap server; save as *.csv
# START WITH model data 'gcc centroids'

gcc_centroids <- lrp_centroids %>% 
  filter(!is.na(pct_hardcoral)) # 1671

# get gcc cells that haven't already been downloaded
fn_list <- list.files(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                           "NOAA_CRW_SST","sst_bycell","sst_cells_v1"), 
                      pattern = "*.csv")

# files exist for 435 of 
fn_df <- tibble(filename = fn_list) %>% 
  separate(filename, into = c(NA,NA,NA,"objectid"), sep = "_|.csv", extra = "drop") %>% 
  distinct(objectid)

cells_remaining <- gcc_centroids$objectid[!gcc_centroids$objectid %in% fn_df$objectid]


# function to download sst from NOAA ERDDAP server
# URL example: 
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.csv?CRW_SST%5B(1985-04-01T12:00:00Z):1:(1985-04-02T12:00:00Z)%5D%5B(-4.975):1:(-4.975)%5D%5B( 39.675):1:( 39.675)%5D

dl_sst <- function(cell_id, centroid_sf, startdate ="1985-04-01", enddate = "1985-05-01", fn = "test"){
  latlon <- sf::st_coordinates(centroid_sf[centroid_sf$objectid == cell_id,])
  lonmin = lonmax = round(latlon[1],6) # x
  latmin = latmax = round(latlon[2],6) # y
  
  sst_url = paste0("https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.csv?CRW_SST%5B(",
                   startdate,"T12:00:00Z):1:(",enddate,"T12:00:00Z)%5D%5B(",
                   latmin,"):1:(",latmax,")%5D%5B(",lonmin,"):1:(",lonmax,")%5D")
  
  dest_fn = here::here("globalprep", "analysis", "coral-counterfactual","data_dl",
                       "NOAA_CRW_SST", "sst_bycell_new", paste0(fn,".csv"))
  
  download.file(sst_url,dest_fn) # ~ 1-2min per; can make parallel.
  return(startdate)
}

# test for 1 yr (antares). start = 13:11; end 13:13 (2mins per year); ~1hr per cell; 25 days for all cells to finish downloading.
now()
test <- dl_sst("29", gcc_centroids, "1986-01-01","1986-01-02") # works; no timeout
test <- dl_sst("29", gcc_centroids, "1986-01-01","1986-12-31") # works; no timeout
now()

# make it parallel
# setup
n.cores <- 2 # max # of pings per computer

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
 
# # Extract sst and save----
# by month:
se_dates <- 
  tibble(
    s_date = seq.Date(from=as.Date("1985-04-01"), to=as.Date("2021-12-01"), by="month"),
    e_date = seq.Date(from=as.Date("1985-05-01"), to=as.Date("2022-01-01"), by="month")-1) %>% 
  mutate(across(everything(), ~as.character(.)))

#se_dates

for(obj in cells_remaining[1:2]){
  print(paste("downloading data for obj: ",obj,"..."))
  try({
    dl_dates <- foreach(
      i = 1:nrow(se_dates),
      .combine = rbind
    ) %dopar% {
      Sys.sleep(sample(seq(1,3,by=0.1), 1)) # wait between 1-3 seconds to try next download
      dl_sst(obj, gcc_centroids, se_dates$s_date[i],se_dates$e_date[i],paste("sst_objectid",obj,i, sep = "_"))
    }
  })
}

# STOP CLUSTER
stopCluster(my.cluster)

# NEXT: combine all annual files into a single file per object ID
# (TODO!)


# download with the 'not parallel' version ----
#for(i in 1:nrow(dl_dates)){
#aurora is doing 1:4000; here 4001-5000, 5001-6000 (maybe)
#for(i in 5001:6000){
#  dl_sst(dl_dates$dl_date[i], paste("sst_global",dl_dates$dl_ref[i],sep = "_"))
#}
