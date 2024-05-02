# 03-lrp-join-mpa.R
# load LRP data
# load MPA data
# Add MPA data to lrp
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

#allreefs
#plot(allreefs, max.plot = 1)


# Load MPA data ----
# MPA data downloaded on 5/18/2022 from www.protectedplanet.net
#
# Citation:
# UNEP-WCMC and IUCN (2022), Protected Planet: The World Database on Protected 
# Areas (WDPA) and World Database on Other Effective Area-based Conservation 
# Measures (WD-OECM) [Online], May 2022, Cambridge, UK: UNEP-WCMC and IUCN. 
# Available at: www.protectedplanet.net.
#
# FUTURE: 
# Update with protection levels (proposed -> implemented, lightly - fully protected) from 
# https://mpatlas.org/; https://marine-conservation.org/mpatlas/download/

# takes a minute to load
mpa <- st_read(here("globalprep","analysis","mapping","map_data", "WDPA",
                    "WDPA_May2022_Public.gdb"), layer = "WDPA_poly_May2022")

# filter to marine pa's
# Allowed values for col 'MARINE': 
# 0 (predominantly or entirely terrestrial) 
# 1 (Coastal: marine and terrestrial) 
# 2 (predominantly or entirely marine) 

mpa_mar <- mpa %>% 
  filter(MARINE != 0)

sf::sf_use_s2(FALSE) # fixes join error

# NOTE: some lrp grids are associated with multiple MPAs.

allreefs_mpa <- allreefs %>% 
  st_join(mpa_mar) %>% 
  mutate(WDPA_MPA = if_else(!is.na(WDPAID), 1, 0))


# Notes: 

# WDPA_MPA = 1 if there's a WDPA ID Assigned. 
# Looks similar to "PA_DEF", where
# 1 = (meets IUCN and CBD protected area definitions)

allreefs_mpa %>% tabyl(WDPA_MPA)
allreefs_mpa %>% tabyl(PA_DEF)


# IUCN Categories: 
# Ia. Strict Nature Reserve
# Ib. Wilderness Area
# II. National Park
# III. Natural Monument 
# IV. Habitat/ Species Management 
# V. Protected Landscape/ Seascape
# VI. Managed Resource Protected Area

allreefs_mpa %>%
  filter(PA_DEF == 1) %>% 
  tabyl(IUCN_CAT)

# Write to file

fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_mpa.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(allreefs_mpa, dsn = fn, driver = "GeoJSON", append = F)

rm(mpa, mpa_mar)