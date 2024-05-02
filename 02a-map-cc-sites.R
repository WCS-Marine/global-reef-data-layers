# map of coral cover sites used to generate the model
# read in RDS from 02-prep ... 
# create leaflet of sites
# color by dataset, % cc

library(here)
source(here("globalprep","analysis","coral-counterfactual", "00-load-cc-libraries.R"))
source(here("globalprep","analysis","coral-counterfactual", "00-load-cc-functions.R"))
library(sf)
library(RColorBrewer)
library(leaflet)
library(leaflet.esri)
library(htmlwidgets)

# load data ----
cc_dat <- read_rds(here("globalprep","analysis","coral-counterfactual","outputs",
               "02_cc_dat_combn_sf.RDS"))

cc_dat

# plot data ----

# 9 colors; first 3 are red to yellow
pal <- colorNumeric(c('#92032a','#fee08b','#ffffbf',
                      "#7fcdbb","#41b6c4","#1d91c0", "#225ea8","#0c2c84",
                      '#2d0355'), domain = seq(0,100,5))
# for databases
pal2 <- colorFactor(palette = "Set1", domain = unique(cc_dat$db))

cc_sitemap <- leaflet(cc_dat,
                      options = leafletOptions(preferCanvas = TRUE)) %>% #faster
  # center map on Indonesia
  setView(126, -5, zoom = 6) %>% 
  # background
  addProviderTiles("CartoDB.DarkMatter", options = providerTileOptions(
    updateWhenZooming = FALSE,       # map won't update tiles until zoom is done
    updateWhenIdle    = FALSE)) %>%     # map won't load new tiles when panning
  #cc_obs layer
  addCircleMarkers(
    color = "gray30", weight = .5, fillOpacity = 1, radius = 5,
    fillColor = ~pal(pct_hardcoral),
    popup = paste(paste("Country:", cc_dat$country),
                  paste("Database:", cc_dat$db),
                  paste("%CC Obs:", round(cc_dat$pct_hardcoral, 3)),
                  sep = "<br/>"),    
    group = "pct_hardcoral_obs") %>%
  addCircleMarkers(
    color = "gray30", weight = .5, fillOpacity = 1, radius = 5,
    fillColor = ~pal2(db),
    popup = paste(paste("Country:", cc_dat$country),
                  paste("Database:", cc_dat$db),
                  paste("%CC Obs:", round(cc_dat$pct_hardcoral, 3)),
                  sep = "<br/>"),
    group = "database") %>% 
  # add legend
  addLegend("bottomright", pal = pal, values = ~seq(0,100,5),
            title = "Pct. coral cover",
            opacity = 1) %>%   
  addLegend("bottomleft", pal = pal2, values = unique(cc_dat$db),
            title = "Database",
            opacity = 1) %>% 
  # add Layer controls
  addLayersControl(overlayGroups=c("pct_hardcoral_obs", "database"),
                   options=layersControlOptions(collapsed=F))

# Save map
saveWidget(cc_sitemap, file = here("globalprep","analysis","coral-counterfactual", 
                                        "plots", "cc_sitemap.html"),
           title = "cc_sitemap")


# Other metrics ----
cc_dat %>% tibble %>% tabyl(db, method)
