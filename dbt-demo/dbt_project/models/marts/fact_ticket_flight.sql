with ticket_flights as (
    select * from {{ source('booking_sources', 'ticket_flights') }}
),
flights as (
    select * from {{ source('booking_sources', 'flights') }}
),
tickets as (
    select * from {{ source('booking_sources', 'tickets') }}
)

select
    tf.ticket_no,
    tf.flight_id,
    t.book_ref,
    f.aircraft_code,
    tf.fare_conditions,
    tf.amount,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.actual_departure,
    f.actual_arrival,

    -- Usando a Macro para duração planejada
    {{ get_flight_duration('f.scheduled_departure', 'f.scheduled_arrival') }} as scheduled_duration_minutes,

    -- Usando a Macro para duração real (pode ser NULL)
    {{ get_flight_duration('f.actual_departure', 'f.actual_arrival') }} as actual_duration_minutes

from ticket_flights tf
join flights f on tf.flight_id = f.flight_id
join tickets t on tf.ticket_no = t.ticket_no
