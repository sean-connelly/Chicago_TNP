#!/bin/bash

echo "`date`: dropping existing drivers data if present"
psql -U postgres -d chicago_tnp_data -c "TRUNCATE TABLE raw_drivers;"
psql -U postgres -d chicago_tnp_data -c "TRUNCATE TABLE drivers;"

echo "`date`: populating raw_drivers data"
schema=`head -n 1 ../data/drivers.csv`
cat ../data/drivers.csv | psql -U postgres -d chicago_tnp_data -c "COPY raw_drivers (${schema}) FROM stdin CSV HEADER;"
echo "`date`: finished raw_drivers load"

echo "`date`: populate drivers data (text to dates, etc)"
psql -U postgres -d chicago_tnp_data -f setup_files/populate_drivers.sql
echo "`date`: finished populating drivers data"