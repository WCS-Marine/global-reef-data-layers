# 03-lrp-join-par-pH-atn.R
# load LRP data
# load par, pH, and diffuse-attenuation (rasters; Bio-Oracle)
# Add data to lrp (raster extract)
# Save

library(here)
source(here("globalprep","analysis","coral-counterfactual","00-load-cc-libraries.R"))
#library(velox) # extract raster data

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


# 1a. Extract Diffuse attenuation (max) ----
# - Variable: Diffuse attenuation (max)	
# - Source: Bio-Oracle
# - Type: Raster

# Load raster
r_diffuse_atn <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                                  "Bio-Oracle", "Present.Surface.Diffuse.attenuation.Max.BOv2_2.tif"), 
                             package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_diffuse_atn) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_diffuse_atn <- extract(r_diffuse_atn, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_diffuse_atn)

# 1b. Extract Diffuse attenuation (mean) ----
# - Variable: Diffuse attenuation (mean)	
# - Source: Bio-Oracle
# - Type: Raster

# Load raster
r_diffuse_atn2 <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                             "Bio-Oracle", "Present.Surface.Diffuse.attenuation.Mean.BOv2_2.tif"), 
                        package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_diffuse_atn2) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_diffuse_atn_mean <- extract(r_diffuse_atn2, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_diffuse_atn2)

# 2. Extract pH (mean) ----
# - Variable: pH (mean)
# - Source: Bio-Oracle
# - Type: Raster

# Load raster
r_pH <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                             "Bio-Oracle", "Present.Surface.pH.BOv2_2.tif"), 
                        package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_pH) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_pH <- extract(r_pH, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_pH)


# 3. Extract PAR (max)  ----
# - Variable: Photosynthetically available radiation "par" (max)
# - Source: Bio-Oracle
# - Type: Raster
# par_max

# Load raster
r_par <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                    "Bio-Oracle", "Present.Surface.Par.Max.BOv2_2.tif"), 
               package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_par) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_par <- extract(r_par, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_par)

# 4. Extract current velocity  ----
# - Variable: Present.Surface.Current.Velocity.Mean (v2.1)
# - Source: Bio-Oracle
# - Type: Raster
# par_max

# Load raster
r_velocity <- raster(here("globalprep","analysis","coral-counterfactual", "data_dl", 
                     "Bio-Oracle", "Present.Surface.Current.Velocity.Mean.tif.BOv2_1.tif"), 
                package = "raster") %>% 
  crop(extent(allreefs)) 

#plot(r_velocity) 

# Get mean of values intersecting 'allreefs' polygons - save this!
# (takes 5-10mins)
allreefs_velocity <- extract(r_velocity, allreefs, fun = median, na.rm=T)

# Clean up large objects
rm(r_velocity)



# Combine with 'all reefs', save ----
allreefs_par_pH_atn <- allreefs %>% 
  cbind(allreefs_diffuse_atn, allreefs_diffuse_atn_mean, allreefs_pH, 
        allreefs_par, allreefs_velocity) %>% 
  rename(diffuse_atn_max = allreefs_diffuse_atn, 
         diffuse_atn_mean = allreefs_diffuse_atn_mean,
         pH_mean = allreefs_pH, 
         par_max = allreefs_par, 
         currents_velocity_mean = allreefs_velocity)

# Write to file
fn = here("globalprep","analysis","coral-counterfactual",
          "outputs", "allreefs_par_pH_atn.geojson")

if(file.exists(fn)){
  file.remove(fn)
}

st_write(allreefs_par_pH_atn, dsn = fn, driver = "GeoJSON", append = F)

# Remove all but the joined reef pressures & effluent table
rm(allreefs_diffuse_atn, allreefs_pH, allreefs_par)
