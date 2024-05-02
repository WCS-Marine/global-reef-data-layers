# load libraries for coral counterfac

library(here)
source(here("globalprep", "analysis", "00-analysis-libraries.R"))
library(lubridate)
library(RColorBrewer)
library(viridis) # plot colors
library(raster)  # raster manipulation
library(rgdal)   # geospatial analysis
library(sf)      # geospatial analysis
library(velox)   # geospatial analysis
library(conflicted)
library(tidyverse)


conflict_prefer("select", "dplyr") # (need to use raster::select for rasters)
conflict_prefer("filter", "dplyr")

# load "extract_values" function 
source(here("globalprep","analysis","coral-counterfactual","00-lp-extract-values.R"))

# Plot themes
theme_partials <- function(){
  theme_light() %+replace%    #replace elements we want to change
  theme(
    # legend
    legend.position="none")
}

theme_rotate <- function(){
  theme_light() %+replace%    #replace elements we want to change
    theme(
      # rotate x axis labels
      axis.text.x = element_text(angle = 90))
}
