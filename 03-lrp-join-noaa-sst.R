# 03-lrp-join-noaa-sst.R --------------------------#
# 
# follows: 00-dl-noaa-sst.R, 01-extract-noaa-sst-2,2b,2c.R
# 
# for each lrp 'objectid' (Andrello et al 2021; local reef pressures)
#  - read extracted daily sst (04/1985-12/2021); from 01-extract-noaa-sst-2c.R
#  - generate statistics (skewness, kurtosis)
#  - save summary object
#  - join to lrp
#
# 
# W. Friedman // 07.28.2022 
# -------------------------------------------------#

library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
library(moments)
library(sf)
library(foreach)
library(doParallel)


# USER INPUTS ----
# PICK ONE - "allreefs"  (55000 cells), or "modelcells" (1600 cells)
#mode = 'modelcells'
mode = 'allreefs'
numcores = 4 # number of cores to use for parallel processing

if(mode == 'modelcells'){
  sst_dir <- here("globalprep","analysis","coral-counterfactual", "data_dl", 
                             "NOAA_CRW_SST","sst_bycell_02c","sst_bycell_modelcells")
}

if(mode == 'allreefs'){
  sst_dir <- here("globalprep","analysis","coral-counterfactual", "data_dl", 
                "NOAA_CRW_SST","sst_bycell_02c","sst_bycell_allreefs")
}

# MAIN ---- 
# List SST files 
fn_list <- list.files(sst_dir, pattern = "*.csv")

# load lrp cells 
# (original allreefs.Rdata transformed using "01-format-allreefs.R")
load(here("globalprep", "analysis", "coral-counterfactual","data_dl",
          "wcs-local-reef-pressures", "allreefs_WGS84.RData"))

# simplified version of allreefs:
lrp <- allreefs %>% 
  select(OBJECTID, geometry)

# Read and summarise SST ----
#  - read extracted daily sst (04/1985-12/2021)
#  - generate statistics (skewness, kurtosis)

# Create empty table to aggregate SST stats
sst_stats <- tibble(objectid = character(), 
                    sst_min = double(),
                    sst_max = double(),
                    sst_mean = double(),
                    sst_median = double(),
                    sst_stdv = double(),
                    sst_skewness = double(),
                    sst_kurtosis = double(), 
                    sst_annualtrend = double())


# For each SST file (objectid) 
#  - read extracted daily sst (04/1985-12/2021)
#  - generate statistics (skewness, kurtosis)
# This is relatively fast ~ 1min for 100 files.

# Make it parallel
generate_stats <- function(sstfn, sstdir, runmode){
  require(tidyverse)
  require(here)
  # 1. Read sst: 
  sst = read_csv(here(sstdir,sstfn), 
                 col_types = list(readr::col_character(),
                                  readr::col_character(), 
                                  readr::col_double(),
                                  readr::col_double(),
                                  readr::col_date(),
                                  readr::col_double(),
                                  readr::col_double(),
                                  readr::col_double())) %>% 
    rename(date = sst_date) %>% 
    mutate(date =  lubridate::ymd(date),
           month = lubridate::month(date), 
           year =  lubridate::year(date))
  
  # 2. Summarise SST:
  ## calculate annual trend
  mdl <- lm(sst_deg_c ~ year, data = sst)
  mdl$coefficients[2]
  
  sst_obj_stats <- tibble(objectid = sst$objectid[1], 
                          sst_min = min(sst$sst_deg_c, na.rm=T),
                          sst_max = max(sst$sst_deg_c, na.rm=T), 
                          sst_mean = mean(sst$sst_deg_c, na.rm=T),
                          sst_median = median(sst$sst_deg_c, na.rm=T),
                          sst_stdv = sd(sst$sst_deg_c, na.rm=T),
                          sst_skewness = moments::skewness(sst$sst_deg_c, na.rm=T),
                          sst_kurtosis = moments::kurtosis(sst$sst_deg_c, na.rm=T),
                          sst_annualtrend = mdl$coefficients[2])
  
  
  if(runmode == 'modelcells'){
    # 4. Plot (and save) time series for each cell
    # check for missing data, etc.
    dt_breaks = seq(as.Date("1985/1/1"), as.Date("2022/1/1"), by = "year")
    
    p1 <- sst %>% 
      ggplot(aes(x = date, y = sst_deg_c, colour = sst_deg_c))+
      geom_point(size = 0.5)+
      scale_colour_viridis_c(limits = c(15,40))+
      geom_smooth(method=lm, formula = y ~ x, se = F, col = "firebrick", lwd = .5)+  # Add linear regression line
      scale_x_continuous(breaks = dt_breaks, labels = dt_breaks)+
      theme_bw()+
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
      ggtitle(paste("OBJECTID:",sst_obj_stats$objectid[1]), 
              subtitle = paste("Annual SST trend = ", round(sst_obj_stats$sst_annualtrend[1],4)))
    
    p2 <- sst %>% 
      ggplot(aes(x = sst_deg_c))+
      geom_histogram(bins = 30, fill = "gray60", colour = "gray70", lwd = 0.2)+
      geom_vline(xintercept = sst_obj_stats$sst_median[1], lty = 2, colour = "gray30")+
      theme_bw()+
      ggtitle(paste0("SST skewness = ", round(sst_obj_stats$sst_skewness[1],3)),
              paste0("SST kurtosis = ", round(sst_obj_stats$sst_kurtosis[1],3)))
      
    png(here("globalprep","analysis","coral-counterfactual", "data_dl", 
             "NOAA_CRW_SST","sst_plots",
             paste0("sst_objectid_",sst_obj_stats$objectid[1],".png")),
        height = 5, width = 11, res = 300, units = "in")
    
    print(ggpubr::ggarrange(p1, p2, labels = c("A", "B"), ncol = 2, widths = c(3,1)))
  
    dev.off()
  }
  

  return(sst_obj_stats) 
}

# Run in parallel ----
# setup
n.cores <- numcores #parallel::detectCores() - 2

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

sst_stats <- foreach(
    i = 1:length(fn_list),
    .combine = rbind
    ) %dopar% {
      generate_stats(fn_list[i], sst_dir, runmode = mode)
    }

# STOP CLUSTER
stopCluster(my.cluster)


# save sst_stats ----
if(mode == "modelcells"){
  sst_stats %>% write_csv(here("globalprep","analysis","coral-counterfactual", 
                             "outputs","gcc_noaa_sst_stats_modelcells.csv"))
}

if(mode == "allreefs"){
  sst_stats %>% write_csv(here("globalprep","analysis","coral-counterfactual", 
                               "outputs", "allreefs_noaa_sst_stats.csv"))
}



# Review data ---- 
# Above takes ~ 3min for 1600 cells - fast!
# 12min for 55000 cells (4 cores). 1210pm start.
# review and save 'bad cells' - too much missing data
# try to download these cells again - incase of erddap server error
# else: remove
# bad_cells <- c("14", "1302")

# if needed: 
#sst_stats <- read_csv(here("globalprep","analysis","coral-counterfactual", 
#                            "outputs","gcc_noaa_sst_stats_allreefs.csv"))

sst_stats <- read_csv(here("globalprep","analysis","coral-counterfactual", 
                           "outputs", "allreefs_noaa_sst_stats.csv"))

# quick plot of stats
hist(sst_stats$sst_skewness)
hist(sst_stats$sst_kurtosis)
hist(sst_stats$sst_annualtrend)
hist(sst_stats$sst_max)
hist(sst_stats$sst_min)

# compare to prior stats from coral reef watch (crw)
# source(here("globalprep","analysis","coral-counterfactual","03-lrp-join-sst.R"))
allreefs_sst <- st_read(here("globalprep","analysis","coral-counterfactual",
                  "outputs", "allreefs_sst.geojson"))

gcc_sst <- allreefs_sst %>% 
  as_tibble() %>% 
  select(OBJECTID, sst_max, sst_range, sst_stdv) %>% 
  rename(objectid = OBJECTID)


sst_join <- sst_stats %>% 
  mutate(objectid = as.character(objectid)) %>% 
  mutate(sst_range = sst_max - sst_min) %>% 
  left_join(gcc_sst, by = "objectid", suffix = c("","_crw"))
  
#sst_join %>% view()

# max values look similar; good
sst_join %>% 
  ggplot(aes(x = sst_max, y = sst_max_crw))+
  geom_point()+
  xlim(26, 36)+ylim(25,36)

# stdv is all over the place; may be based on stdv of monthly rather than daily vals?
# using crw vals
sst_join %>% 
  ggplot(aes(x = sst_stdv, y = sst_stdv_crw))+
  geom_point()
           
# range looks similar; good.
sst_join %>% 
  ggplot(aes(x = sst_range, y = sst_range_crw))+
  geom_point()+
  xlim(0,18)+ylim(0,18)

