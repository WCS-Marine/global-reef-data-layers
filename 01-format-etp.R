# ---------------------------------------------------------# 
# 01-format-etp.R
# Read and format Eastern Tropical Pacific (ETP)
# coral cover date from: 
#
# Romero‐Torres, M., Acosta, A., Palacio‐Castro, A. M., 
# Treml, E. A., Zapata, F. A., Paz‐García, D. A., & 
# Porter, J. W. (2020). Coral reef resilience to thermal
# stress in the Eastern Tropical Pacific. Global Change 
# Biology, 26(7), 3880-3890.
# https://doi.org/10.1111/gcb.15126
# 
# Data downloaded on 15 Apr 2022 by WF from:
# https://zenodo.org/record/3744864#.Yln1NZLMJ9e
# 
# W. Friedman // 15 April 2022
# UPDATED: 05/16/2022 removing site averaging
# ---------------------------------------------------------# 

dat_etp0 <- read_csv(here("globalprep","analysis","coral-counterfactual","data_dl",
                        "romero_torres_ETP","Data","Coral_Cover_ETP.csv")) %>% 
  clean_names() %>% 
  rename(survey_year = year) %>% 
  select(region, country, location, site, lat, lon, date, survey_year, coral_cover, reference) %>% 
  filter(survey_year >= 2010) %>% 
  arrange(survey_year, site)

dat_etp0

# 1. keep most recent survey year
# 2. get mean of within-year dupes

etp_info <- dat_etp0 %>% 
  group_by(site, lat, lon) %>% 
  summarise(max_year = max(survey_year))

dat_etp <- dat_etp0 %>% 
  # keep most recently survey year
  left_join(etp_info, by = c("site", "lat", "lon")) %>% 
  mutate(max_yr_ck = if_else(survey_year == max_year, 1, 0)) %>% 
  filter(max_yr_ck == 1) %>% 
  select(-max_yr_ck, - max_year) %>% 
  # get mean of within-year dupes
  group_by(country, site, lat, lon) %>% 
  summarise(year = unique(survey_year), 
            pct_hardcoral = mean(coral_cover,na.rm=T),
            reference = unique(reference)) %>% 
  rename(latitude = lat, 
         longitude = lon) %>% 
  select(country, site, latitude, longitude, year, pct_hardcoral, reference)
  

# length(unique(dat_etp$site)) # 177 sites
# survey years: 1970 - 2014
# 49 surveys 2010 - 2021, with 31 distinct sites.
