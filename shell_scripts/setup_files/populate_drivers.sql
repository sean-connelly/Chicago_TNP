INSERT INTO drivers
(
month_reported, driver_start_month,
city, state, zip,	
number_of_trips, multiple_tnps
)
SELECT
    make_date(cast(split_part(month_reported, '-', 1) as integer),
              cast(split_part(month_reported, '-', 2) as integer),
              1) as month_reported, 
    make_date(cast(split_part(driver_start_month, '-', 1) as integer),
              cast(split_part(driver_start_month, '-', 2) as integer),
              1) as driver_start_month,
    city, 
    state, 
    zip,	
    number_of_trips, 
    multiple_tnps
FROM raw_drivers
ON CONFLICT DO NOTHING;

TRUNCATE TABLE raw_drivers;