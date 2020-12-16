
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
CREATE SCHEMA IF NOT EXISTS analysis;

--Declare time period for YoY comparisons
--Period 1
set session my.vars.period_1_start_date = '2019-01-01';
set session my.vars.period_1_covid_date = '2019-03-21';
set session my.vars.period_1_end_date = '2019-09-30';

--Period 2
set session my.vars.period_2_start_date = '2020-01-01';
set session my.vars.period_2_covid_date = '2020-03-21';
set session my.vars.period_2_end_date = '2020-09-30';





---####################
--TRIPS
---####################





--BASE ANALYSIS TABLES
--Trips YOY
drop table if exists analysis.base_ytd;
create table analysis.base_ytd as
select 
*,
case when (trip_start between current_setting('my.vars.period_1_covid_date')::date and
	                       current_setting('my.vars.period_1_end_date')::date
		   or
		   trip_start between current_setting('my.vars.period_2_covid_date')::date and
							   current_setting('my.vars.period_2_end_date')::date)
	 then 'Post-COVID'
	 else 'Pre-COVID' end as covid_group							 
from public.trips
where
  --YTD restriction
 	  (trip_start between current_setting('my.vars.period_1_start_date')::date and
	                       current_setting('my.vars.period_1_end_date')::date
	   or
	   trip_start between current_setting('my.vars.period_2_start_date')::date and
	                       current_setting('my.vars.period_2_end_date')::date);
						   
--Daily trips
drop table if exists analysis.daily_trips;
create table analysis.daily_trips as
select
  date(trip_start) date,
  count(*) as trips
from analysis.base_ytd
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
from analysis.base_ytd
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
from analysis.base_ytd
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
covid_group,
pickup_census_tract,
count(*) as trips
from analysis.base_ytd
where pickup_census_tract is not null
group by extract(year from trip_start), covid_group, pickup_census_tract;

--2019 vs 2020 dropoffs by census tract
drop table if exists analysis.dropoff_tracts_comp;
create table analysis.dropoff_tracts_comp as
select
extract(year from trip_end) as year,
covid_group,
dropoff_census_tract,
count(*) as trips
from analysis.base_ytd
where dropoff_census_tract is not null
group by extract(year from trip_end), covid_group, dropoff_census_tract;

--2019 vs 2020 trip patterns by census tract
drop table if exists analysis.trip_patterns_tracts_comp;
create table analysis.trip_patterns_tracts_comp as
select
extract(year from trip_start) as year,
covid_group,
pickup_census_tract,
dropoff_census_tract,
count(*) as trips
from analysis.base_ytd
where pickup_census_tract is not null
  and dropoff_census_tract is not null
group by extract(year from trip_start), covid_group, pickup_census_tract, dropoff_census_tract;

--2019 vs 2020 trip patterns by community area
--pickup
drop table if exists analysis.hourly_trips_by_pickup_community_area;
create table analysis.hourly_trips_by_pickup_community_area as
select
extract(year from trip_start) as year,
covid_group,
pickup_community_area,
date_trunc('hour', trip_start) as pickup_hour,
extract(hour from trip_start) as hour_of_day,
extract(dow from trip_start) as day_of_week,
count(*) as trips
from analysis.base_ytd
group by extract(year from trip_start), covid_group, pickup_community_area, pickup_hour, hour_of_day, day_of_week
order by pickup_community_area, pickup_hour;

--dropoff
drop table if exists analysis.hourly_trips_by_dropoff_community_area;
create table analysis.hourly_trips_by_dropoff_community_area as
select
extract(year from trip_end) as year,
covid_group,
dropoff_community_area,
date_trunc('hour', trip_end) as dropoff_hour,
extract(hour from trip_end) as hour_of_day,
extract(dow from trip_end) as day_of_week,
count(*) as trips
from analysis.base_ytd
group by extract(year from trip_end), covid_group, dropoff_community_area, dropoff_hour, hour_of_day, day_of_week
order by dropoff_community_area, dropoff_hour;





---####################
--DRIVERS
---####################





--Drivers with more than zero trips by month
create table analysis.drivers_non_zero as
select *
from public.drivers
where number_of_trips > 0


