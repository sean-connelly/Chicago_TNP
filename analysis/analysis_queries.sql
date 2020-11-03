
---####################
--SET UP
---####################

--Create indices to speed up queries
CREATE INDEX IF NOT EXISTS idx_trips_on_trip_id ON public.trips (trip_id);
CREATE INDEX IF NOT EXISTS idx_trips_on_pickup_community_area ON public.trips (pickup_community_area);
CREATE INDEX IF NOT EXISTS idx_trips_on_pickup_census_tract ON public.trips (pickup_census_tract);
CREATE INDEX IF NOT EXISTS idx_trips_on_dropoff_community_area ON public.trips (dropoff_community_area);
CREATE INDEX IF NOT EXISTS idx_trips_on_dropoff_census_tract ON public.trips (dropoff_census_tract);

--Create analysis schema to store prepared tables
CREATE SCHEMA analysis;

--Declare time period for YoY comparisons
--Period 1
set session my.vars.period_1_start_date = '2019-01-01';
set session my.vars.period_1_end_date = '2019-06-01';
--Period 2
set session my.vars.period_2_start_date = '2020-01-01';
set session my.vars.period_2_end_date = '2020-06-01';





---####################
--TRIPS
---####################





--BASE ANALYSIS TABLES
--Daily trips
drop table if exists analysis.daily_trips;
create table analysis.daily_trips as
select
  date(trip_start) date,
  count(*) as trips
from public.trips
group by date;

--Monthly trips
drop table if exists analysis.monthly_trips;
create table analysis.monthly_trips as
select
  date(date_trunc('month', date) + '1 month - 1 day'::interval) as month,
  sum(trips) as trips,
  count(*) as days,
  sum(trips)::numeric / count(*) as trips_per_day
from analysis.daily_trips
group by month
order by month;

--TNP daily activity 
drop table if exists analysis.tnp_daily_activity;
create table analysis.tnp_daily_activity as
select
  date(trip_start) as date,
  count(*) as trips,
  sum(trip_seconds) as trip_seconds,
  sum(trip_miles) as trip_miles,
  sum(fare) as fare,
  sum(extras) as extras,
  sum(trip_total) as trip_total
from public.trips
where fare is not null
  and trip_miles is not null
  and trip_seconds is not NULL
  and fare between 1 and 1000
  and trip_total between 1 and 1000
  and trip_miles between 0 and 250
  and trip_seconds between 30 and 21600
group by date
order by date;

--TNP monthly activity
drop table if exists analysis.tnp_monthly_activity;
create table analysis.tnp_monthly_activity as
select
  date(date_trunc('month', trip_start) + '1 month - 1 day'::interval) as month,
  count(*) as trips,
  sum(trip_seconds) as trip_seconds,
  sum(trip_miles) as trip_miles,
  sum(fare) as fare,
  sum(extras) as extras,
  sum(trip_total) as trip_total
from public.trips
where fare is not null
  and trip_total is not null
  and trip_miles is not null
  and trip_seconds is not null
  and fare between 1 and 1000
  and trip_total between 1 and 1000
  and trip_miles between 0 and 250
  and trip_seconds between 30 and 21600
group by month
order by month;



--SPATIAL ANALYSIS
--2019 vs 2020 pickups by census tract
drop table if exists analysis.pickup_tracts_comp;
create table analysis.pickup_tracts_comp as
select
extract(year from trip_start) as year,
pickup_census_tract,
count(*) as trips
from public.trips
where pickup_census_tract is not null
  --YTD restriction
  and (trip_start between current_setting('my.vars.period_1_start_date')::date and
	                       current_setting('my.vars.period_1_end_date')::date
	   or
	   trip_start between current_setting('my.vars.period_2_start_date')::date and
	                       current_setting('my.vars.period_2_end_date')::date)
group by extract(year from trip_start), pickup_census_tract;

--2019 vs 2020 dropoffs by census tract
drop table if exists analysis.dropoff_tracts_comp;
create table analysis.dropoff_tracts_comp as
select
extract(year from trip_end) as year,
dropoff_census_tract,
count(*) as trips
from public.trips
where dropoff_census_tract is not null
  --YTD restriction
  and (trip_end between current_setting('my.vars.period_1_start_date')::date and
	                     current_setting('my.vars.period_1_end_date')::date
	   or
	   trip_end between current_setting('my.vars.period_2_start_date')::date and
	                     current_setting('my.vars.period_2_end_date')::date)
group by extract(year from trip_end), dropoff_census_tract;

--2019 vs 2020 trip patterns by census tract
drop table if exists analysis.trip_patterns_tracts_comp;
create table analysis.trip_patterns_tracts_comp as
select
extract(year from trip_start) as year,
pickup_census_tract,
dropoff_census_tract,
count(*) as trips
from public.trips
where pickup_census_tract is not null
  and dropoff_census_tract is not null
  --YTD restriction
  and (trip_start between current_setting('my.vars.period_1_start_date')::date and
	                       current_setting('my.vars.period_1_end_date')::date
	   or
	   trip_start between current_setting('my.vars.period_2_start_date')::date and
	                       current_setting('my.vars.period_2_end_date')::date)
group by extract(year from trip_start), pickup_census_tract, dropoff_census_tract;





---####################
--DRIVERS
---####################





--Drivers with more than zero trips by month
create table analysis.drivers_non_zero as
select *
from public.drivers
where number_of_trips > 0


