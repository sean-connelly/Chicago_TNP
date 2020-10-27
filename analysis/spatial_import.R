

# Setup -------------------------------------------------------------------


# Load libraries
pacman::p_load(tidyverse, tidycensus, sf,
               RPostgres, RPostgreSQL, DBI,
               config, here)

# Set working directory
setwd(here::here())

# Load API keys and database connection information for project
api_key_census <- config::get("api_key_census")



# Get tabular data for Cook County tracts ---------------------------------


# Variables 
ref_vars <-  load_variables(year = "2018", dataset = "acs5/profile", cache = TRUE)

vars <- ref_vars %>% 
  mutate("table_name" = gsub( "_.*$", "", name),
         "label" = gsub("!!", "; ", label)) %>% 
  filter(str_detect(table_name,  pattern = "\\d$")) %>% 
  select(table_name, everything())

# Get Data Profiles at Tract level
tracts_raw <- get_acs(geography = "tract",
                      year = 2018,
                      variables = vars %>% pull(name),
                      survey = "acs5",
                      state = "17", # IL FIPS 
                      county = "031", # Cook County FIPS
                      geometry = FALSE,
                      wide = TRUE)
    

# Join to spatial data ----------------------------------------------------


# Load spatial data
# Community areas
comm_areas_sf <- st_read("../data/shapefiles/community_areas/community_areas.shp") %>% 
  mutate(across(where(is.factor), as.character)) %>% 
  select("comm_area_id" = area_num_1, "comm_area_n" = area_numbe,
         community, shape_area, shape_len) %>% 
  mutate("comm_area_n" = as.numeric(comm_area_n))

comm_areas_sf <- comm_areas_sf %>% st_transform(4326)

# Tracts
tracts_sf <- st_read("../data/shapefiles/census_tracts/census_tracts.shp") %>% 
  mutate(across(where(is.factor), as.character)) %>% 
  select("GEOID" = geoid10, "comm_area_id" = commarea, "comm_area_n" = commarea_n,
         notes)

tracts_sf <- tracts_sf %>% st_transform(4326)

# Restrict tracts to City of Chicago
tracts <- tracts_raw %>% 
  semi_join(., tracts_sf, by = "GEOID") %>% 
  left_join(., vars, by = c("variable" = "name")) %>% 
  select(GEOID, NAME, table_name, variable, label, estimate, moe)
    

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

# Census Tracts - Tabluar
dbWriteTable(conn = con,
             name = "acs_data_profiles",
             value = tracts,
             overwrite = TRUE)
