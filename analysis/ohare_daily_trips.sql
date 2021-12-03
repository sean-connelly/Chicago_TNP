/*
--Create daily trips from O'Hare table
drop table if exists analysis.daily_trips_ohare;
create table analysis.daily_trips_ohare as
select
date(trip_start) date,
sum(case when pickup_census_tract = '17031980000' 
	then 1 else 0 end) as pickup_trips,
sum(case when dropoff_census_tract = '17031980000' 
	then 1 else 0 end) as dropoff_trips,
sum(case when pickup_census_tract = '17031980000' 
	       or dropoff_census_tract = '17031980000' 
	then 1 else 0 end) as total_trips
from public.trips
where pickup_census_tract = '17031980000'
   or dropoff_census_tract = '17031980000'
group by date;
*/

--Analyze daily trips from O'Hare table
select
pickup_trips,
dropoff_trips,
pickup_trips + dropoff_trips as total,
avg((pickup_trips + dropoff_trips)) 
	over(order by date rows between 29 preceding and current row) as avg_last30_total_trips
from analysis.daily_trips_ohare
order by date;

