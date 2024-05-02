# format aca data
# downloaded via fetch_aca_square/fetch_aca.py, for each LRP grid, based on 
# grid centroids and 5km width
#
# 1. open and bind all files to create one 'master'; move to archive

library(here)
library(tidyverse)
library(janitor)

aca1 <- read_csv(here("globalprep", "analysis", "coral-counterfactual",
                  "intermediate-files","allreefs_aca_01.csv"))
aca2 <- read_csv(here("globalprep", "analysis", "coral-counterfactual",
                      "intermediate-files","allreefs_aca_02.csv"))
aca3 <- read_csv(here("globalprep", "analysis", "coral-counterfactual",
                      "intermediate-files","allreefs_aca_03.csv"))
aca4 <- read_csv(here("globalprep", "analysis", "coral-counterfactual",
                      "intermediate-files","allreefs_aca_04.csv"))
aca5 <- read_csv(here("globalprep", "analysis", "coral-counterfactual",
                      "intermediate-files","allreefs_aca_05.csv"))

allreefs_aca <- bind_rows(aca1, aca2, aca3, aca4, aca5) %>% 
  distinct() %>% 
  rename(area_m2 = area) %>% 
  mutate(mapped_m2 = mapped_sqkm*1000000, 
         aoi_m2 = aoi_sqkm*1000000) %>% 
  mutate(pr_aca_class = area_m2/mapped_m2) %>% 
  select(-c(aoi_sqkm, mapped_sqkm))

# save full table of aca linked to allreefs grids
allreefs_aca %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                 "outputs","allreefs_aca.csv"))

has_geo <- allreefs_aca %>% 
  filter(aca_type == "geomorphic") %>% 
  distinct(OBJECTID, longitude, latitude)

has_benthic <- allreefs_aca %>% 
  filter(aca_type == "benthic") %>% 
  distinct(OBJECTID, longitude, latitude)

top_geo <- allreefs_aca %>% 
  filter(aca_type == "geomorphic") %>% 
  arrange(-pr_aca_class) %>% 
  distinct(OBJECTID,.keep_all = T) %>% 
  rename(top_geomorphic_class = aca_class) %>% 
  select(OBJECTID, top_geomorphic_class, area_m2, mapped_m2, pr_aca_class)

top_geo %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                 "outputs","allreefs_aca_top_geo.csv"))

top_benthic <- allreefs_aca %>% 
  filter(aca_type == "benthic") %>% 
  arrange(-pr_aca_class) %>% 
  distinct(OBJECTID,.keep_all = T) %>% 
  rename(top_benthic_class = aca_class) %>% 
  select(OBJECTID, top_benthic_class, area_m2, mapped_m2, pr_aca_class)

top_benthic %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                 "outputs","allreefs_aca_top_benthic.csv"))

top_benthic %>% tabyl(top_benthic_class)

# simplified geomorphic categories
simple_geo <- allreefs_aca %>% 
  filter(aca_type == "geomorphic") %>% 
  mutate(aca_group = recode(aca_class, 
                          "Plateau" = "bank", 
                          "Reef Crest" = "crest",
                          "Deep Lagoon" = "lagoon",
                          "Inner Reef Flat" = "lagoon", 
                          "Outer Reef Flat" = "lagoon", 
                          "Patch Reefs" = "lagoon", 
                          "Shallow Lagoon" = "lagoon", 
                          "Terrestrial Reef Flat"= "lagoon", 
                          "Back Reef Slope" = "slope",
                          "Reef Slope" = "slope", 
                          "Sheltered Reef Slope" = "slope")) %>% 
  group_by(OBJECTID, aca_group) %>% 
  summarise(area_m2 = sum(area_m2), 
            mapped_m2 = max(mapped_m2)) %>% 
  ungroup() %>% 
  mutate(pr_aca_group = area_m2 / mapped_m2)

# Proportion of all surveyed area that is bank, lagoon, slope, crest
simple_geo %>% 
  pivot_wider(id_cols = OBJECTID, names_from = aca_group, 
              values_from = pr_aca_group, names_prefix = "aca_pr_") %>% 
  mutate(across(starts_with("aca_pr"), ~replace_na(.,0))) %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                 "outputs","allreefs_aca_geo_simple.csv"))

# Top aca geomorphic 'simplified' category
simple_geo %>% 
  arrange(-pr_aca_group) %>% 
  distinct(OBJECTID, .keep_all = T) %>% 
  rename(top_geo_simple = aca_group) %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                 "outputs","allreefs_aca_top_geo_simple.csv"))

# Proportion seagrass in surveyed (non-NA) cells
allreefs_aca %>% 
  filter(aca_class == "Seagrass") %>% 
  select(OBJECTID, longitude, latitude, pr_aca_class) %>% 
  rename(pr_seagrass = pr_aca_class) %>% 
  right_join(has_benthic) %>% 
  mutate(pr_seagrass = replace_na(pr_seagrass, 0)) %>% 
  write_csv(here("globalprep", "analysis", "coral-counterfactual",
                 "outputs","allreefs_aca_seagrass.csv"))


