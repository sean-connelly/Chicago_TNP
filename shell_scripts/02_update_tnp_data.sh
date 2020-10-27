#!/bin/bash

echo "`date`: Step 1 - update trips data"
echo "`date`: downloading trips"
./update_trips_data.sh
echo "`date`: Step 1 Complete - finished updating trips data"

echo "`date`: Step 2 - update drivers data"
echo "`date`: finished downloading trips"
echo "`date`: downloading drivers"
./download_raw_drivers_data.sh
echo "`date`: finished downloading drivers"
echo "`date`: importing drivers"
./import_drivers_data.sh
echo "`date`: finished importing drivers"
echo "`date`: Step 2 Complete - finished update drivers data"

echo "`date`: Step 3 - update vehicles data"
echo "`date`: downloading vehicles"
./download_raw_vehicles_data.sh
echo "`date`: finished downloading vehicles"
echo "`date`: importing vehicles"
./import_vehicles_data.sh
echo "`date`: finished importing vehicles"
echo "`date`: Step 3 Complete - finished updating vehicles data"



