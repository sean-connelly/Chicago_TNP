#!/bin/bash

echo "`date`: dropping existing vehicles data if present"
psql -U postgres -d chicago_tnp_data -c "TRUNCATE TABLE raw_vehicles;"
psql -U postgres -d chicago_tnp_data -c "TRUNCATE TABLE vehicles;"

echo "`date`: populating raw_vehicles data"
schema=`head -n 1 ../data/vehicles.csv`
cat ../data/vehicles.csv | psql -U postgres -d chicago_tnp_data -c "COPY raw_vehicles (${schema}) FROM stdin CSV HEADER;"
echo "`date`: finished raw_vehicles load"

echo "`date`: populate vehicles data (text to dates, etc)"
psql -U postgres -d chicago_tnp_data -f setup_files/populate_vehicles.sql
echo "`date`: finished populating vehicles data"
echo "`date`: finished tnp data load"