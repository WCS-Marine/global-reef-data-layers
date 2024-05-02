# 03-lrp-join-chla ---------------- #
# - Read and summarise weekly chlorophyll data over the lrp cells
# - Get overall (weekly): mean, median, max, min, sd of chla per cell over the 10-yr time period
# - Get annual: mean, median; sd of all annual; max/min of annual
# - Number of weeks above 0.2, 0.3, 0.4 thresholds (Bell et al. 2014)
# 
# From Bell et al 2014; 
# Initially an ETC-Chl a corresponding to an annual mean Chl a \0.5 mg m-3 
# was chosen (Bell 1992); the currently mandated Trigger value for Chl a 
# (T-Chl a) *0.4–0.45 mg m-3 (GBRMPA 2010) essentially agrees with this value. 
# Further analysis of the Barbados data (Bell and Elmetri 1995; Bell et al. 
# 2007) and application of the ETM to the demise of corals in the Florida Keys 
# (Lapointe 1997; Lapointe et al. 2004) suggested that an even lower 
# ETC-Chl a (*0.2–0.3 mg m-3) is applicable in regions that have a high 
# proportion of coral species that are sensitive to settlement of POM 
# (e.g., Acropora palmata and plate-type corals) and in particular to regions 
# that are subject to a low flushing regime where settlement of POM and a 
# build-up of DOM are pro- moted. Initially we defined a chronic state of 
# eutrophication to exist in regions characterized by an annual mean Chl a
# [0.3 mg m-3 (Bell et al. 2012). However, the above dis- cussed findings 
# that COTS larval growth is promoted in the lower ETC-Chl a range 0.2–0.3 mg 
# m-3 suggests that a chronic state would be better defined at the lower end of
# this range, i.e., [0.2 mg m-3. This value agrees with the ETC value suggested 
# by data for the wider Caribbean (Lapointe et al. 2007; Lapointe and Mallin 2011).
# 
# Data info:
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/nesdisVHNSQchlaWeekly.html
# https://data.noaa.gov/dataset/dataset/chlorophyll-noaa-viirs-science-quality-global-level-3-2012-present-weekly1
# https://coastwatch.noaa.gov/cw/satellite-data-products/ocean-color/science-quality/viirs-snpp.html
#
# Takes awhile to extract all weekly data; do it in parallel. 
# See: https://www.blasbenito.com/post/02_parallelizing_loops_with_r/
# 
# W. Friedman // May 2022
# --------------------------------- #

library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
library(foreach)
library(doParallel)
library(moments) # skewness, kurtosis



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

#allreefs
#plot(allreefs, max.plot = 1)

# simplified version of allreefs:
lrp <- allreefs %>% 
  select(OBJECTID, geometry)

# Extract Weekly Chl-a over LRP grid cells ----
# - Variable: Chlorophyll (mg m^-3; mass_concentration_of_chlorophyll_a_in_sea_water)
# - min: 0.001, max: 100.0
# - Science quality data; 01-2012 - 05-2020
# - (real) max# of samples per cell: 470
# - (real) min# of samples per cell: 0
# - Source: NOAA CoastWatch
# - Type: Raster

# Chl-a files:
fn_list <- list.files(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                           "NOAA_VIIRS_Chla_weekly"), pattern = "chla-")

# setup 
n.cores <- parallel::detectCores() - 2

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

# define a function that extracts chlorophyll data over the
# lrp grid cells; returns a single data.frame to be iteratively combined 
get_chla <- function(fn, lrp){
  library(here)
  library(tidyverse)
  library(raster)
  library(dplyr)
  fn_path <- here("globalprep","analysis","coral-counterfactual", "data_dl", 
                  "NOAA_VIIRS_Chla_weekly", fn)
  chla_dt <- str_sub(fn, start = 6L, end = -5L)
  # Load raster
  r_chla <- raster(fn_path, package = "raster") %>% 
    crop(extent(lrp)) 
  # Get median of values intersecting 'allreefs' polygons - save this!
  # (takes 5-10mins)
  lrp_chla <- extract(r_chla, lrp, fun = median, na.rm=T)
  
  # make chla_id the column name
  df_chla <-  lrp %>% 
    as_tibble() %>% 
    bind_cols(chla = lrp_chla) %>%
    mutate(date = chla_dt) %>% 
    dplyr::select(-geometry) %>% 
    as.data.frame()
    
  
  return(df_chla)
}

# Extract chla ----
chla_weekly <- foreach(
  i = 1:length(fn_list),
  .combine = rbind
) %dopar% {
  get_chla(fn_list[i], lrp)
}

# Save ----  
write_rds(chla_weekly, file = here("globalprep","analysis","coral-counterfactual", 
                          "outputs","allreefs_chla_weekly.RDS"))

#chla_weekly <- read_rds(here("globalprep","analysis","coral-counterfactual", 
#                             "outputs","allreefs_chla_weekly.RDS"))

# Summarize chl-a data by site ----
chla_weekly %>% head()  

# Check for extreme outliers (takes awhile...)
chla_weekly %>% 
  mutate(date = ymd(date),
         year = lubridate::year(date)) %>% 
  ggplot(aes(x = OBJECTID, y = chla, colour = year))+
  geom_point()

ggsave()

# Annual stats
chla_annual <- chla_weekly %>% 
  mutate(date = ymd(date),
         year = lubridate::year(date)) %>% 
  # replace values == 0 (no data), and > 100 (error?) with NA
  mutate(chla = if_else(chla > 100, 0, chla), 
         chla = na_if(chla, 0)) %>% 
  group_by(OBJECTID, year) %>% 
  summarise(chla_annual_mean = mean(chla, na.rm=T),
            chla_annual_median = median(chla, na.rm = T), 
            chla_annual_max = max(chla, na.rm = T), 
            chla_annual_min = min(chla, na.rm = T), 
            chla_annual_sd  = sd(chla, na.rm = T),
            chla_annual_samples =  sum(!is.na(chla))) %>% 
  mutate(chla_annual_med_p20 = if_else(chla_annual_median >= 20, 1, 0),
         chla_annual_med_p30 = if_else(chla_annual_median >= 30, 1, 0),
         chla_annual_med_p40 = if_else(chla_annual_median >= 40, 1, 0)) %>% 
  mutate(chla_annual_range = chla_annual_max - chla_annual_min)

chla_annual %>% head()
chla_annual %>% filter(chla_annual_med_p20 > 0) # ~450 yr-cells with annual median > 20
hist(chla_annual$chla_annual_range)

# summarise over annual values
chla_9y <- chla_annual %>% 
  group_by(OBJECTID) %>% 
  summarise(chla_avg = mean(chla_annual_median, na.rm=T), 
            chla_max = max(chla_annual_median, na.rm=T),
            chla_min = min(chla_annual_median, na.rm=T), 
            chla_sd  = sd(chla_annual_median, na.rm=T))

chla_resid <- chla_annual %>% 
  left_join(chla_9y[c("OBJECTID","chla_avg")]) %>% 
  group_by(OBJECTID, year) %>% 
  summarise(annual_resid = chla_annual_median - chla_avg) %>% 
  group_by(OBJECTID) %>% 
  summarise(chla_max_resid = max(annual_resid))

# ~425 grid cells with max annual residuals (above annual median) > 5mg/m3
chla_resid %>% filter(chla_max_resid > 5) %>% 
  pull(chla_max_resid) %>% hist()

# Weekly stats
# TODO: remove where n_samples (or n_annual_samples) is too small
# TODO: check NA assumptions with data provider (FIRST with raster extract fcn)
chla_wk_stats <- chla_weekly %>% 
  # replace values == 0 (no data), and > 100 (error?) with NA
  mutate(chla = if_else(chla > 100, 0, chla), 
         chla = na_if(chla, 0)) %>% 
  # record if weekly chl-a is above threshold values (20,30,40):
  mutate(chla_p20 = if_else(chla >= 20, 1, 0),
         chla_p30 = if_else(chla >= 30, 1, 0),
         chla_p40 = if_else(chla >= 40, 1, 0)) %>% 
  group_by(OBJECTID) %>% 
  summarise(chla_mean = mean(chla, na.rm = T),
            chla_median = median(chla, na.rm = T), 
            chla_max = max(chla, na.rm = T), 
            chla_min = min(chla, na.rm = T), 
            chla_sd  = sd(chla, na.rm = T), 
            chla_skewness = skewness(chla, na.rm=T),
            chla_kurtosis = kurtosis(chla, na.rm=T),
            chla_range = chla_max - chla_min,
            chla_samples = sum(!is.na(chla)),
            # number of weeks > threshold:
            chla_p20_sum = sum(chla_p20, na.rm=T),
            chla_p30_sum = sum(chla_p30, na.rm=T),
            chla_p40_sum = sum(chla_p40, na.rm=T))
  
  
chla_wk_stats %>% head()

chla_wk_stats$chla_samples %>% hist()

chla_wk_stats %>% 
  filter(chla_p20_sum ==1) %>% view()

chla_wk_stats %>% 
  filter(chla_max > 20) %>% 
  pull(chla_max) %>% 
  hist()


# detecting 'phase shifts' in chl-a
chla_wk_stats$chla_range %>% hist()
chla_wk_stats$chla_sd %>% hist()
chla_wk_stats$chla_skewness %>% hist()
chla_wk_stats$chla_kurtosis %>% hist()

# skewness
# kurtosis
# https://towardsdatascience.com/skewness-kurtosis-simplified-1338e094fc85

# high skewness example
chla_wk_stats %>% filter(chla_skewness > 10) %>% head()
chla_wk_stats %>% filter(chla_skewness < -3) %>% head()

cellid = 26764#10085
tmp <- chla_weekly[chla_weekly$OBJECTID == cellid,]
tmp$chla %>% hist()
