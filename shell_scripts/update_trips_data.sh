#!/bin/bash

ts=$(psql -U postgres -P t -P format=unaligned -d chicago_tnp_data -c "SELECT date(max(trip_start) - '2 days'::interval) FROM trips")
url="https://data.cityofchicago.org/resource/m6dm-c72p.csv?%24where=trip_start_timestamp%20>=%20'${ts}'&%24limit=1000000000"

echo "downloading updated trips data from ${url}"
wget -O ../data/trips.csv ${url}

./import_trips_data.sh
