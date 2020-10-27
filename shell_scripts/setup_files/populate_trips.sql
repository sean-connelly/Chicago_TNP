DELETE FROM trips
WHERE trip_id IN (SELECT trip_id FROM raw_trips);

INSERT INTO trips
(
  trip_id, trip_start, trip_end, trip_seconds, trip_miles,
  pickup_census_tract, dropoff_census_tract, pickup_community_area,
  dropoff_community_area, fare, tips, extras, trip_total,
  pickup_centroid_latitude, pickup_centroid_longitude,
  dropoff_centroid_latitude, dropoff_centroid_longitude,
  shared_trip_authorized, trips_pooled
)
SELECT
  trip_id,
  trip_start_timestamp,
  trip_end_timestamp,
  trip_seconds,
  trip_miles,
  pickup_census_tract,
  dropoff_census_tract,
  pickup_community_area,
  dropoff_community_area,
  fare,
  tip,
  additional_charges,
  trip_total,
  pickup_centroid_latitude,
  pickup_centroid_longitude,
  dropoff_centroid_latitude,
  dropoff_centroid_longitude,
  shared_trip_authorized,
  trips_pooled
FROM raw_trips
ON CONFLICT DO NOTHING;

TRUNCATE TABLE raw_trips;
