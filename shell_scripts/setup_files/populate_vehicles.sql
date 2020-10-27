INSERT INTO vehicles
(
month_reported, state,	
make, model, color,	
year, last_inspection_month,
number_of_trips, multiple_tnps
)
SELECT
    make_date(cast(split_part(month_reported, '-', 1) as integer),
              cast(split_part(month_reported, '-', 2) as integer),
              1) as month_reported, 
    state, 
    make, 
    model, 
    color,	
    year,
    make_date(cast(split_part(last_inspection_month, '-', 1) as integer),
              cast(split_part(last_inspection_month, '-', 2) as integer),
              1) as last_inspection_month,
    number_of_trips,
    multiple_tnps
FROM raw_vehicles
ON CONFLICT DO NOTHING;

TRUNCATE TABLE raw_vehicles;