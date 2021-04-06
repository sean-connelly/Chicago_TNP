title: "Rideshare in Chicago During COVID-19"
author: "Sean Connelly"
date: "`r format(Sys.time(), '%B %d, %Y')`"
output:
  html_document:
  code_folding: hide
editor_options: 
  chunk_output_type: console
---
  
  ```{r setup, include=FALSE}
# Load libraries
pacman::p_load(tidyverse, lubridate,
               summarytools, janitor, 
               sf, leaflet, leaflet.extras, tmap,
               DT, gghighlight, highcharter,
               knitr, kableExtra,
               viridis, scales, hrbrthemes, ggthemes, 
               RPostgres, RPostgreSQL, DBI,
               config, here)
# Set working directory
setwd("C:\GitHub_folder\Voorhees\Chicago_TNP\analysis")
options(scipen = 999, dplyr.summarise.inform = FALSE)
knitr::opts_chunk$set(fig.width = 10, fig.asp = 0.618,
                      fig.align = "center", out.width = "70%")
update(DBI)


### Rideshare Data

This analysis relies on Transportation Network Provider (TNP) data for trips, drivers, and vehicles. These datasets are published on the City of Chicago's Data Portal and updated quarterly.

```{r import data}
# Connect to database

install.packages("DBI")


library(tidycensus)
library(tidyverse)
census_api_key("328b79fddc0bad0be5b46ac6d3c460252213c960", install = TRUE)


con <- RPostgres::dbConnect(RPostgres::Postgres(), 
                            host = config::get("host"),
                            port = config::get("port"),
                            dbname = config::get("dbname"),
                            user = config::get("user"), 
                            password = config::get("password"))
#====================
# Trips
#====================
# Import data
daily_trips <- dbGetQuery(con, "SELECT * FROM analysis.daily_trips")
# Clean and tidy
daily_trips <- daily_trips %>% 
  filter(year(date) %in% c(2019, 2020)) %>% 
  mutate("year" = year(date),
         "day" = yday(date),
         "date_x" = date %>% 
           as.character(.) %>%
           str_replace("^\\d{4}","2000") %>% 
           as_date(.),
         "weekday" = wday(date, label = TRUE),
         "trips" = as.numeric(trips)) 
# Restrict to comparable time periods
yoy_period <- daily_trips %>% filter(year == max(year))
daily_trips <- daily_trips %>% 
  filter(day %in% yoy_period$day)
# trips <- dbGetQuery(con, "SELECT * FROM public.trips LIMIT 100;")
# trips <- dbReadTable(con, "public.trips")
# Drivers
drivers <- dbGetQuery(con, "SELECT * FROM public.drivers LIMIT 100;")
# drivers <- dbReadTable(con, "public.drivers")
# Vehicles
vehicles <- dbGetQuery(con, "SELECT * FROM public.vehicles LIMIT 100;")
# vehicles <- dbReadTable(con, "public.vehicles")
```

### Daily Trips

```{r daily trips}
# Plot information
daily_trips_plot_title <- daily_trips %>%
  group_by(year) %>%
  summarize(trips = sum(trips)) %>%
  pivot_wider(everything(), names_from = "year", values_from = "trips") %>% 
  mutate("change" = `2020`-`2019`,
         "change_pct" = (change/`2019`),
         "title_text" = paste0(as.character(comma(-change)), " (", percent(change_pct), ")"))
# Daily Trips YoY Plot
daily_trips %>% 
  mutate("year" = as.character(year)) %>% 
  group_by(year) %>% 
  arrange(date_x) %>%
  mutate(trips_agg = cumsum(trips)) %>% 
  ggplot(aes(x = date_x, y = trips_agg, color = year)) +
  geom_line(size = 1.5) +
  geom_vline(xintercept = as.numeric(as.Date("2000-03-21")), linetype = 4, 
             color = "black", size = 1) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b-%d") +
  scale_y_continuous(labels = comma) +
  labs(title = paste0("Compared to the same period in 2019 (1/1-6/1), \nrideshare trips have decreased by ",
                      daily_trips_plot_title$title_text, " in 2020"),
       x = "Day of the Year", y = "Aggregate Trips",
       color = "Year") +
  scale_color_ipsum() +
  theme_ipsum()
# Table
daily_trips_plot_title %>% 
  mutate(across(c(`2019`, `2020`, change), comma),
         "change_pct" = percent(change_pct)) %>% 
  select(`2019`, `2020`, "Change" = change, "Change (%)" = change_pct) %>% 
  kbl() %>% 
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))
```

### Spatial Distribution of Trips

Example of type of analysis to be conducted

```{r pickup tracts}
# Import data
pickup_tracts_comp <- dbGetQuery(con, "SELECT * FROM analysis.pickup_tracts_comp")
sf_tracts <- st_read(con, layer = "spatial_tracts")
# Join tabluar to spatial, reconfigure
pickup_tracts_comp <- left_join(sf_tracts %>% select(GEOID),
                                pickup_tracts_comp,
                                by = c("GEOID" = "pickup_census_tract")) %>% 
  st_as_sf() %>% 
  mutate("trips" = as.numeric(trips))
# Map
pickup_tracts_comp %>% 
  ggplot(aes(fill = trips)) +
  facet_wrap(~year) +
  geom_sf(color = "light gray") +
  coord_sf(crs = 4326) +
  scale_fill_viridis_c(labels = comma) +
  labs(title = "Rideshare Trips by Pickup Census Tract") +
  theme_ipsum()
  
# Quantile map
tm_shape(pickup_tracts_comp) +
  tm_fill(col = "trips", title = "Trips",
          style = "quantile", palette = "viridis") +
  tm_borders() +
  tm_facets(by = "year", nrow = 1, drop.units = TRUE) +
  tm_layout(main.title = "Rideshare Trips by Pickup Census Tract", 
            main.title.position = c("center"),
            legend.outside = FALSE, 
            legend.position = c("left", "bottom"))
```


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
             
             
             