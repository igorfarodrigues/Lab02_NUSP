with airports as (
    select * from {{ source('booking_sources', 'airports') }}
),
flights as (
    select * from {{ source('booking_sources', 'flights') }}
),

departures as (
    select
        departure_airport as airport_code,
        count(*) as total_departures
    from flights
    group by departure_airport
),

arrivals as (
    select
        arrival_airport as airport_code,
        count(*) as total_arrivals
    from flights
    group by arrival_airport
)

select
    a.airport_code,
    a.airport_name,
    a.city,
    a.timezone,
    coalesce(d.total_departures, 0) as total_departures,
    coalesce(arr.total_arrivals, 0) as total_arrivals,
    coalesce(d.total_departures, 0) + coalesce(arr.total_arrivals, 0) as total_operations

from airports a
left join departures d on a.airport_code = d.airport_code
left join arrivals arr on a.airport_code = arr.airport_code
