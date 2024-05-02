# 07-lrp-join-effluent.R
# load LRP data
# load Effluent data
# Add effluent data to lrp
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

allreefs

  
#plot(allreefs, max.plot = 1)


# Load Wastewater Data ----
# 
# Wastewater N & FIO
# Tuholske, Cascade, Benjamin S. Halpern, Gordon Blasco, Juan Carlos Villasenor, Melanie Frazier, and Kelly Caylor. "Mapping global inputs and impacts from of human sewage in coastal ecosystems." PloS one 16, no. 11 (2021): e0258898.
# 
# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0258898
# https://knb.ecoinformatics.org/view/doi:10.5063/F76B09
# 
# We use a new high-resolution geospatial model to measure and map nitrogen (N) and pathogen - fecal indicator organisms (FIO) - inputs from human sewage for ~135,000 watersheds globally. Our modeled data is for 2015. The resulting dataset provides N and FIO wastewater inputs for each watershed globally. The dataset separates the contribution from sewered, septic, and untreated (open deification) wastewater inputs to coastal waters. Data is provided at the watershed level, as well as the coastal 'pourpoint' (the location where the watershed empties into the ocean), as vector shape files (.shp). Furthermore, we provide a global raster of N coastal impacts created by propagating pourpoint N inputs into the coastal waters using a plume model based on a logarithmic decay function. The effluent plumes can be used to determine the extent to which different marine habitats are exposed to wastewater N.
# 
# "The modeled wastewater plume data was used to determine the exposure of coral and sea- grass to N inputs from wastewater. We rasterized spatial polygon and point data describing global coral reef [62] and seagrass bed [63] locations to create raster maps of ~0.5 km resolution. These cells were then aggregated to *~1km* resolution consistent with the output from the plume model. Cells including the habitat were classified as 1, and otherwise set to no value. We used a higher resolution for the initial rasterization to ensure a higher probability of capturing smaller polygon areas because the habitat is not identified in the cell unless it overlaps with the center of the raster cell. We extracted the N values for each sanitation system and the total N from all wastewater for each raster cell containing the habitat. Finally, we defined hot- spots as habitat raster cells exposed to total wastewater N values equal to or greater than the 97.5th quantile determined across the entire range of the habitat."
# - global_effluent_2015_open_N.tif
# - global_effluent_2015_septic_N.tif
# - global_effluent_2015_treated_N.tif
# - global_effluent_2015_tot_N.tif


# Extract: effluent_2015_open_N ----
# Load raster, crop to keep object sizes small(er)
r_eff_totN <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", "tuholske_knb", 
                          "Global_N_Coastal_Plumes_tifs", "global_effluent_2015_tot_N.tif"), 
                     package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_eff_totN,col = viridis(n=4))

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes ~3-5min)
allreefs_totN <-  extract(r_eff_totN, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_eff_totN)


# Extract: septic_N ----
# - global_effluent_2015_septic_N.tif

# Load raster, crop to keep object sizes small(er)
r_eff_septicN <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", "tuholske_knb", 
                             "Global_N_Coastal_Plumes_tifs", "global_effluent_2015_septic_N.tif"), 
                        package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_eff_septicN,col = viridis(n=8))

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes ~3-5min)
allreefs_septicN <-  extract(r_eff_septicN, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_eff_septicN)



# Extract: treated_N ----
# global_effluent_2015_treated_N.tif

# Load raster, crop to keep object sizes small(er)
r_eff_treatedN <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", "tuholske_knb", 
                              "Global_N_Coastal_Plumes_tifs", "global_effluent_2015_treated_N.tif"), 
                         package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_eff_treatedN,col = viridis(n=8))

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes ~3-5min)
allreefs_treatedN <-  extract(r_eff_treatedN, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_eff_treatedN)


# Extract: open_N ----
# global_effluent_2015_open_N.tif

# Load raster, crop to keep object sizes small(er)
r_eff_openN <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", "tuholske_knb", 
                           "Global_N_Coastal_Plumes_tifs", "global_effluent_2015_open_N.tif"), 
                      package = "raster") %>% 
  crop(extent(allreefs)) 

# plot(r_eff_openN,col = viridis(n=8))

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes ~3-5min)
allreefs_openN <-  extract(r_eff_openN, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_eff_openN)


# Combine with 'all reefs', save ----

allreefs_effluent <- allreefs %>% 
  cbind(allreefs_openN, allreefs_septicN, allreefs_treatedN, allreefs_totN) %>% 
  rename(effluent_openN = allreefs_openN, 
         effluent_septicN = allreefs_septicN, 
         effluent_treatedN = allreefs_treatedN, 
         effluent_totalN = allreefs_totN)


# Write to file

fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_effluent.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(allreefs_effluent, dsn = fn, driver = "GeoJSON", append = F)

# Remove all but the joined reef pressures & effluent table
# rm(allreefs_openN, allreefs_septicN, allreefs_totN, allreefs_treatedN)
