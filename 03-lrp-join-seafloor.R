# 03-lrp-join-seafloor.R
# load LRP data
# load GSGFM seafloor data
# get intersection of seafloor characteristics, possibly associated with 
# coral reef productivity
# Save these as an indicator; export extended LRP table
# vr_score = vertical relief score (0,1)
# could do more; save area of each geomorphic class, etc. 
# W. Friedman // 04-2022

library(here)
library(tidyverse)
library(sf)

# Load LRP grid cells -----
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

# Load bathymetry data -----
# 
# Seafloor Geomorphic Features Map by Harris, P.T., Macmillan-Lawler, M., 
#  Rupp, J. and Baker, E.K. 2014. Geomorphology of the oceans. Marine Geology, 
#  352: 4-24. is licensed under a Creative Commons Attribution 4.0 
#  International License
# 
# Notes: 
#  W.Friedman (as: friedman@nceas.ucsb.edu) downloaded these data, with 
#  permission, on 5/26/2021 from: https://www.bluehabitats.org/?page_id=58
#  There are many other layers in this dataset; only loading shelf 
#  classification, slope, abyss, and canyons.


# load gsgfm layers of interest
# (filter class == high should get rid of polygon error)
gs_shelf <- st_read(here("globalprep","analysis","mapping","map_data",
                         "GSGFM","Shelf_Classification.dbf")) %>% 
  st_transform(crs = 4326) %>% 
  filter(Class == "high")

gs_shelf %>% tabyl(Geomorphic)
gs_shelf %>% tabyl(Class)


gs_slope <- st_read(here("globalprep","analysis","mapping","map_data",
                         "GSGFM","Slope.dbf")) %>% 
  st_transform(crs = 4326)

gs_slope

gs_abyss <- st_read(here("globalprep","analysis","mapping","map_data",
                         "GSGFM","Abyss.dbf")) %>% 
  st_transform(crs = 4326)

gs_abyss

gs_canyons <- st_read(here("globalprep","analysis","mapping","map_data",
                           "GSGFM","Canyons.dbf")) %>% 
  st_transform(crs = 4326)


# Combine with LRP -----
lrp <- allreefs

sf::sf_use_s2(FALSE) # fixes join error

# join to lrp (takes a few minutes)
lrp_shelf <- st_join(lrp, gs_shelf) 
lrp_slope <- st_join(lrp, gs_slope) 
lrp_abyss <- st_join(lrp, gs_abyss)
lrp_canyons <- st_join(lrp, gs_canyons)


allreefs_abyss <- lrp_abyss %>% 
  mutate(gs_abyss = if_else(Geomorphic == "Abyss", 1, 0),
         gs_abyss = replace_na(gs_abyss, 0)) %>% 
  as_tibble() %>% 
  select(OBJECTID, gs_abyss)


allreefs_slope <- lrp_slope %>% 
  mutate(gs_slope = if_else(Geomorphic == "Slope", 1, 0),
         gs_slope = replace_na(gs_slope, 0)) %>% 
  as_tibble() %>% 
  select(OBJECTID, gs_slope) %>% 
  distinct()

allreefs_canyons <- lrp_canyons %>% 
  mutate(gs_canyons = if_else(Geomorphic == "Canyon", 1, 0),
         gs_canyons = replace_na(gs_canyons, 0)) %>% 
  as_tibble() %>% 
  select(OBJECTID, gs_canyons) %>% 
  distinct()

# high relief shelf
allreefs_shelf_hr <- lrp_shelf %>% 
  mutate(gs_shelf_hr = if_else(Class == "high", 1, 0),
         gs_shelf_hr = replace_na(gs_shelf_hr, 0)) %>% 
  as_tibble() %>% 
  select(OBJECTID, gs_shelf_hr) %>% #get_dupes() %>% view()
  distinct()


allreefs_gsgfm <- allreefs_shelf_hr %>% 
  left_join(allreefs_slope, by = "OBJECTID") %>%
  left_join(allreefs_abyss, by = "OBJECTID") %>% 
  left_join(allreefs_canyons, by = "OBJECTID") %>% 
  mutate(gs_sum = rowSums(across(starts_with("gs_")), na.rm=T), 
         gs_vr_score = if_else(gs_sum > 0, 1, 0)) %>% 
  select(-gs_sum)

# vr_score = vertical relief score (0,1)
allreefs_gsgfm %>% tabyl(gs_vr_score)

# Save as RDS
allreefs_gsgfm %>% 
  saveRDS(file = here("globalprep", "analysis", "coral-counterfactual",
                      "outputs","allreefs_seafloor.RDS"))

# Save as CSV
allreefs_gsgfm %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                      "outputs","allreefs_seafloor.csv"))
