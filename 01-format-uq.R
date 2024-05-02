# ------------------------------------------#
# 01-format-uq.R 
# load and format UQ photo quadrat data 
# to include in GCCv1.1
# W. Friedman // April 15, 2022
# ------------------------------------------#

library(here)

source(here("globalprep","analysis","coral-counterfactual", "00-load-cc-libraries.R"))
country_tbl <- read_csv(here("globalprep","analysis","mapping","map_data", "country_codes.csv"))

# Note: 
# dat_uq has "CHA" (Chagos Archipelago); re-coding as "MUS" (Mauritius) to align
# with other datasets in use.

dat_uq <- read_csv(here("globalprep","analysis","coral-counterfactual","data_dl",
              "UQ_CoralCover","seaviewsurvey_surveys.csv")) %>% 
  rename(latitude = lat_start, 
         longitude = lng_start) %>% 
  mutate(date = lubridate::ymd(surveydate),
         year = lubridate::year(date),
         db = "uq_photoquadrat",
         method = "photo") %>% 
  rename(iso3 = country) %>%
  mutate(iso3 = recode(iso3, 
                       "CHA" = "MUS")) %>% 
  left_join(country_tbl[c("iso3","country")]) %>% 
  mutate(pct_hardcoral = pr_hard_coral * 100) %>% 
  select(surveyid, transectid, date, year, ocean, country, iso3, latitude, longitude, pct_hardcoral, db, method)


# Data checks
# Not much to do; very clean already

# dat_uq %>% get_dupes() # no dupes
# length(unique(dat_uq$surveyid)) == nrow(dat_uq) # True; all surveys are unique

# dat_uq %>% tabyl(country)
# dat_uq %>% tabyl(year) # 2012-2018

# dat_uq %>% skimr::skim()
