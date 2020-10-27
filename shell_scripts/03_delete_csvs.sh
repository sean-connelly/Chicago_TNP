#!/bin/bash

echo "`date`: deleting temp CSVs to free up space"
rm ../data/trips.csv
rm ../data/drivers.csv
rm ../data/vehicles.csv
echo "`date`: finished deleting temp CSVs"