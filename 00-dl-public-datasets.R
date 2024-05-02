# 00-dl-public-datasets.R ----
# download public  datasets used in coral counterfactual analysis
# re-run as necessary (if files are updated)

library(here)
source(here("globalprep","analysis","coral-counterfactual", "00-load-cc-libraries.R"))


# local-reef-pressures allreefs_WGS84.shp
# https://github.com/WCS-Marine/local-reef-pressures/tree/main/data

fn_list = c("allreefs_WGS84.RData", 
            "allreefs_WGS84.gpkg",
            "allreefs_WGS84.prj",
            "allreefs_WGS84.shp",
            "allreefs_WGS84.shx")

for(f in fn_list){
  fn_url = paste0("https://github.com/WCS-Marine/local-reef-pressures/blob/main/data/",f)
  fn_dst = here(here("globalprep","analysis","coral-counterfactual", "data_dl","wcs-local-reef-pressures",f))
  download.file(fn_url, fn_dst)
}


# WWF - Marine Ecoregions (Spalding et al. 2007)
fn_url = "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/7gger8mmke_MEOW_FINAL.zip?_ga=2.183883238.1912345306.1631728993-259244770.1631728993"
fn_dst = here(here("globalprep","analysis","coral-counterfactual", "data_dl","meow.zip"))
download.file(fn_url, fn_dst)

# NOAA netcdf downloads ... 