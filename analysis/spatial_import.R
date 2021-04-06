

# Setup -------------------------------------------------------------------


# Load libraries
pacman::p_load(tidyverse, tidycensus, sf,
               RPostgres, RPostgreSQL, DBI,
               config, here, janitor)

# Set working directory
setwd(here::here())
options(scipen = 999, stringsAsFactors = FALSE, dplyr.summarise.inform = FALSE)

# Load API keys and database connection information for project
api_key_census <- config::get("api_key_census")


# Get tabular data for Cook County tracts ---------------------------------


# Variables
# Data Profiles
ref_vars_dp <-  load_variables(year = "2019", 
                               dataset = "acs5/profile", 
                               cache = TRUE)

# Detailed Tables
ref_vars_subject <-  load_variables(year = "2019", 
                                    dataset = "acs5/subject", 
                                    cache = TRUE)

# Combine, remove helpers
ref_vars <- bind_rows(ref_vars_dp, ref_vars_subject)

rm(ref_vars_dp, ref_vars_subject)

# Restrict variables called to:
# Data Profiles (DP02-05) 

# Frontline Occupations (S2401) 
# Based off of https://www.aclum.org/en/publications/data-show-covid-19-hitting-essential-workers-and-people-color-hardest
# and WBEZ analysis https://www.wbez.org/stories/no-health-care-workers-in-chicago-dont-all-live-downtown/6eeeb985-45e4-4a07-a359-964967bfb865

# Includes the following:
# 16+ Workers Total (S2401_C01_001)
# Healthcare practitioners and technical occupations (S2401_C01_015)
# Healthcare support occupations (S2401_C01_019)
# Protective service occupations (S2401_C01_020)
# Food preparation and serving related occupations (S2401_C01_023)
# Building and grounds cleaning and maintenance occupations (S2401_C01_024)
# Personal care and service occupations (S2401_C01_025)
vars <- ref_vars %>% 
  mutate("table_name" = gsub( "_.*$", "", name),
         "label" = gsub("!!", "; ", label)) %>% 
  filter(str_detect(table_name,  
                    pattern = "\\d$")) %>%
  filter(str_detect(table_name,
                    pattern = "DP0(2|3|4|5)") |
           str_detect(name,
                      pattern = "S2401_C01_(001|015|019|020|023|024|025)")) %>%
  select(table_name, everything())

# Get Data Profiles at Tract level
tracts_raw <- get_acs(geography = "tract",
                      year = 2019,
                      variables = vars %>% pull(name),
                      survey = "acs5",
                      state = "17", # IL FIPS 
                      county = "031", # Cook County FIPS
                      geometry = FALSE,
                      wide = TRUE)
    

# Join to spatial data ----------------------------------------------------


## ----- Community areas -----
# Community areas
comm_areas_sf <- st_read("../data/shapefiles/community_areas/community_areas.shp") %>% 
  mutate(across(where(is.factor), as.character)) %>% 
  select("comm_area_id" = area_num_1, "comm_area_n" = area_numbe,
         community, shape_area, shape_len) %>% 
  mutate("comm_area_n" = as.numeric(comm_area_n))

# Transform
comm_areas_sf <- comm_areas_sf %>% st_transform(4326)

## ----- Tracts -----
# Tracts
tracts_sf <- st_read("../data/shapefiles/census_tracts/census_tracts.shp") %>% 
  mutate(across(where(is.factor), as.character)) %>% 
  select("GEOID" = geoid10, "comm_area_id" = commarea, "comm_area_n" = commarea_n,
         notes)

# Transform
tracts_sf <- tracts_sf %>% st_transform(4326)

# Restrict tracts to City of Chicago
tracts <- tracts_raw %>% 
  semi_join(., tracts_sf, by = "GEOID") %>% 
  left_join(., vars, by = c("variable" = "name")) %>% 
  select(GEOID, NAME, table_name, variable, label, estimate, moe)
  
## ----- ZIP codes -----
# ZIP codes
zip_codes_sf <- st_read("../data/shapefiles/zip_codes/zip_codes.shp") %>% 
  select("zip_code" = zip)

# Transform
zip_codes_sf <- zip_codes_sf %>% st_transform(4326)

# ZIP codes COVID-19 information (cases, tests, vaccinations, etc.)
zip_codes_covid <- read_csv("https://data.cityofchicago.org/api/views/yhhz-zm2v/rows.csv?accessType=DOWNLOAD") %>% 
  clean_names()


# Write to database -------------------------------------------------------


# Connect to database
con <- RPostgres::dbConnect(RPostgres::Postgres(), 
                            host = config::get("host"),
                            port = config::get("port"),
                            dbname = config::get("dbname"),
                            user = config::get("user"), 
                            password = config::get("password"))

# Community Areas
dbWriteTable(conn = con,
             name = "spatial_community_areas",
             value = comm_areas_sf,
             overwrite = TRUE)

# Census Tracts - Spatial
dbWriteTable(conn = con,
             name = "spatial_tracts",
             value = tracts_sf,
             overwrite = TRUE)

# Census Tracts - Tabular
dbWriteTable(conn = con,
             name = "acs_data_profiles",
             value = tracts,
             overwrite = TRUE)

# ZIP Codes - Spatial
dbWriteTable(conn = con,
             name = "spatial_zip_codes",
             value = zip_codes_sf,
             overwrite = TRUE)

# Census Tracts - Spatial
dbWriteTable(conn = con,
             name = "zip_codes_covid",
             value = zip_codes_covid,
             overwrite = TRUE)
