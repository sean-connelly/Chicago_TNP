#!/bin/bash

echo "`date`: beginning raw_trips load"
schema=`head -n 1 ../data/trips.csv`
cat ../data/trips.csv | psql -U postgres -d chicago_tnp_data -c "COPY raw_trips (${schema}) FROM stdin CSV HEADER;"
echo "`date`: finished raw_trips load"

echo "`date`: populating trips data"
psql -U postgres -d chicago_tnp_data -f setup_files/populate_trips.sql
echo "`date`: populated trips data"