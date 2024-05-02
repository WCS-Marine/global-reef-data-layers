# 03-lrp-join-DO-calcite.R
# load LRP data
# load DO and calcite (raster)
# Add data to lrp (raster extract)
# Save
library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
library(velox) # extract raster data

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

#allreefs
#plot(allreefs, max.plot = 1)


# Extract Dissolved Oxygen----
# - Variable: Dissolved oxygen (mean)
# - Source: Bio-Oracle
# - Type: Raster
# - Note: Data are pretty uniform. Will be interesting to see if useful

# Load raster
r_dissolved_oxygen <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                                  "Bio-Oracle", "Present.Surface.Dissolved.oxygen.Mean.tif"), 
                             package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_dissolved_oxygen) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_dissolved_oxygen <- extract(r_dissolved_oxygen, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_dissolved_oxygen)

# Extract Calcite ----
# - Variable: Calcite (mean)
# - Source: Bio-Oracle
# - Type: Raster
# - Note: Values > 0 are concentrated around coastlines. Missing data or true 0's?

# Load raster
r_calcite <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                         "Bio-Oracle", "Present.Surface.Calcite.Mean.BOv2_2.tif"), 
                    package = "raster") %>% 
  crop(extent(allreefs))

#plot(r_calcite) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes ~3-5min)
allreefs_calcite <-  extract(r_calcite, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_calcite)




# Combine with 'all reefs', save ----
allreefs_DO_calcite <- allreefs %>% 
  cbind(allreefs_dissolved_oxygen, allreefs_calcite) %>% 
  rename(dissolved_oxygen = allreefs_dissolved_oxygen, 
         calcite = allreefs_calcite)

# Write to file
fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_DO_calcite.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(allreefs_DO_calcite, dsn = fn, driver = "GeoJSON", append = F)

# Remove all but the joined reef pressures & effluent table
rm(allreefs_dissolved_oxygen, allreefs_calcite)
