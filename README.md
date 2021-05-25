# Chicago Transportation Network Provider (TNP) Analysis
 
This repository contains code analyzing the impact of COVID-19 on rideshare in Chicago. The setup, ingest, and update phases are heavily reliant on Todd W Schneider's excellent work: you can see [his repo here](https://github.com/toddwschneider/chicago-taxi-data) and his corresponding [blog post here](https://toddwschneider.com/posts/chicago-taxi-data/).

<span style="color:red">WARNING:</span> As of May 2021, the TNP data is ~50GB all in and the ingest process for trip data took several hours on my laptop - not for the faint of heart.

### Data Sources

Most raw data comes from the City of Chicago Data Portal:

* TNP Data (Uber/Lyft)
  * [Trips](https://data.cityofchicago.org/Transportation/Transportation-Network-Providers-Trips/m6dm-c72p)
  * [Drivers](https://data.cityofchicago.org/Transportation/Transportation-Network-Providers-Drivers/j6wf-834c)
  * [Vehicles](https://data.cityofchicago.org/Transportation/Transportation-Network-Providers-Vehicles/bc6b-sq4u)
* Spatial Data
  * [Census Tracts](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Census-Tracts-2010/5jrd-6zik)
  * [Community Areas](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas-current-/cauq-8yn6)

Additional Census Tract-level information is pulled from the American Community Survey using Kyle Walker's handy [tidycensus package](https://github.com/walkerke/tidycensus). 

## Instructions

This section will mirror most of the steps outlined by Schneider, but my own setup was a little different - I have a machine running Windows 10, the scope of this analysis includes drivers/vehicles/census data, etc. - your mileage may vary.

##### **1. Install Necessary Programs**

  * **Install [Git](https://git-scm.com/downloads) and [GitHub Desktop](https://desktop.github.com/). If necessary, add additional required utilities like [Wget](https://gist.github.com/evanwill/0207876c3243bbb6863e65ec5dc3f058)**
   
     I run the ETL script using Git Bash but I prefer GitHub Desktop rather than messing with the command line for everything else. Wget is also a required utility to request the TNP files from the Data Portal if you are not already running linux.
   
   
  * **Install [PostgreSQL](https://www.postgresql.org/download/) and [PostGIS](https://postgis.net/install). Add Postgres to your PATH** 

     I recommend downloading PostgreSQL 12.4. PostGIS and other extensions are not yet available for PostgreSQL 13. The installer for PostgreSQL allowed me to download the spatial extension (PostGIS) directly, but you may have to do so separately.
     
     You should also add [Postgres to your PATH](https://medium.com/@itayperry91/get-started-with-postgresql-on-windows-a-juniors-life-4adfa6dd10e) so that the Git Bash shell can run `psql` commands. The scripts as written reference the default user `postgres`. You may have to store your password using the [PGPASSWORD environment variable](https://www.postgresql.org/docs/9.1/libpq-envars.html) if Git Bash keeps demanding a password. You can run `psql -U postgres -c 'create database test;'` in Git Bash to make sure everthing is working OK.  
    
  * **Install [R](https://cran.rstudio.com/) and [RStudio](https://rstudio.com/products/rstudio/download/#download)** 

     Analysis and Census data ingest are done using R scripts and RMarkdown.

##### **2. Download and import TNP data**

Within the `shell_scripts/` subfolder, open Git Bash and run the following to grab TNP trips, drivers, and vehicles data:

```
./01_etl_tnp_script.sh
```

This process will take several hours, but if completed correctly when you open PgAdmin you should see a database called `chicago_tnp_data` with populated data in the `trips`, `drivers`, and `vehicles` tables. You can remove
the temporary CSVs created in the the `data/` subfolder during the download phase to free up space by then running:

```
./03_delete_csvs.sh
```

##### **3.Set up connections to database for analysis in R**

Within the `analysis/` subfolder, open `rideshare_analysis.Rmd`. To connect to the data stored in Postgres, you must have a `config.yml` file saved within `analysis/` that defines the following variables:

```
default:
    host: "localhost"
    dbname: "chicago_tnp_data"
    port: 5432
    user: "postgres"
    password: "YOUR PASSWORD HERE"    
    api_key_census: "YOUR KEY HERE"
```

##### **4. Optional: Import spatial geometries and Census data**

Within the `analysis/` subfolder, open and run `spatial_import.R`.

##### **5. Updating TNP data**

The city releases new TNP data every quarter. To update the data, navigate to the `shell_scripts/` subfolder and run

```
./02_update_tnp_data.sh
```

This script only grabs the latest TNP trip data, rather than rebuilding the entire database. TNP driver and vehicle data, however, are dumped and rebuilt from scratch. Compared to trips, these are relatively small (they only take a couple of minutes), but the process could be optimized in the future. 