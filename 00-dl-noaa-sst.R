# 00-download-SST-global.R ----------#
# 
# for each day, from 04-01-1985 to 12-31-2021
# download and save all daily temp data from NOAA CRW
#    using ERDDAP server
# -----------------------------------#
library(here)
library(tidyverse)
library(sf)
library(foreach)
library(doParallel)

options(timeout = 1200) # set to 20mins
# function to download sst from NOAA ERDDAP server
# URL example: 
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.csv?CRW_SST%5B(1985-04-01T12:00:00Z):1:(1985-04-02T12:00:00Z)%5D%5B(-4.975):1:(-4.975)%5D%5B( 39.675):1:( 39.675)%5D
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.csv?CRW_SST%5B(1986-01-01T12:00:00Z):1:(1986-01-01T12:00:00Z)%5D%5B(35):1:(-35)%5D%5B(-179.975):1:(179.975)%5D
# netcdf
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.nc?CRW_SST%5B(1986-01-01T12:00:00Z):1:(1986-01-01T12:00:00Z)%5D%5B(40):1:(-40)%5D%5B(-179.975):1:(179.975)%5D
dl_sst <- function(dt ="1986-01-01", fn = "test"){
  startdate = enddate = dt
  # Update URL to increase year range 
  sst_url = paste0("https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.csv?CRW_SST%5B(",
                   startdate,"T12:00:00Z):1:(",enddate,
                   ")%5D%5B(35):1:(-35)%5D%5B(-179.975):1:(179.975)%5D")
  
  dest_fn = here::here("globalprep", "analysis", "coral-counterfactual","data_dl",
                       "NOAA_CRW_SST", "sst_global", paste0(fn,".csv")) # .csv / .nc
  try(download.file(sst_url,dest_fn)) # ~ 1min per day # method = "wget" or "curl"?
  return(startdate)
}

# make it parallel
# this only works inside R-studio?
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
# 
# # Extract sst and save----
dl_dates <-
  tibble(
    dl_date = seq.Date(from=as.Date("1985-04-01"), to=as.Date("2021-12-31"), by="day")) %>%
  mutate(across(everything(), ~as.character(.))) %>%
  mutate(dl_ref = str_replace_all(dl_date, "-",""))

#dl_dates
 
thisday <- foreach(
    i = 1:10, #i = 1:nrow(dl_dates),
    .combine = rbind
    ) %dopar% {
      Sys.sleep(sample(seq(1,3,by=0.1), 1)) # wait between 1-3 seconds to try next download
      dl_sst(dl_dates$dl_date[i], paste("sst_global",dl_dates$dl_ref[i],sep = "_"))
    }

# STOP CLUSTER
stopCluster(my.cluster)


# download with the 'not parallel' version ----
#for(i in 1:nrow(dl_dates)){
#aurora is doing 1:4000; here 4001-5000, 5001-6000 (maybe)
#for(i in 5001:6000){
#  dl_sst(dl_dates$dl_date[i], paste("sst_global",dl_dates$dl_ref[i],sep = "_"))
#}
