# Download weekly global chlorophyll data from NOAA ERDDAP
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/nesdisVHNSQchlaWeekly.html
# https://data.noaa.gov/dataset/dataset/chlorophyll-noaa-viirs-science-quality-global-level-3-2012-present-weekly1
# https://coastwatch.noaa.gov/cw/satellite-data-products/ocean-color/science-quality/viirs-snpp.html

# temporal-extent-begin 	2012-01-02T12:00:00Z
# temporal-extent-end 	  2020-04-08T12:00:00Z

# lrp_coords$latitude %>% max: 33.675
# lrp_coords$latitude %>% min: -31.675
# lrp_coords$longitude %>% min: -179.975
# lrp_coords$longitude %>% max: 179.975 

# only need to run this once!
# W.Friedman // 05-2022

lat_max = 35
lat_min = -35
url1 <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/nesdisVHNSQchlaWeekly.geotif?chlor_a"

date_ls <-seq(ymd('2012-01-01'),ymd('2020-12-31'), by = '1 week') %>% as.character()

for(dt in date_ls){
  dl_url <- paste0(url1,"%5B(",dt,"T12:00:00Z):1:(",dt,"T12:00:00Z)%5D%5B(0.0):1:(0.0)%5D%5B(", 
                 lat_max,"):1:(",lat_min,")%5D%5B(-179.98125):1:(179.98125)%5D")
  
  fn_dst <- here("globalprep","analysis","coral-counterfactual", 
                             "data_dl", "NOAA_VIIRS_Chla_weekly",paste0("chla-",dt,".tif"))

  download.file(dl_url, fn_dst)
}
