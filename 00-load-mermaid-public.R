library(here)
library(tidyverse)
library(janitor)
library(mermaidr)

#Get mermaidr
#https://github.com/data-mermaid/mermaidr
#remotes::install_github("data-mermaid/mermaidr")


#get all public summary benthicpit
p <- mermaid_get_projects()
p

names(p)

#pit
public_summary <- p %>%
  filter(str_detect(data_policy_benthicpit, "Public")) #include Public and Public Summary

public_summary %>% 
  tabyl("countries")

public_summary %>%
  #head(2) %>%
  mermaid_get_project_data("benthicpit", "sampleevents", token = NULL) #token = NULL gets all public data

.Last.value %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual", "all-public-summary.csv"))

pit <- read_csv(here("globalprep", "analysis", "coral-counterfactual", "all-public-summary.csv"))
nrow(pit)


#lit
projects <- mermaid_get_my_projects()
projects

projects %>% #need to get my projects first, not all public = 403 access forbidden
  mermaid_get_project_data("benthiclit", "sampleevents")

.Last.value %>%
  write_csv(here("globalprep", "analysis", "coral-counterfactual", "esd-lit.csv"))

lit <- read_csv(here("globalprep", "analysis", "coral-counterfactual", "esd-lit.csv"))
nrow(lit)
names(lit)

lit %>% 
  tabyl(country)


#bleaching
projects %>% 
  mermaid_get_project_data("bleaching", "sampleevents")

.Last.value %>%
  write_csv(here("globalprep", "analysis", "coral-counterfactual", "esd-bleaching.csv"))

bleaching <- read_csv(here("globalprep", "analysis", "coral-counterfactual", "esd-bleaching.csv"))
nrow(bleaching)
names(bleaching)


##NB this is comparable to percent_cover_benthic_category_avg_hard_coral
bleaching$percent_hard_avg_avg 

bleaching %>% 
  mutate(year = lubridate::year(bleaching$sample_date)) %>% 
  filter(!is.na(percent_hard_avg_avg)) %>%  #279 rows
  tabyl(country, year)


#Whiteny --start here
#combine into massive coral cover dataset


