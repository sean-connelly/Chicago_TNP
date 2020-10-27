#!/bin/bash

echo "`date`: Step 1 - creating database"
./initialize_database.sh
echo "`date`: Step 1 Complete - finished creating database"

echo "`date`: Step 2 - downloading tnp data"
echo "`date`: downloading trips"
./download_raw_trips_data.sh
echo "`date`: finished downloading trips"
echo "`date`: downloading drivers"
./download_raw_drivers_data.sh
echo "`date`: finished downloading drivers"
echo "`date`: downloading vehicles"
./download_raw_vehicles_data.sh
echo "`date`: finished downloading vehicles"
echo "`date`: Step 2 Complete - finished downloading tnp data"

echo "`date`: Step 3 - importing tnp data"
echo "`date`: importing trips"
./import_trips_data.sh
echo "`date`: finished importing trips"
echo "`date`: importing drivers"
./import_drivers_data.sh
echo "`date`: finished importing drivers"
echo "`date`: importing vehicles"
./import_vehicles_data.sh
echo "`date`: finished importing vehicles"
echo "`date`: Step 3 Complete - finished importing tnp data"