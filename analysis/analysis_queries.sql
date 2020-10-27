
--create indices to speed up queries
CREATE INDEX IF NOT EXISTS idx_trips_on_trip_id ON public.trips (trip_id);
CREATE INDEX IF NOT EXISTS idx_trips_on_pickup_community_area ON public.trips (pickup_community_area);
CREATE INDEX IF NOT EXISTS idx_trips_on_pickup_census_tract ON public.trips (pickup_census_tract);
CREATE INDEX IF NOT EXISTS idx_trips_on_dropoff_community_area ON public.trips (dropoff_community_area);
CREATE INDEX IF NOT EXISTS idx_trips_on_dropoff_census_tract ON public.trips (dropoff_census_tract);

--Create analysis schema to store prepared tables
CREATE SCHEMA analysis;

--Example query, 2019 vs 2020 pickups by census tract
create table analysis.pickup_tracts_comp as
select
extract(year from trip_start) as year,
pickup_census_tract,
count(*) as trips
from public.trips
where pickup_census_tract is not null
  and extract(year from trip_start) in (2019, 2020)
group by extract(year from trip_start), pickup_census_tract
