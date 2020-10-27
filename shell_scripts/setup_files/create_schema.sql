CREATE EXTENSION postgis;

--trips
CREATE UNLOGGED TABLE public.raw_trips (
  trip_id text,
  trip_start_timestamp timestamp without time zone,
  trip_end_timestamp timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract text,
  dropoff_census_tract text,
  pickup_community_area int,
  dropoff_community_area int,
  fare numeric,
  tip numeric,
  additional_charges numeric,
  trip_total numeric,
  shared_trip_authorized boolean,
  trips_pooled int,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  pickup_centroid_location text,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  dropoff_centroid_location text
);

CREATE TABLE public.trips (
  trip_id text,
  trip_start timestamp without time zone,
  trip_end timestamp without time zone,
  trip_seconds numeric,
  trip_miles numeric,
  pickup_census_tract text,
  dropoff_census_tract text,
  pickup_community_area int,
  dropoff_community_area int,
  fare numeric,
  tips numeric,
  extras numeric,
  trip_total numeric,
  pickup_centroid_latitude numeric,
  pickup_centroid_longitude numeric,
  pickup_centroid_location text,
  dropoff_centroid_latitude numeric,
  dropoff_centroid_longitude numeric,
  dropoff_centroid_location text,
  shared_trip_authorized boolean,
  trips_pooled int
);

--drivers
CREATE UNLOGGED TABLE public.raw_drivers (
month_reported text,
driver_start_month text,
city text,
state text,	
zip text,	
number_of_trips int,	
multiple_tnps boolean
);

CREATE TABLE public.drivers (
month_reported date,
driver_start_month date,
city text,
state text,	
zip text,	
number_of_trips int,	
multiple_tnps boolean
);

--vehicles
CREATE UNLOGGED TABLE public.raw_vehicles (
month_reported text,
state text,	
make text,
model text,
color text,	
year int,	
last_inspection_month text,
number_of_trips int,	
multiple_tnps boolean
);

CREATE TABLE public.vehicles (
month_reported date,
state text,	
make text,
model text,
color text,	
year int,	
last_inspection_month date,
number_of_trips int,	
multiple_tnps boolean
);
