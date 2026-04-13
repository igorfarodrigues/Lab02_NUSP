-- Teste Singular: Verifica se a chegada ocorre APÓS a partida planejada
-- O DBT considera o teste falho se a query retornar QUALQUER linha
-- Portanto, buscamos registros com dados INCORRETOS (chegada <= partida)

select
    flight_id,
    scheduled_departure,
    scheduled_arrival
from {{ ref('fact_ticket_flight') }}
where scheduled_arrival <= scheduled_departure
